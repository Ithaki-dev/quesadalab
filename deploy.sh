#!/usr/bin/env bash

set -Eeuo pipefail
IFS=$'\n\t'

readonly SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
readonly REPO_ROOT="$SCRIPT_DIR"
readonly SOURCE_ROOT="${REPO_ROOT}/stacks"
readonly CONFIG_SOURCE_ROOT="${REPO_ROOT}/config"
readonly LIVE_ROOT="/opt/quesadalab/stacks"
readonly CONFIG_LIVE_ROOT="/opt/quesadalab/config"
readonly BACKUP_ROOT="/opt/quesadalab/backups/config-deployments"
readonly LOG_ROOT="/opt/quesadalab/logs/deployments"
readonly LOCK_FILE="/run/lock/quesadalab-deploy.lock"
readonly VALIDATE_SCRIPT="${REPO_ROOT}/scripts/validate.sh"
readonly HEALTH_RETRIES=24
readonly HEALTH_INTERVAL=5

readonly -a DEPLOY_ORDER=(
    traefik
    node-exporter
    cadvisor
    prometheus
    grafana
    portainer
    uptime-kuma
    homepage
    vaultwarden
)

COMMAND=""
PULL=false
DRY_RUN=false
VALIDATE=true
CURRENT_STACK="none"
CURRENT_BACKUP=""
LOG_FILE=""
SYNC_COMPLETED=false

usage() {
    cat <<'EOF'
Usage:
  ./deploy.sh list
  ./deploy.sh STACK [--pull] [--dry-run] [--no-validate]
  ./deploy.sh all [--pull] [--dry-run] [--no-validate]

Options:
  --pull          Pull configured images before deployment.
  --dry-run       Show actions without writing files or invoking Docker.
  --no-validate   Skip repository validation.
  -h, --help      Show this help.
EOF
}

log() {
    local level="$1"
    shift
    local message="$*"

    printf '[%s] %s\n' "$level" "$message"
    if [[ -n "$LOG_FILE" ]]; then
        printf '[%s] [%s] %s\n' "$(date '+%Y-%m-%d %H:%M:%S')" "$level" "$message" >> "$LOG_FILE"
    fi
}

die() {
    log "ERROR" "$1" >&2
    exit 1
}

handle_error() {
    local exit_code=$?
    local line_number="$1"
    local failed_command="$2"

    log "ERROR" "Deployment failed for stack '${CURRENT_STACK}' at line ${line_number}: ${failed_command}"
    if [[ "$SYNC_COMPLETED" == "true" && -n "$CURRENT_BACKUP" ]]; then
        log "RECOVERY" "Active configuration may have changed. Review backup: ${CURRENT_BACKUP}"
        log "RECOVERY" "No automatic rollback was attempted. Validate the backup before restoring it."
    fi
    exit "$exit_code"
}

trap 'handle_error "$LINENO" "$BASH_COMMAND"' ERR

find_compose_file() {
    local directory="$1" candidate

    for candidate in docker-compose.yml docker-compose.yaml compose.yml compose.yaml; do
        if [[ -f "${directory}/${candidate}" ]]; then
            printf '%s\n' "${directory}/${candidate}"
            return 0
        fi
    done
    return 1
}

list_stacks() {
    local directory

    for directory in "$SOURCE_ROOT"/*; do
        [[ -d "$directory" ]] || continue
        if find_compose_file "$directory" >/dev/null; then
            basename -- "$directory"
        fi
    done | sort
}

stack_exists() {
    [[ -d "${SOURCE_ROOT}/$1" ]] && find_compose_file "${SOURCE_ROOT}/$1" >/dev/null
}

parse_arguments() {
    (($# > 0)) || { usage; exit 1; }

    while (($# > 0)); do
        case "$1" in
            --pull) PULL=true ;;
            --dry-run) DRY_RUN=true ;;
            --no-validate) VALIDATE=false ;;
            -h|--help) usage; exit 0 ;;
            -*) die "Unknown option: $1" ;;
            *)
                [[ -z "$COMMAND" ]] || die "Only one stack or command may be specified."
                COMMAND="$1"
                ;;
        esac
        shift
    done

    [[ -n "$COMMAND" ]] || die "A stack, 'all', or 'list' is required."
}

require_command() {
    command -v "$1" >/dev/null 2>&1 || die "Required command not found: $1"
}

validate_runtime_environment() {
    [[ "$EUID" -eq 0 ]] || die "Real deployments must run as root."
    require_command docker
    require_command rsync
    require_command flock
    require_command tar
    docker compose version >/dev/null 2>&1 || die "Docker Compose Plugin is not available."
    docker info >/dev/null 2>&1 || die "Docker daemon is not available."
}

initialize_runtime() {
    local timestamp

    timestamp="$(date '+%Y-%m-%d_%H-%M-%S')"
    mkdir -p -- "$BACKUP_ROOT" "$LOG_ROOT"
    LOG_FILE="${LOG_ROOT}/deployment-${timestamp}.log"
    : > "$LOG_FILE"
    chmod 640 "$LOG_FILE"

    exec 9>"$LOCK_FILE"
    flock -n 9 || die "Another QuesadaLab deployment is already running."
}

run_repository_validation() {
    if [[ "$VALIDATE" != "true" ]]; then
        log "WARNING" "Repository validation was explicitly skipped."
        return
    fi

    if [[ "$DRY_RUN" == "true" ]]; then
        log "DRY-RUN" "Would run ${VALIDATE_SCRIPT}."
        return
    fi

    [[ -x "$VALIDATE_SCRIPT" ]] || die "Validation script is not executable: ${VALIDATE_SCRIPT}"
    log "INFO" "Validating repository before deployment."
    "$VALIDATE_SCRIPT"
}

preflight_stack() {
    local stack="$1"
    local source_dir="${SOURCE_ROOT}/${stack}"
    local live_dir="${LIVE_ROOT}/${stack}"

    stack_exists "$stack" || die "Stack is incomplete or unknown: $stack"

    if [[ -f "${source_dir}/.env.example" && ! -f "${live_dir}/.env" ]]; then
        if [[ "$DRY_RUN" == "true" ]]; then
            log "DRY-RUN" "Real deployment requires this file before making changes: ${live_dir}/.env"
            return
        fi
        die "Live environment file is required before deployment: ${live_dir}/.env"
    fi
}

backup_stack_configuration() {
    local stack="$1"
    local live_dir="${LIVE_ROOT}/${stack}"
    local live_config_dir="${CONFIG_LIVE_ROOT}/${stack}"
    local timestamp backup_dir
    local -a backup_paths=()

    timestamp="$(date '+%Y-%m-%d_%H-%M-%S')"
    backup_dir="${BACKUP_ROOT}/${timestamp}/${stack}"
    CURRENT_BACKUP="$backup_dir"

    if [[ "$DRY_RUN" == "true" ]]; then
        log "DRY-RUN" "Would back up ${live_dir} to ${backup_dir}."
        return
    fi

    mkdir -p -- "$backup_dir"
    chmod 700 "$backup_dir"

    [[ -d "$live_dir" ]] && backup_paths+=("stacks/${stack}")
    [[ -d "$live_config_dir" ]] && backup_paths+=("config/${stack}")

    if ((${#backup_paths[@]} > 0)); then
        tar --create --gzip --file "${backup_dir}/stack-config.tar.gz" \
            --directory "/opt/quesadalab" "${backup_paths[@]}"
        chmod 600 "${backup_dir}/stack-config.tar.gz"
        log "OK" "Stack and managed configuration backup created at ${backup_dir}."
    else
        printf 'Stack did not exist before this deployment.\n' > "${backup_dir}/STACK_WAS_ABSENT"
        chmod 600 "${backup_dir}/STACK_WAS_ABSENT"
        log "OK" "Recorded that ${live_dir} did not previously exist."
    fi
}

synchronize_managed_configuration() {
    local stack="$1"
    local source_dir="${CONFIG_SOURCE_ROOT}/${stack}/"
    local live_dir="${CONFIG_LIVE_ROOT}/${stack}/"

    [[ -d "$source_dir" ]] || return 0

    if [[ "$DRY_RUN" == "true" ]]; then
        log "DRY-RUN" "Would synchronize managed configuration from ${source_dir} to ${live_dir} without deleting live-only files."
        return
    fi

    mkdir -p -- "$live_dir"
    rsync --archive "$source_dir" "$live_dir"
    log "OK" "Managed configuration synchronized without --delete."
}

synchronize_stack() {
    local stack="$1"
    local source_dir="${SOURCE_ROOT}/${stack}/"
    local live_dir="${LIVE_ROOT}/${stack}/"

    if [[ "$DRY_RUN" == "true" ]]; then
        log "DRY-RUN" "Would synchronize tracked configuration from ${source_dir} to ${live_dir}."
        log "DRY-RUN" "Would preserve live .env files and would not delete untracked runtime files."
        return
    fi

    mkdir -p -- "$live_dir"
    rsync --archive \
        --include='.env.example' \
        --exclude='.env' \
        --exclude='.env.*' \
        "$source_dir" "$live_dir"
    SYNC_COMPLETED=true
    log "OK" "Tracked stack configuration synchronized without --delete."
}

validate_live_compose() {
    local stack="$1"
    local live_dir="${LIVE_ROOT}/${stack}"
    local compose_file

    if [[ "$DRY_RUN" == "true" ]]; then
        log "DRY-RUN" "Would validate the active Compose configuration for ${stack}."
        return
    fi

    compose_file="$(find_compose_file "$live_dir")" || die "No Compose file found after synchronization: $live_dir"
    docker compose --project-directory "$live_dir" -f "$compose_file" config --quiet
    log "OK" "Active Compose configuration is valid for ${stack}."
}

show_failed_container_logs() {
    local container_id="$1"

    log "ERROR" "Recent logs for container ${container_id}:"
    docker logs --tail 50 "$container_id" 2>&1 |
        sed -E 's/((password|passwd|token|secret|api[_-]?key)[=: ]+)[^ ]+/\1[REDACTED]/Ig' || true
}

wait_for_stack() {
    local stack="$1"
    local live_dir="${LIVE_ROOT}/${stack}"
    local compose_file attempt container_id state health pending
    local -a containers=()

    compose_file="$(find_compose_file "$live_dir")"
    mapfile -t containers < <(docker compose --project-directory "$live_dir" -f "$compose_file" ps -q)
    ((${#containers[@]} > 0)) || die "Compose did not report containers for ${stack}."

    for ((attempt = 1; attempt <= HEALTH_RETRIES; attempt++)); do
        pending=false

        for container_id in "${containers[@]}"; do
            state="$(docker inspect --format '{{.State.Status}}' "$container_id")"
            health="$(docker inspect --format '{{if .State.Health}}{{.State.Health.Status}}{{else}}none{{end}}' "$container_id")"

            if [[ "$state" == "exited" || "$state" == "dead" || "$health" == "unhealthy" ]]; then
                show_failed_container_logs "$container_id"
                die "Container ${container_id} failed with state=${state}, health=${health}."
            fi

            if [[ "$state" != "running" || ("$health" != "none" && "$health" != "healthy") ]]; then
                pending=true
            fi
        done

        if [[ "$pending" == "false" ]]; then
            log "OK" "All containers for ${stack} are running or healthy."
            return
        fi

        sleep "$HEALTH_INTERVAL"
    done

    die "Containers for ${stack} did not become ready within $((HEALTH_RETRIES * HEALTH_INTERVAL)) seconds."
}

deploy_stack() {
    local stack="$1"
    local live_dir="${LIVE_ROOT}/${stack}"
    local compose_file

    CURRENT_STACK="$stack"
    CURRENT_BACKUP=""
    SYNC_COMPLETED=false

    preflight_stack "$stack"
    backup_stack_configuration "$stack"
    synchronize_stack "$stack"
    synchronize_managed_configuration "$stack"
    validate_live_compose "$stack"

    if [[ "$DRY_RUN" == "true" ]]; then
        [[ "$PULL" == "true" ]] && log "DRY-RUN" "Would pull images for ${stack}."
        log "DRY-RUN" "Would run docker compose up for ${stack}; health checks are omitted."
        log "DRY-RUN" "Simulation completed for ${stack}; no changes were made."
        return
    fi

    compose_file="$(find_compose_file "$live_dir")"
    if [[ "$PULL" == "true" ]]; then
        log "INFO" "Pulling images for ${stack}."
        docker compose --project-directory "$live_dir" -f "$compose_file" pull
    fi

    docker compose --project-directory "$live_dir" -f "$compose_file" up -d --remove-orphans
    wait_for_stack "$stack"
    log "OK" "Deployment completed for ${stack}."
}

main() {
    local stack

    parse_arguments "$@"

    if [[ "$COMMAND" == "list" ]]; then
        [[ "$PULL" == "false" && "$DRY_RUN" == "false" && "$VALIDATE" == "true" ]] || \
            die "The list command does not accept deployment options."
        list_stacks
        return
    fi

    if [[ "$COMMAND" != "all" ]]; then
        stack_exists "$COMMAND" || die "Stack is incomplete or unknown: $COMMAND"
    fi

    if [[ "$DRY_RUN" == "true" ]]; then
        require_command bash
    else
        validate_runtime_environment
        initialize_runtime
    fi

    run_repository_validation

    if [[ "$COMMAND" == "all" ]]; then
        for stack in "${DEPLOY_ORDER[@]}"; do
            stack_exists "$stack" || die "Stack in DEPLOY_ORDER is incomplete or missing: $stack"
            deploy_stack "$stack"
        done
    else
        deploy_stack "$COMMAND"
    fi
}

main "$@"

#!/usr/bin/env bash

set -Eeuo pipefail
IFS=$'\n\t'

readonly SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
readonly REPO_ROOT="$(cd -- "${SCRIPT_DIR}/.." && pwd)"

ERRORS=0
WARNINGS=0
TEMP_ENV_FILES=()

log() {
    printf '[%s] %s\n' "$1" "$2"
}

error() {
    log "ERROR" "$1" >&2
    ((ERRORS += 1))
}

warning() {
    log "WARNING" "$1" >&2
    ((WARNINGS += 1))
}

cleanup() {
    local env_file

    for env_file in "${TEMP_ENV_FILES[@]}"; do
        [[ -f "$env_file" ]] && rm -f -- "$env_file"
    done

    return 0
}

trap cleanup EXIT
trap 'exit 130' INT TERM

require_command() {
    if ! command -v "$1" >/dev/null 2>&1; then
        error "Required command not found: $1"
        return 1
    fi
}

validate_bash() {
    local script
    local -a scripts=()

    mapfile -t scripts < <(
        find "$REPO_ROOT" -type f -name '*.sh' -not -path '*/.git/*' -print | sort
    )

    for script in "${scripts[@]}"; do
        if bash -n "$script"; then
            log "OK" "Bash syntax: ${script#"${REPO_ROOT}/"}"
        else
            error "Invalid Bash syntax: ${script#"${REPO_ROOT}/"}"
        fi
    done
}

compose_requires_env() {
    grep -Eq '^[[:space:]]*env_file:[[:space:]]*$|^[[:space:]]*-[[:space:]]*\.env[[:space:]]*$' "$1"
}

validate_compose() {
    local compose_file stack_dir env_file example_file created_env=false
    local -a compose_files=()

    if ! docker compose version >/dev/null 2>&1; then
        error "Docker Compose Plugin is not available."
        return
    fi

    mapfile -t compose_files < <(
        find "${REPO_ROOT}/stacks" -type f \
            \( -name 'docker-compose.yml' -o -name 'docker-compose.yaml' \
               -o -name 'compose.yml' -o -name 'compose.yaml' \) -print | sort
    )

    for compose_file in "${compose_files[@]}"; do
        stack_dir="$(dirname -- "$compose_file")"
        env_file="${stack_dir}/.env"
        example_file="${stack_dir}/.env.example"
        created_env=false

        if compose_requires_env "$compose_file" && [[ ! -f "$env_file" ]]; then
            if [[ ! -f "$example_file" ]]; then
                error "Missing .env.example for ${compose_file#"${REPO_ROOT}/"}"
                continue
            fi

            cp -- "$example_file" "$env_file"
            TEMP_ENV_FILES+=("$env_file")
            created_env=true
        fi

        if docker compose --project-directory "$stack_dir" -f "$compose_file" config --quiet; then
            log "OK" "Compose: ${compose_file#"${REPO_ROOT}/"}"
        else
            error "Invalid Compose file: ${compose_file#"${REPO_ROOT}/"}"
        fi

        if [[ "$created_env" == "true" ]]; then
            rm -f -- "$env_file"
        fi
    done
}

validate_sensitive_files() {
    local finding

    while IFS= read -r finding; do
        error "Real environment file is present: ${finding#"${REPO_ROOT}/"}"
    done < <(find "$REPO_ROOT" -type f -name '.env' -not -path '*/.git/*' -print)

    while IFS= read -r finding; do
        error "Private key material detected: ${finding#"${REPO_ROOT}/"}"
    done < <(
        grep -RIlE 'BEGIN ([A-Z ]+ )?PRIVATE KEY' "$REPO_ROOT" \
            --exclude-dir=.git 2>/dev/null || true
    )

    while IFS= read -r finding; do
        error "Possible backup artifact: ${finding#"${REPO_ROOT}/"}"
    done < <(
        find "$REPO_ROOT" -type f -not -path '*/.git/*' \
            \( -name '*.tar' -o -name '*.tar.gz' -o -name '*.bak' \
               -o -name '*.backup' -o -name '*.old' \) -print
    )
}

main() {
    cd "$REPO_ROOT"

    require_command bash || true
    require_command docker || true
    require_command find || true
    require_command grep || true

    validate_bash
    validate_sensitive_files

    if command -v docker >/dev/null 2>&1; then
        validate_compose
    fi

    printf '\nValidation summary: %d error(s), %d warning(s).\n' "$ERRORS" "$WARNINGS"
    ((ERRORS == 0))
}

main "$@"

#!/usr/bin/env bash

set -Eeuo pipefail
IFS=$'\n\t'

readonly ROOT="/opt/quesadalab"
readonly STACK_DIR="${ROOT}/stacks/nextcloud"
readonly ENV_FILE="${STACK_DIR}/.env"
readonly COMPOSE_FILE="${STACK_DIR}/docker-compose.yml"
readonly LOG_DIR="${ROOT}/logs"
readonly LOG_FILE="${LOG_DIR}/nextcloud-restore.log"
WORK_DIR=""

log() {
    printf '[%s] [%s] %s\n' "$(date '+%Y-%m-%d %H:%M:%S')" "$1" "$2" |
        tee -a "$LOG_FILE"
}

cleanup() {
    local status=$?
    [[ -z "$WORK_DIR" || ! -d "$WORK_DIR" ]] || rm -rf -- "$WORK_DIR"
    [[ $status -eq 0 ]] || log ERROR "La restauración terminó con código ${status}."
}
trap cleanup EXIT
trap 'log ERROR "Fallo en la línea ${LINENO}."' ERR

compose() {
    docker compose --env-file "$ENV_FILE" --project-directory "$STACK_DIR" \
        -f "$COMPOSE_FILE" "$@"
}

validate_backup() {
    local backup_dir="$1"
    local required

    [[ $EUID -eq 0 ]] || { log ERROR "Debe ejecutarse como root."; return 1; }
    [[ -d "$backup_dir" ]] || { log ERROR "No existe ${backup_dir}."; return 1; }

    for required in database.dump application.tar.gz user-data.tar.gz SHA256SUMS; do
        [[ -s "${backup_dir}/${required}" ]] || {
            log ERROR "Falta ${required}."
            return 1
        }
    done

    (cd "$backup_dir" && sha256sum --check SHA256SUMS)

    if tar -tzf "${backup_dir}/application.tar.gz" |
        grep -Eq '(^/|(^|/)\.\.(/|$))'; then
        log ERROR "application.tar.gz contiene una ruta insegura."
        return 1
    fi

    if tar -tzf "${backup_dir}/user-data.tar.gz" |
        grep -Eq '(^/|(^|/)\.\.(/|$))'; then
        log ERROR "user-data.tar.gz contiene una ruta insegura."
        return 1
    fi

    tar -tzf "${backup_dir}/application.tar.gz" |
        grep -Fxq 'opt/quesadalab/stacks/nextcloud/.env'
    tar -tzf "${backup_dir}/user-data.tar.gz" |
        grep -q '^srv/nextcloud-data/user-data/'
}

confirm_restore() {
    printf '\nSe reemplazarán PostgreSQL, la aplicación, secretos y datos de usuarios.\n'
    read -r -p 'Escriba RESTORE-NEXTCLOUD para continuar: ' answer
    [[ "$answer" == RESTORE-NEXTCLOUD ]] || { log WARNING "Operación cancelada."; exit 0; }
}

restore_files() {
    local backup_dir="$1"
    WORK_DIR="$(mktemp -d /tmp/nextcloud-restore.XXXXXX)"
    tar -xzf "${backup_dir}/application.tar.gz" -C "$WORK_DIR"
    tar -xzf "${backup_dir}/user-data.tar.gz" -C "$WORK_DIR"

    compose down
    rsync -a --delete "${WORK_DIR}/opt/quesadalab/data/nextcloud/html/" \
        "${ROOT}/data/nextcloud/html/"
    rsync -a --delete "${WORK_DIR}/srv/nextcloud-data/user-data/" \
        /srv/nextcloud-data/user-data/
    rsync -a --delete "${WORK_DIR}/opt/quesadalab/stacks/nextcloud/" "$STACK_DIR/"
    rsync -a --delete "${WORK_DIR}/opt/quesadalab/config/nextcloud/" \
        "${ROOT}/config/nextcloud/"
    rsync -a --delete "${WORK_DIR}/opt/quesadalab/security/nextcloud/" \
        "${ROOT}/security/nextcloud/"

    compose up -d db redis
    for _ in {1..30}; do
        [[ "$(docker inspect -f '{{if .State.Health}}{{.State.Health.Status}}{{end}}' nextcloud-db)" == healthy ]] && break
        sleep 2
    done

    docker exec -i nextcloud-db pg_restore --username nextcloud --dbname nextcloud \
        --clean --if-exists --no-owner < "${backup_dir}/database.dump"
    compose up -d
}

main() {
    local backup_dir="${1:-}"
    mkdir -p "$LOG_DIR"
    [[ -n "$backup_dir" ]] || { echo "Uso: $0 /ruta/al/backup"; exit 1; }
    validate_backup "$backup_dir"
    confirm_restore
    restore_files "$backup_dir"
    log SUCCESS "Restauración completada; valide estado, endpoint y acceso."
}

main "$@"

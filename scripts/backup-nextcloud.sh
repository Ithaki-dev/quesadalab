#!/usr/bin/env bash

set -Eeuo pipefail
IFS=$'\n\t'

readonly SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
readonly ROOT="/opt/quesadalab"
readonly STACK_DIR="${ROOT}/stacks/nextcloud"
readonly APP_DIR="${ROOT}/data/nextcloud/html"
readonly DATA_DIR="/srv/nextcloud-data/user-data"
readonly CONFIG_DIR="${ROOT}/config/nextcloud"
readonly SECURITY_DIR="${ROOT}/security/nextcloud"
readonly BACKUP_ROOT="${NEXTCLOUD_BACKUP_ROOT:-${ROOT}/backups/nextcloud}"
readonly LOG_DIR="${ROOT}/logs"
readonly TIMESTAMP="$(date '+%Y-%m-%d_%H-%M-%S')"
readonly BACKUP_DIR="${BACKUP_ROOT}/${TIMESTAMP}"
readonly LOCK_FILE="/run/lock/quesadalab-nextcloud-backup.lock"
readonly RETENTION_LIBRARY="${SCRIPT_DIR}/lib/retention.sh"
readonly RETENTION="${NEXTCLOUD_BACKUP_RETENTION:-3}"
readonly APP_CONTAINER="nextcloud"
readonly DB_CONTAINER="nextcloud-db"
readonly LOG_FILE="${LOG_DIR}/nextcloud-backup.log"

MAINTENANCE_ENABLED=false
BACKUP_COMPLETE=false

log() {
    printf '[%s] [%s] %s\n' "$(date '+%Y-%m-%d %H:%M:%S')" "$1" "$2" |
        tee -a "$LOG_FILE"
}

cleanup() {
    local status=$?

    if [[ "$MAINTENANCE_ENABLED" == "true" ]]; then
        docker exec --user www-data "$APP_CONTAINER" \
            php occ maintenance:mode --off >/dev/null 2>&1 ||
            log ERROR "No fue posible desactivar el modo mantenimiento."
    fi

    if [[ $status -ne 0 && "$BACKUP_COMPLETE" != "true" ]]; then
        log ERROR "El respaldo no terminó correctamente (código ${status})."
    fi
}

trap cleanup EXIT
trap 'log ERROR "Fallo en la línea ${LINENO}."' ERR

validate_environment() {
    local command_name path

    [[ $EUID -eq 0 ]] || { log ERROR "Debe ejecutarse como root."; return 1; }

    for command_name in df docker du findmnt flock sha256sum tar tee; do
        command -v "$command_name" >/dev/null 2>&1 || {
            log ERROR "Falta el comando requerido: ${command_name}"
            return 1
        }
    done

    for path in "$STACK_DIR" "$APP_DIR" "$DATA_DIR" "$CONFIG_DIR" "$SECURITY_DIR"; do
        [[ -d "$path" ]] || { log ERROR "No existe: ${path}"; return 1; }
    done

    docker inspect "$APP_CONTAINER" "$DB_CONTAINER" >/dev/null
    [[ "$(docker inspect -f '{{.State.Running}}' "$APP_CONTAINER")" == true ]]
    [[ "$(docker inspect -f '{{.State.Running}}' "$DB_CONTAINER")" == true ]]

    mkdir -p "$BACKUP_ROOT" "$BACKUP_DIR" "$LOG_DIR"
    chmod 0700 "$BACKUP_DIR"

    local required_bytes available_bytes
    required_bytes="$((
        $(du -sb "$APP_DIR" "$DATA_DIR" | awk '{total += $1} END {print total}') +
        1073741824
    ))"
    available_bytes="$(df --output=avail -B1 "$BACKUP_ROOT" | awk 'NR == 2 {print $1}')"

    if (( available_bytes < required_bytes )); then
        log ERROR "Espacio insuficiente en ${BACKUP_ROOT}; use un destino externo."
        return 1
    fi
}

enable_maintenance() {
    log INFO "Activando modo mantenimiento."
    docker exec --user www-data "$APP_CONTAINER" php occ maintenance:mode --on
    MAINTENANCE_ENABLED=true
}

create_backup() {
    log INFO "Exportando PostgreSQL."
    docker exec "$DB_CONTAINER" pg_dump \
        --username nextcloud --dbname nextcloud --format=custom --no-owner \
        > "${BACKUP_DIR}/database.dump"
    [[ -s "${BACKUP_DIR}/database.dump" ]] || {
        log ERROR "El volcado PostgreSQL está vacío."
        return 1
    }

    log INFO "Archivando aplicación y configuración."
    tar -czf "${BACKUP_DIR}/application.tar.gz" \
        -C / opt/quesadalab/data/nextcloud/html \
        opt/quesadalab/stacks/nextcloud \
        opt/quesadalab/config/nextcloud \
        opt/quesadalab/security/nextcloud

    log INFO "Archivando datos de usuarios."
    tar -czf "${BACKUP_DIR}/user-data.tar.gz" \
        -C / srv/nextcloud-data/user-data

    chmod 0600 "${BACKUP_DIR}"/*

    (
        cd "$BACKUP_DIR"
        sha256sum database.dump application.tar.gz user-data.tar.gz > SHA256SUMS
        sha256sum --check SHA256SUMS
        tar -tzf application.tar.gz >/dev/null
        tar -tzf user-data.tar.gz >/dev/null
    )
}

create_manifest() {
    {
        printf 'QuesadaLab Nextcloud Backup\n'
        printf 'Timestamp: %s\n' "$TIMESTAMP"
        printf 'Hostname: %s\n' "$(hostname)"
        printf 'Nextcloud image: %s\n' "$(docker inspect -f '{{.Config.Image}}' "$APP_CONTAINER")"
        printf 'PostgreSQL image: %s\n' "$(docker inspect -f '{{.Config.Image}}' "$DB_CONTAINER")"
        printf 'Backup directory: %s\n' "$BACKUP_DIR"
        du -h "${BACKUP_DIR}"/*
    } > "${BACKUP_DIR}/manifest.txt"
    chmod 0600 "${BACKUP_DIR}/manifest.txt"
}

main() {
    mkdir -p "$LOG_DIR"
    exec 9>"$LOCK_FILE"
    flock -n 9 || { log ERROR "Ya existe otro respaldo en ejecución."; exit 1; }

    log INFO "Iniciando respaldo consistente de Nextcloud."
    validate_environment
    enable_maintenance
    create_backup
    create_manifest
    docker exec --user www-data "$APP_CONTAINER" php occ maintenance:mode --off
    MAINTENANCE_ENABLED=false

    # shellcheck source=/dev/null
    source "$RETENTION_LIBRARY"
    prune_backup_sets "$BACKUP_ROOT" "$RETENTION" false

    BACKUP_COMPLETE=true
    log SUCCESS "Respaldo completado: ${BACKUP_DIR}"
}

main "$@"

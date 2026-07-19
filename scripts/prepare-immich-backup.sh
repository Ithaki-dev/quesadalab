#!/usr/bin/env bash

set -Eeuo pipefail
IFS=$'\n\t'

readonly ROOT="/opt/quesadalab"
readonly STACK_DIR="${ROOT}/stacks/immich"
readonly SECURITY_DIR="${ROOT}/security/immich"
readonly BACKUP_ROOT="${IMMICH_BACKUP_ROOT:-${ROOT}/backups/immich}"
readonly RETENTION="${IMMICH_PREPARED_RETENTION:-3}"
readonly TIMESTAMP="$(date '+%Y-%m-%d_%H-%M-%S')"
readonly BACKUP_DIR="${BACKUP_ROOT}/${TIMESTAMP}"
readonly LOG_DIR="${ROOT}/logs"
readonly LOG_FILE="${LOG_DIR}/immich-backup.log"
readonly LOCK_FILE="/run/lock/quesadalab-immich-backup.lock"
readonly DB_CONTAINER="immich-postgres"
readonly SERVER_CONTAINER="immich-server"

log() {
    printf '[%s] [%s] %s\n' "$(date '+%Y-%m-%d %H:%M:%S')" "$1" "$2" |
        tee -a "$LOG_FILE"
}

cleanup() {
    local status=$?
    if [[ $status -ne 0 && -d "$BACKUP_DIR" ]]; then
        rm -rf --one-file-system -- "$BACKUP_DIR"
    fi
    [[ $status -eq 0 ]] || log ERROR "La preparacion termino con codigo ${status}."
}

trap cleanup EXIT
trap 'log ERROR "Fallo en la linea ${LINENO}."' ERR

validate_environment() {
    local command_name

    [[ $EUID -eq 0 ]] || { log ERROR "Debe ejecutarse como root."; return 1; }
    [[ "$RETENTION" =~ ^[1-9][0-9]*$ ]] || {
        log ERROR "La retencion debe ser un entero mayor que cero."
        return 1
    }

    for command_name in docker find findmnt flock gzip sha256sum sort tar tee; do
        command -v "$command_name" >/dev/null 2>&1 || {
            log ERROR "Falta el comando requerido: ${command_name}"
            return 1
        }
    done

    [[ -f "${STACK_DIR}/.env" ]] || { log ERROR "Falta ${STACK_DIR}/.env."; return 1; }
    [[ -d "$SECURITY_DIR" ]] || { log ERROR "Falta ${SECURITY_DIR}."; return 1; }
    [[ -d /srv/immich-data/library ]] || { log ERROR "Falta la biblioteca Immich."; return 1; }
    findmnt -rn --target /srv/immich-data >/dev/null || {
        log ERROR "/srv/immich-data no esta montado."
        return 1
    }

    for container in "$DB_CONTAINER" "$SERVER_CONTAINER"; do
        [[ "$(docker inspect -f '{{.State.Running}}' "$container")" == true ]] || {
            log ERROR "El contenedor ${container} no esta activo."
            return 1
        }
    done
}

create_backup() {
    mkdir -p "$BACKUP_ROOT" "$BACKUP_DIR" "$LOG_DIR"
    chmod 0700 "$BACKUP_ROOT" "$BACKUP_DIR"

    log INFO "Exportando PostgreSQL antes de copiar la biblioteca."
    docker exec "$DB_CONTAINER" pg_dump --clean --if-exists \
        --username immich --dbname immich |
        gzip -c > "${BACKUP_DIR}/database.sql.gz"
    [[ -s "${BACKUP_DIR}/database.sql.gz" ]]

    log INFO "Archivando configuracion y secretos."
    tar -czf "${BACKUP_DIR}/configuration.tar.gz" -C / \
        opt/quesadalab/stacks/immich \
        opt/quesadalab/security/immich

    {
        printf 'QuesadaLab Immich Backup Preparation\n'
        printf 'Timestamp: %s\n' "$TIMESTAMP"
        printf 'Hostname: %s\n' "$(hostname)"
        printf 'Immich image: %s\n' "$(docker inspect -f '{{.Config.Image}}' "$SERVER_CONTAINER")"
        printf 'PostgreSQL image: %s\n' "$(docker inspect -f '{{.Config.Image}}' "$DB_CONTAINER")"
        printf 'Media source: /srv/immich-data/library\n'
    } > "${BACKUP_DIR}/manifest.txt"

    chmod 0600 "${BACKUP_DIR}"/*
    (
        cd "$BACKUP_DIR"
        sha256sum database.sql.gz configuration.tar.gz manifest.txt > SHA256SUMS
        sha256sum --check SHA256SUMS
        gzip -t database.sql.gz
        tar -tzf configuration.tar.gz >/dev/null
    )
}

apply_retention() {
    local -a sets=()
    local index

    mapfile -d '' -t sets < <(
        find "$BACKUP_ROOT" -mindepth 1 -maxdepth 1 -type d \
            -name '????-??-??_??-??-??' -printf '%p\0' | sort -z -r
    )

    for ((index = RETENTION; index < ${#sets[@]}; index++)); do
        log INFO "Eliminando preparacion antigua: ${sets[$index]}"
        rm -rf --one-file-system -- "${sets[$index]}"
    done
}

main() {
    mkdir -p "$LOG_DIR"
    exec 9>"$LOCK_FILE"
    flock -n 9 || { log ERROR "Ya existe otra preparacion en ejecucion."; exit 1; }
    validate_environment
    create_backup
    apply_retention
    log SUCCESS "Preparacion completada: ${BACKUP_DIR}"
}

main "$@"

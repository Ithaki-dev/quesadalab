#!/usr/bin/env bash

set -Eeuo pipefail
IFS=$'\n\t'

readonly ROOT="/opt/quesadalab"
readonly STACK_DIR="${ROOT}/stacks/jellyfin"
readonly CONFIG_DIR="${ROOT}/data/jellyfin/config"
readonly BACKUP_ROOT="${JELLYFIN_BACKUP_ROOT:-${ROOT}/backups/jellyfin}"
readonly RETENTION="${JELLYFIN_BACKUP_RETENTION:-3}"
readonly TIMESTAMP="$(date '+%Y-%m-%d_%H-%M-%S')"
readonly BACKUP_DIR="${BACKUP_ROOT}/${TIMESTAMP}"
readonly LOG_DIR="${ROOT}/logs"
readonly LOG_FILE="${LOG_DIR}/jellyfin-backup.log"
readonly LOCK_FILE="/run/lock/quesadalab-jellyfin-backup.lock"
readonly CONTAINER="jellyfin"

CONTAINER_STOPPED=false

log() {
    printf '[%s] [%s] %s\n' "$(date '+%Y-%m-%d %H:%M:%S')" "$1" "$2" |
        tee -a "$LOG_FILE"
}

start_jellyfin() {
    local attempt
    [[ "$CONTAINER_STOPPED" == true ]] || return 0
    log INFO "Iniciando Jellyfin."
    docker start "$CONTAINER" >/dev/null
    CONTAINER_STOPPED=false
    for attempt in {1..60}; do
        [[ "$(docker inspect -f '{{if .State.Health}}{{.State.Health.Status}}{{end}}' "$CONTAINER")" == healthy ]] && return 0
        sleep 2
    done
    log ERROR "Jellyfin no alcanzo estado healthy despues del respaldo."
    return 1
}

cleanup() {
    local status=$?
    if [[ "$CONTAINER_STOPPED" == true ]]; then
        start_jellyfin || status=1
    fi
    if [[ $status -ne 0 && -d "$BACKUP_DIR" ]]; then
        rm -rf --one-file-system -- "$BACKUP_DIR"
    fi
    [[ $status -eq 0 ]] || log ERROR "El respaldo termino con codigo ${status}."
    exit "$status"
}

trap cleanup EXIT
trap 'log ERROR "Fallo en la linea ${LINENO}."' ERR

validate_environment() {
    local command_name
    [[ $EUID -eq 0 ]] || { log ERROR "Debe ejecutarse como root."; return 1; }
    [[ "$RETENTION" =~ ^[1-9][0-9]*$ ]] || return 1
    for command_name in awk df docker du find flock sha256sum sort tar tee; do
        command -v "$command_name" >/dev/null 2>&1 || {
            log ERROR "Falta el comando requerido: ${command_name}"
            return 1
        }
    done
    [[ -f "${STACK_DIR}/.env" && -f "${STACK_DIR}/docker-compose.yml" ]] || {
        log ERROR "Falta la configuracion activa de Jellyfin."
        return 1
    }
    [[ -d "$CONFIG_DIR" ]] || { log ERROR "Falta ${CONFIG_DIR}."; return 1; }
    [[ -s "${CONFIG_DIR}/data/jellyfin.db" ]] || {
        log ERROR "Falta la base SQLite ${CONFIG_DIR}/data/jellyfin.db."
        return 1
    }
    [[ "$(docker inspect -f '{{.State.Running}}' "$CONTAINER")" == true ]] || {
        log ERROR "El contenedor Jellyfin no esta activo."
        return 1
    }
}

create_backup() {
    local source_bytes available_bytes required_bytes
    mkdir -p "$BACKUP_ROOT" "$BACKUP_DIR" "$LOG_DIR"
    chmod 0700 "$BACKUP_ROOT" "$BACKUP_DIR"

    source_bytes="$(du -sb "$CONFIG_DIR" "$STACK_DIR" | awk '{total += $1} END {print total}')"
    available_bytes="$(df --output=avail -B1 "$BACKUP_ROOT" | awk 'NR == 2 {print $1}')"
    required_bytes=$((source_bytes * 2 + 104857600))
    if (( available_bytes < required_bytes )); then
        log ERROR "Espacio insuficiente para el respaldo Jellyfin."
        return 1
    fi

    log INFO "Deteniendo Jellyfin para obtener una copia consistente de SQLite."
    docker stop --time 60 "$CONTAINER" >/dev/null
    CONTAINER_STOPPED=true

    log INFO "Archivando configuracion, base de datos, usuarios, plugins y metadatos."
    tar -czf "${BACKUP_DIR}/configuration.tar.gz" -C / \
        opt/quesadalab/data/jellyfin/config \
        opt/quesadalab/stacks/jellyfin

    start_jellyfin

    {
        printf 'QuesadaLab Jellyfin Configuration Backup\n'
        printf 'Timestamp: %s\n' "$TIMESTAMP"
        printf 'Hostname: %s\n' "$(hostname)"
        printf 'Image: %s\n' "$(docker inspect -f '{{.Config.Image}}' "$CONTAINER")"
        printf 'Included: /opt/quesadalab/data/jellyfin/config and active stack\n'
        printf 'Excluded: /srv/jellyfin-media (all media, cache and transcodes)\n'
    } > "${BACKUP_DIR}/manifest.txt"

    chmod 0600 "${BACKUP_DIR}"/*
    (
        cd "$BACKUP_DIR"
        sha256sum configuration.tar.gz manifest.txt > SHA256SUMS
        sha256sum --check SHA256SUMS
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
        log INFO "Eliminando respaldo antiguo: ${sets[$index]}"
        rm -rf --one-file-system -- "${sets[$index]}"
    done
}

main() {
    mkdir -p "$LOG_DIR"
    exec 9>"$LOCK_FILE"
    flock -n 9 || { log ERROR "Ya existe otro respaldo en ejecucion."; exit 1; }
    validate_environment
    create_backup
    apply_retention
    log SUCCESS "Respaldo completado: ${BACKUP_DIR}"
}

main "$@"

#!/usr/bin/env bash

set -Eeuo pipefail

readonly SCRIPT_NAME="$(basename "$0")"
readonly BACKUP_ROOT="/opt/quesadalab/backups/daily"
readonly QUESADALAB_ROOT="/opt/quesadalab"
readonly DATA_DIR="${QUESADALAB_ROOT}/data/vaultwarden"
readonly STACK_DIR="${QUESADALAB_ROOT}/stacks/vaultwarden"
readonly LOG_DIR="${QUESADALAB_ROOT}/logs/backups"
readonly LOG_FILE="${LOG_DIR}/vaultwarden-restore.log"
readonly CONTAINER_NAME="vaultwarden"

CONTAINER_WAS_RUNNING=false
WORK_DIR=""

log() {
    local level="$1"
    shift

    printf '[%s] [%s] %s\n' \
        "$(date '+%Y-%m-%d %H:%M:%S')" \
        "$level" \
        "$*" | tee -a "$LOG_FILE"
}

cleanup() {
    local exit_code=$?

    if [[ -n "${WORK_DIR}" && -d "${WORK_DIR}" ]]; then
        rm -rf "${WORK_DIR}"
    fi

    if [[ "${CONTAINER_WAS_RUNNING}" == "true" ]]; then
        if ! docker inspect -f '{{.State.Running}}' "$CONTAINER_NAME" 2>/dev/null \
            | grep -q '^true$'; then
            log "INFO" "Reiniciando ${CONTAINER_NAME} después de la restauración..."
            docker start "$CONTAINER_NAME" >/dev/null || \
                log "ERROR" "No se pudo reiniciar ${CONTAINER_NAME}."
        fi
    fi

    if [[ $exit_code -ne 0 ]]; then
        log "ERROR" "La restauración terminó con errores. Código: ${exit_code}"
    fi
}

trap cleanup EXIT
trap 'log "ERROR" "Error en la línea ${LINENO}: ${BASH_COMMAND}"' ERR

usage() {
    cat <<EOF
Uso:

  ${SCRIPT_NAME} /ruta/al/directorio-del-backup

Ejemplo:

  ${SCRIPT_NAME} /opt/quesadalab/backups/daily/2026-07-17_07-34-30
EOF
}

validate_environment() {
    local backup_dir="$1"

    mkdir -p "$LOG_DIR"

    command -v docker >/dev/null 2>&1 || {
        log "ERROR" "Docker no está instalado."
        exit 1
    }

    command -v tar >/dev/null 2>&1 || {
        log "ERROR" "tar no está instalado."
        exit 1
    }

    command -v sha256sum >/dev/null 2>&1 || {
        log "ERROR" "sha256sum no está instalado."
        exit 1
    }

    [[ -d "$backup_dir" ]] || {
        log "ERROR" "No existe el directorio de respaldo: ${backup_dir}"
        exit 1
    }

    compgen -G "${backup_dir}/vaultwarden-*.tar.gz" >/dev/null || {
        log "ERROR" "No se encontró el archivo vaultwarden-*.tar.gz."
        exit 1
    }

    compgen -G "${backup_dir}/vaultwarden-*.tar.gz.sha256" >/dev/null || {
        log "ERROR" "No se encontró el archivo de checksum."
        exit 1
    }

    docker inspect "$CONTAINER_NAME" >/dev/null 2>&1 || {
        log "ERROR" "No existe el contenedor ${CONTAINER_NAME}."
        exit 1
    }
}


confirm_restore() {
    local backup_dir="$1"

    echo
    echo "ADVERTENCIA"
    echo "==========="
    echo
    echo "Se restaurará Vaultwarden usando:"
    echo
    echo "  ${backup_dir}"
    echo
    echo "Esto reemplazará:"
    echo
    echo "  ${DATA_DIR}"
    echo "  ${STACK_DIR}"
    echo

    read -r -p "Escriba RESTAURAR para continuar: " answer

    if [[ "$answer" != "RESTAURAR" ]]; then
        log "WARN" "Restauración cancelada por el usuario."
        exit 0
    fi
}

create_safety_backup() {
    local timestamp
    local safety_dir

    timestamp="$(date '+%Y-%m-%d_%H-%M-%S')"
    safety_dir="${QUESADALAB_ROOT}/backups/pre-restore/${timestamp}"

    mkdir -p "$safety_dir"

    log "INFO" "Creando respaldo preventivo del estado actual..."

    tar \
        --create \
        --gzip \
        --file "${safety_dir}/vaultwarden-pre-restore.tar.gz" \
        --directory "$QUESADALAB_ROOT" \
        "data/vaultwarden" \
        "stacks/vaultwarden"

    (
        cd "$safety_dir"
        sha256sum "vaultwarden-pre-restore.tar.gz" \
            > "vaultwarden-pre-restore.tar.gz.sha256"
    )

    log "INFO" "Respaldo preventivo creado en ${safety_dir}"
}

stop_container() {
    if docker inspect -f '{{.State.Running}}' "$CONTAINER_NAME" \
        | grep -q '^true$'; then
        CONTAINER_WAS_RUNNING=true

        log "INFO" "Deteniendo temporalmente ${CONTAINER_NAME}..."
        docker stop --time 30 "$CONTAINER_NAME" >/dev/null
    else
        log "WARN" "El contenedor ya estaba detenido."
    fi
}

verify_backup() {
    local backup_dir="$1"
    local archive
    local checksum
    local archive_listing

    archive="$(
        find "$backup_dir" \
            -maxdepth 1 \
            -type f \
            -name 'vaultwarden-*.tar.gz' \
            | sort \
            | head -n 1
    )"

    [[ -n "$archive" ]] || {
        log "ERROR" "No se encontró el archivo de respaldo."
        exit 1
    }

    checksum="${archive}.sha256"
    archive_listing="$(mktemp /tmp/vaultwarden-archive-list.XXXXXX)"

    log "INFO" "Verificando checksum..."

    (
        cd "$backup_dir"
        sha256sum --check "$(basename "$checksum")"
    )

    log "INFO" "Validando contenido del archivo..."

    tar -tzf "$archive" > "$archive_listing"

    if ! grep -Fxq "data/vaultwarden/db.sqlite3" "$archive_listing"; then
        rm -f "$archive_listing"
        log "ERROR" "El respaldo no contiene data/vaultwarden/db.sqlite3."
        exit 1
    fi

    if ! grep -Fq "stacks/vaultwarden/" "$archive_listing"; then
        rm -f "$archive_listing"
        log "ERROR" "El respaldo no contiene stacks/vaultwarden."
        exit 1
    fi

    rm -f "$archive_listing"

    log "INFO" "La estructura del respaldo es válida."
}
  
extract_backup() {
    local backup_dir="$1"
    local archive

    archive="$(
        find "$backup_dir" \
            -maxdepth 1 \
            -type f \
            -name 'vaultwarden-*.tar.gz' \
            | sort \
            | head -n 1
    )"

    [[ -n "$archive" ]] || {
        log "ERROR" "No se encontró el archivo de respaldo para extraer."
        exit 1
    }

    WORK_DIR="$(mktemp -d /tmp/vaultwarden-restore.XXXXXX)"

    log "INFO" "Extrayendo respaldo en el área temporal ${WORK_DIR}..."

    tar \
        --extract \
        --gzip \
        --file "$archive" \
        --directory "$WORK_DIR"

    [[ -f "${WORK_DIR}/data/vaultwarden/db.sqlite3" ]] || {
        log "ERROR" "La extracción no contiene data/vaultwarden/db.sqlite3."
        exit 1
    }

    [[ -d "${WORK_DIR}/stacks/vaultwarden" ]] || {
        log "ERROR" "La extracción no contiene stacks/vaultwarden."
        exit 1
    }

    log "INFO" "Respaldo extraído correctamente."
}
    

verify_sqlite() {
    local db_path="${WORK_DIR}/data/vaultwarden/db.sqlite3"

    log "INFO" "Verificando integridad de SQLite..."

    python3 - "$db_path" <<'PY'
import sqlite3
import sys

db_path = sys.argv[1]

connection = sqlite3.connect(f"file:{db_path}?mode=ro", uri=True)
result = connection.execute("PRAGMA integrity_check;").fetchone()[0]
connection.close()

print(f"Integridad SQLite: {result}")

if result != "ok":
    raise SystemExit(1)
PY
}

replace_current_files() {
    log "INFO" "Reemplazando los datos actuales..."

    rm -rf "$DATA_DIR"
    rm -rf "$STACK_DIR"

    mkdir -p "$(dirname "$DATA_DIR")"
    mkdir -p "$(dirname "$STACK_DIR")"

    cp -a "${WORK_DIR}/data/vaultwarden" "$DATA_DIR"
    cp -a "${WORK_DIR}/stacks/vaultwarden" "$STACK_DIR"
}

start_container() {
    log "INFO" "Iniciando ${CONTAINER_NAME}..."

    docker start "$CONTAINER_NAME" >/dev/null

    sleep 5

    if ! docker inspect -f '{{.State.Running}}' "$CONTAINER_NAME" \
        | grep -q '^true$'; then
        log "ERROR" "Vaultwarden no quedó en ejecución."
        exit 1
    fi

    CONTAINER_WAS_RUNNING=false
}

verify_service() {
    log "INFO" "Verificando el endpoint de salud..."

    for attempt in {1..12}; do
        if curl \
            --silent \
            --fail \
            --output /dev/null \
            https://vault.lab/alive; then
            log "SUCCESS" "Vaultwarden responde correctamente."
            return 0
        fi

        sleep 5
    done

    log "ERROR" "Vaultwarden no respondió correctamente después de restaurar."
    exit 1
}

main() {
    local backup_dir="${1:-}"

    if [[ -z "$backup_dir" ]]; then
        usage
        exit 1
    fi

    log "INFO" "Iniciando restauración de Vaultwarden."

    validate_environment "$backup_dir"
    verify_backup "$backup_dir"
    confirm_restore "$backup_dir"
    create_safety_backup
    stop_container
    extract_backup "$backup_dir"
    verify_sqlite
    replace_current_files
    start_container
    verify_service

    log "SUCCESS" "Restauración completada correctamente."
}

main "$@"

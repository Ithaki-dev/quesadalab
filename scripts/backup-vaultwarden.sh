#!/usr/bin/env bash

# ==============================================================================
# QuesadaLab Backup Framework
# Respaldo automatizado de Vaultwarden
#
# Funciones principales:
#   - Validación del entorno
#   - Detención controlada de Vaultwarden
#   - Creación de respaldo consistente
#   - Checksum SHA-256
#   - Verificación del archivo
#   - Generación de manifest
#   - Reinicio del contenedor
#   - Verificación del estado Docker
#   - Verificación externa mediante Traefik
#   - Retención automática
#   - Manejo de errores y recuperación
# ==============================================================================

set -Eeuo pipefail
IFS=$'\n\t'

# ==============================================================================
# Configuración general
# ==============================================================================

readonly SCRIPT_DIR="$(
    cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &&
    pwd
)"

readonly QUESADALAB_ROOT="/opt/quesadalab"

readonly DATA_SOURCE="${QUESADALAB_ROOT}/data/vaultwarden"
readonly STACK_SOURCE="${QUESADALAB_ROOT}/stacks/vaultwarden"

readonly BACKUP_ROOT="${QUESADALAB_ROOT}/backups/daily"
readonly LOG_DIR="${QUESADALAB_ROOT}/logs"

readonly RETENTION_LIBRARY="${SCRIPT_DIR}/lib/retention.sh"
readonly DAILY_RETENTION=7

readonly CONTAINER_NAME="vaultwarden"
readonly HEALTH_URL="https://vault.lab/alive"

readonly TIMESTAMP="$(date '+%Y-%m-%d_%H-%M-%S')"
readonly BACKUP_DIR="${BACKUP_ROOT}/${TIMESTAMP}"

readonly ARCHIVE_NAME="vaultwarden-${TIMESTAMP}.tar.gz"
readonly ARCHIVE_PATH="${BACKUP_DIR}/${ARCHIVE_NAME}"
readonly CHECKSUM_PATH="${ARCHIVE_PATH}.sha256"
readonly MANIFEST_PATH="${BACKUP_DIR}/manifest.txt"
readonly LOG_FILE="${LOG_DIR}/vaultwarden-backup.log"

# Docker health check:
# 24 intentos × 5 segundos = máximo 120 segundos.
readonly CONTAINER_HEALTH_RETRIES=24
readonly CONTAINER_HEALTH_INTERVAL=5

# Verificación externa mediante Traefik.
readonly EXTERNAL_CHECK_RETRIES=3
readonly EXTERNAL_CHECK_INTERVAL=3

CONTAINER_WAS_RUNNING=false
BACKUP_COMPLETED=false

# ==============================================================================
# Biblioteca de retención
# ==============================================================================

if [[ ! -r "$RETENTION_LIBRARY" ]]; then
    printf '[%s] [ERROR] No se puede leer la biblioteca de retención: %s\n' \
        "$(date '+%Y-%m-%d %H:%M:%S')" \
        "$RETENTION_LIBRARY" >&2
    exit 1
fi

# shellcheck source=/dev/null
source "$RETENTION_LIBRARY"

# ==============================================================================
# Logging
# ==============================================================================

log() {
    local level="$1"
    shift

    local message="$*"
    local current_timestamp

    current_timestamp="$(date '+%Y-%m-%d %H:%M:%S')"

    mkdir -p "$LOG_DIR"

    printf '[%s] [%s] %s\n' \
        "$current_timestamp" \
        "$level" \
        "$message" |
        tee -a "$LOG_FILE"
}

# ==============================================================================
# Manejo de errores
# ==============================================================================

handle_error() {
    local exit_code=$?
    local line_number="${1:-desconocida}"

    log "ERROR" \
        "El respaldo falló en la línea ${line_number}. Código de salida: ${exit_code}"

    exit "$exit_code"
}

cleanup() {
    local exit_code=$?

    if [[ "$CONTAINER_WAS_RUNNING" == "true" ]]; then
        local current_state

        current_state="$(
            docker inspect \
                --format '{{.State.Running}}' \
                "$CONTAINER_NAME" 2>/dev/null ||
                true
        )"

        if [[ "$current_state" != "true" ]]; then
            log "WARNING" \
                "Vaultwarden estaba activo antes del respaldo y ahora está detenido."

            log "WARNING" \
                "Intentando iniciar Vaultwarden durante la limpieza..."

            if docker start "$CONTAINER_NAME" >/dev/null 2>&1; then
                log "INFO" \
                    "Vaultwarden fue iniciado durante la limpieza."
            else
                log "ERROR" \
                    "No fue posible iniciar Vaultwarden durante la limpieza."
            fi
        fi
    fi

    if [[ "$exit_code" -ne 0 && "$BACKUP_COMPLETED" != "true" ]]; then
        log "ERROR" \
            "El proceso de respaldo no finalizó correctamente."
    fi
}

handle_signal() {
    local signal_name="$1"

    log "WARNING" \
        "Proceso interrumpido por la señal ${signal_name}."

    exit 130
}

trap 'handle_error "$LINENO"' ERR
trap cleanup EXIT
trap 'handle_signal INT' INT
trap 'handle_signal TERM' TERM

# ==============================================================================
# Validación del entorno
# ==============================================================================

validate_environment() {
    log "INFO" \
        "Validando el entorno..."

    local required_commands=(
        awk
        curl
        date
        docker
        du
        find
        grep
        hostname
        realpath
        sha256sum
        sleep
        sort
        tar
        tee
    )

    local command_name

    for command_name in "${required_commands[@]}"; do
        if ! command -v "$command_name" >/dev/null 2>&1; then
            log "ERROR" \
                "Comando requerido no encontrado: ${command_name}"
            return 1
        fi
    done

    if [[ "$EUID" -ne 0 ]]; then
        log "ERROR" \
            "Este script debe ejecutarse como root."
        return 1
    fi

    if [[ ! -d "$DATA_SOURCE" ]]; then
        log "ERROR" \
            "No existe el directorio de datos: ${DATA_SOURCE}"
        return 1
    fi

    if [[ ! -d "$STACK_SOURCE" ]]; then
        log "ERROR" \
            "No existe el directorio del stack: ${STACK_SOURCE}"
        return 1
    fi

    if ! docker info >/dev/null 2>&1; then
        log "ERROR" \
            "Docker no está disponible."
        return 1
    fi

    if ! docker inspect "$CONTAINER_NAME" >/dev/null 2>&1; then
        log "ERROR" \
            "No existe el contenedor Docker: ${CONTAINER_NAME}"
        return 1
    fi

    mkdir -p \
        "$BACKUP_ROOT" \
        "$BACKUP_DIR" \
        "$LOG_DIR"

    if [[ ! -w "$BACKUP_ROOT" ]]; then
        log "ERROR" \
            "No se puede escribir en el directorio: ${BACKUP_ROOT}"
        return 1
    fi

    if [[ ! -w "$LOG_DIR" ]]; then
        log "ERROR" \
            "No se puede escribir en el directorio: ${LOG_DIR}"
        return 1
    fi

    log "INFO" \
        "Entorno validado correctamente."
}

# ==============================================================================
# Estado del contenedor
# ==============================================================================

detect_container_state() {
    local running_state

    running_state="$(
        docker inspect \
            --format '{{.State.Running}}' \
            "$CONTAINER_NAME"
    )"

    if [[ "$running_state" == "true" ]]; then
        CONTAINER_WAS_RUNNING=true

        log "INFO" \
            "Vaultwarden se encuentra activo."
    else
        CONTAINER_WAS_RUNNING=false

        log "WARNING" \
            "Vaultwarden ya estaba detenido antes del respaldo."
    fi
}

stop_container() {
    if [[ "$CONTAINER_WAS_RUNNING" != "true" ]]; then
        log "INFO" \
            "No es necesario detener Vaultwarden."
        return 0
    fi

    log "INFO" \
        "Deteniendo temporalmente Vaultwarden..."

    docker stop \
        --time 30 \
        "$CONTAINER_NAME" >/dev/null

    local running_state

    running_state="$(
        docker inspect \
            --format '{{.State.Running}}' \
            "$CONTAINER_NAME"
    )"

    if [[ "$running_state" == "true" ]]; then
        log "ERROR" \
            "Vaultwarden continúa activo después de docker stop."
        return 1
    fi

    log "INFO" \
        "Vaultwarden detenido correctamente."
}

start_container() {
    if [[ "$CONTAINER_WAS_RUNNING" != "true" ]]; then
        log "INFO" \
            "Vaultwarden estaba detenido antes del respaldo; no se iniciará automáticamente."
        return 0
    fi

    log "INFO" \
        "Iniciando Vaultwarden..."

    docker start "$CONTAINER_NAME" >/dev/null

    log "INFO" \
        "Vaultwarden recibió la orden de inicio."
}

# ==============================================================================
# Creación del respaldo
# ==============================================================================

create_archive() {
    log "INFO" \
        "Creando archivo de respaldo..."

    tar \
        --create \
        --gzip \
        --file "$ARCHIVE_PATH" \
        --directory "$QUESADALAB_ROOT" \
        "data/vaultwarden" \
        "stacks/vaultwarden"

    if [[ ! -s "$ARCHIVE_PATH" ]]; then
        log "ERROR" \
            "El archivo de respaldo está vacío o no fue creado."
        return 1
    fi

    log "INFO" \
        "Archivo generado: ${ARCHIVE_PATH}"
}

generate_checksum() {
    log "INFO" \
        "Calculando checksum SHA-256..."

    (
        cd "$BACKUP_DIR"
        sha256sum "$ARCHIVE_NAME" > "${ARCHIVE_NAME}.sha256"
    )

    if [[ ! -s "$CHECKSUM_PATH" ]]; then
        log "ERROR" \
            "No fue posible generar el checksum."
        return 1
    fi

    log "INFO" \
        "Checksum generado correctamente."
}

verify_archive() {
    log "INFO" \
        "Verificando la integridad del archivo..."

    (
        cd "$BACKUP_DIR"
        sha256sum --check "${ARCHIVE_NAME}.sha256"
    )

    if ! tar \
        --list \
        --gzip \
        --file "$ARCHIVE_PATH" >/dev/null; then

        log "ERROR" \
            "El archivo tar.gz no pudo ser leído."
        return 1
    fi

    local archive_listing

    archive_listing="$(
        tar \
            --list \
            --gzip \
            --file "$ARCHIVE_PATH"
    )"

    if ! grep -qE '^data/vaultwarden(/|$)' <<< "$archive_listing"; then
        log "ERROR" \
            "El archivo no contiene data/vaultwarden."
        return 1
    fi

    if ! grep -qE '^stacks/vaultwarden(/|$)' <<< "$archive_listing"; then
        log "ERROR" \
            "El archivo no contiene stacks/vaultwarden."
        return 1
    fi

    log "INFO" \
        "Integridad del archivo verificada correctamente."
}

create_manifest() {
    log "INFO" \
        "Creando manifest del respaldo..."

    local archive_size
    local docker_image
    local container_id
    local checksum_value

    archive_size="$(
        du -h "$ARCHIVE_PATH" |
        awk '{print $1}'
    )"

    docker_image="$(
        docker inspect \
            --format '{{.Config.Image}}' \
            "$CONTAINER_NAME"
    )"

    container_id="$(
        docker inspect \
            --format '{{.Id}}' \
            "$CONTAINER_NAME"
    )"

    checksum_value="$(
        awk '{print $1}' "$CHECKSUM_PATH"
    )"

    cat > "$MANIFEST_PATH" <<EOF
QuesadaLab Vaultwarden Backup
=============================

Backup information
------------------
Timestamp: ${TIMESTAMP}
Hostname: $(hostname)
Backup directory: ${BACKUP_DIR}
Archive: ${ARCHIVE_NAME}
Archive size: ${archive_size}
SHA-256: ${checksum_value}

Container
---------
Name: ${CONTAINER_NAME}
Image: ${docker_image}
Container ID: ${container_id}
Was running before backup: ${CONTAINER_WAS_RUNNING}

Sources
-------
${DATA_SOURCE}
${STACK_SOURCE}

Archive structure
-----------------
data/vaultwarden/
stacks/vaultwarden/

Retention
---------
Daily backups retained: ${DAILY_RETENTION}
EOF

    chmod 640 "$MANIFEST_PATH"

    log "INFO" \
        "Manifest creado correctamente."
}

# ==============================================================================
# Health check Docker
# ==============================================================================

wait_for_container_health() {
    if [[ "$CONTAINER_WAS_RUNNING" != "true" ]]; then
        return 0
    fi

    log "INFO" \
        "Esperando que Docker marque Vaultwarden como saludable..."

    local attempt
    local container_state
    local health_state

    for ((
        attempt = 1;
        attempt <= CONTAINER_HEALTH_RETRIES;
        attempt++
    )); do
        container_state="$(
            docker inspect \
                --format '{{.State.Status}}' \
                "$CONTAINER_NAME" 2>/dev/null ||
                true
        )"

        health_state="$(
            docker inspect \
                --format '{{if .State.Health}}{{.State.Health.Status}}{{else}}none{{end}}' \
                "$CONTAINER_NAME" 2>/dev/null ||
                true
        )"

        if [[ "$health_state" == "healthy" ]]; then
            log "SUCCESS" \
                "Docker reporta Vaultwarden como healthy."
            return 0
        fi

        if [[ "$health_state" == "unhealthy" ]]; then
            log "WARNING" \
                "Docker reporta temporalmente Vaultwarden como unhealthy."
        fi

        if [[ "$health_state" == "none" &&
              "$container_state" == "running" ]]; then

            log "SUCCESS" \
                "Vaultwarden está running y no tiene healthcheck configurado."
            return 0
        fi

        if [[ "$container_state" == "exited" ||
              "$container_state" == "dead" ]]; then

            log "ERROR" \
                "Vaultwarden terminó inesperadamente. Estado: ${container_state}"
            return 1
        fi

        log "INFO" \
            "Estado Docker: status=${container_state:-desconocido}, health=${health_state:-desconocido}, intento ${attempt}/${CONTAINER_HEALTH_RETRIES}."

        sleep "$CONTAINER_HEALTH_INTERVAL"
    done

    log "ERROR" \
        "Docker no reportó Vaultwarden como saludable después de $((CONTAINER_HEALTH_RETRIES * CONTAINER_HEALTH_INTERVAL)) segundos."

    return 1
}

# ==============================================================================
# Verificación externa mediante Traefik
# ==============================================================================

verify_external_endpoint() {
    if [[ "$CONTAINER_WAS_RUNNING" != "true" ]]; then
        return 0
    fi

    log "INFO" \
        "Verificando disponibilidad externa mediante Traefik..."

    local attempt
    local http_code="000"

    for ((
        attempt = 1;
        attempt <= EXTERNAL_CHECK_RETRIES;
        attempt++
    )); do
        http_code="$(
            curl \
                --silent \
                --output /dev/null \
                --write-out '%{http_code}' \
                --connect-timeout 5 \
                --max-time 10 \
                "$HEALTH_URL" ||
                true
        )"

        if [[ "$http_code" == "200" ]]; then
            log "SUCCESS" \
                "Endpoint ${HEALTH_URL} disponible con HTTP 200."
            return 0
        fi

        log "WARNING" \
            "Verificación externa ${attempt}/${EXTERNAL_CHECK_RETRIES}: HTTP ${http_code:-sin respuesta}."

        if (( attempt < EXTERNAL_CHECK_RETRIES )); then
            sleep "$EXTERNAL_CHECK_INTERVAL"
        fi
    done

    log "WARNING" \
        "Docker reporta Vaultwarden como saludable, pero ${HEALTH_URL} respondió HTTP ${http_code:-sin respuesta}."

    log "WARNING" \
        "La comprobación externa no bloqueará el respaldo."

    return 0
}

# ==============================================================================
# Retención
# ==============================================================================

apply_retention_policy() {
    log "INFO" \
        "Aplicando política de retención: conservar los últimos ${DAILY_RETENTION} respaldos diarios."

    prune_backup_sets \
        "$BACKUP_ROOT" \
        "$DAILY_RETENTION" \
        false
}

# ==============================================================================
# Flujo principal
# ==============================================================================

main() {
    mkdir -p \
        "$LOG_DIR" \
        "$BACKUP_ROOT"

    log "INFO" \
        "============================================================"

    log "INFO" \
        "Iniciando respaldo de Vaultwarden."

    log "INFO" \
        "Timestamp: ${TIMESTAMP}"

    validate_environment
    detect_container_state
    stop_container

    create_archive
    generate_checksum
    verify_archive
    create_manifest

    start_container
    wait_for_container_health
    verify_external_endpoint

    apply_retention_policy

    BACKUP_COMPLETED=true

    log "SUCCESS" \
        "Respaldo completado correctamente."

    log "SUCCESS" \
        "Ubicación: ${BACKUP_DIR}"

    log "INFO" \
        "============================================================"
}

main "$@"

#!/usr/bin/env bash

# ==============================================================================
# QuesadaLab Backup Framework
# Biblioteca reutilizable de retención de respaldos
# ==============================================================================

readonly RETENTION_ALLOWED_ROOT="/opt/quesadalab/backups"

retention_log() {
    local level="$1"
    shift

    if declare -F log >/dev/null 2>&1; then
        log "$level" "$*"
    else
        printf '[%s] [%s] %s\n' \
            "$(date '+%Y-%m-%d %H:%M:%S')" \
            "$level" \
            "$*"
    fi
}

validate_retention_directory() {
    local directory="$1"
    local resolved_directory
    local resolved_root

    if [[ -z "$directory" ]]; then
        retention_log "ERROR" \
            "No se indicó el directorio al que se aplicará la retención."
        return 1
    fi

    if [[ ! -d "$directory" ]]; then
        retention_log "ERROR" \
            "El directorio de respaldos no existe: $directory"
        return 1
    fi

    resolved_directory="$(realpath -m -- "$directory")"
    resolved_root="$(realpath -m -- "$RETENTION_ALLOWED_ROOT")"

    case "$resolved_directory" in
        "$resolved_root"/*)
            ;;
        *)
            retention_log "ERROR" \
                "Directorio rechazado por seguridad: $resolved_directory"
            return 1
            ;;
    esac

    if [[ "$resolved_directory" == "/" ||
          "$resolved_directory" == "$resolved_root" ]]; then
        retention_log "ERROR" \
            "No se permite aplicar retención directamente sobre: $resolved_directory"
        return 1
    fi
}

validate_retention_limit() {
    local keep="$1"

    if [[ ! "$keep" =~ ^[1-9][0-9]*$ ]]; then
        retention_log "ERROR" \
            "El límite de retención debe ser un entero mayor que cero: $keep"
        return 1
    fi
}

prune_backup_sets() {
    local directory="$1"
    local keep="$2"
    local dry_run="${3:-false}"

    local -a backups=()
    local backup_name
    local backup_path
    local index
    local removed=0

    validate_retention_directory "$directory" || return 1
    validate_retention_limit "$keep" || return 1

    if [[ "$dry_run" != "true" && "$dry_run" != "false" ]]; then
        retention_log "ERROR" \
            "El modo dry-run debe ser true o false: $dry_run"
        return 1
    fi

    mapfile -t backups < <(
        find "$directory" \
            -mindepth 1 \
            -maxdepth 1 \
            -type d \
            -printf '%f\n' |
        grep -E \
            '^[0-9]{4}-[0-9]{2}-[0-9]{2}_[0-9]{2}-[0-9]{2}-[0-9]{2}$' |
        sort -r
    )

    retention_log "INFO" \
        "Respaldos válidos encontrados en $directory: ${#backups[@]}"

    retention_log "INFO" \
        "Política aplicada: conservar los últimos $keep respaldos."

    if (( ${#backups[@]} <= keep )); then
        retention_log "INFO" \
            "No hay respaldos antiguos que eliminar."
        return 0
    fi

    for ((index = keep; index < ${#backups[@]}; index++)); do
        backup_name="${backups[$index]}"
        backup_path="${directory}/${backup_name}"

        if [[ "$dry_run" == "true" ]]; then
            retention_log "DRY-RUN" \
                "Se eliminaría: $backup_path"
        else
            retention_log "INFO" \
                "Eliminando respaldo antiguo: $backup_path"

            rm -rf --one-file-system -- "$backup_path"
            ((removed += 1))
        fi
    done

    if [[ "$dry_run" == "true" ]]; then
        retention_log "INFO" \
            "Simulación finalizada; no se eliminó ningún archivo."
    else
        retention_log "SUCCESS" \
            "Retención completada. Respaldos eliminados: $removed"
    fi
}

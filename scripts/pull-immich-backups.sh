#!/usr/bin/env bash

set -Eeuo pipefail
IFS=$'\n\t'

readonly REMOTE_HOST="${IMMICH_BACKUP_HOST:-192.168.1.30}"
readonly REMOTE_USER="${IMMICH_BACKUP_USER:-root}"
readonly SSH_KEY="${IMMICH_BACKUP_KEY:-/root/.ssh/quesadalab-immich-backup}"
readonly MOUNT_ROOT="${IMMICH_USB_MOUNT:-/mnt/quesadalab-backup}"
readonly DESTINATION="${IMMICH_USB_DESTINATION:-${MOUNT_ROOT}/immich}"
readonly RETENTION="${IMMICH_USB_RETENTION:-3}"
readonly LOCK_FILE="/run/lock/quesadalab-immich-usb-pull.lock"
readonly REMOTE_METADATA="/opt/quesadalab/backups/immich"
readonly REMOTE_MEDIA="/srv/immich-data/library"
readonly SSH_COMMAND="ssh -i ${SSH_KEY} -o IdentitiesOnly=yes -o BatchMode=yes -o ConnectTimeout=10"

STAGING_DIR=""

log() { printf '[%s] [%s] %s\n' "$(date '+%Y-%m-%d %H:%M:%S')" "$1" "$2"; }

cleanup() {
    local status=$?
    if [[ -n "$STAGING_DIR" && -d "$STAGING_DIR" ]]; then
        rm -rf --one-file-system -- "$STAGING_DIR"
    fi
    [[ $status -eq 0 ]] || log ERROR "La transferencia termino con codigo ${status}."
}
trap cleanup EXIT
trap 'log ERROR "Fallo en la linea ${LINENO}."' ERR

validate_environment() {
    local command_name mounted_target key_mode
    [[ $EUID -eq 0 ]] || { log ERROR "Debe ejecutarse como root."; return 1; }
    [[ "$RETENTION" =~ ^[1-9][0-9]*$ ]] || return 1

    for command_name in date du find findmnt flock mktemp realpath rsync \
        sha256sum sort ssh stat; do
        command -v "$command_name" >/dev/null 2>&1 || {
            log ERROR "Falta el comando requerido: ${command_name}"
            return 1
        }
    done

    mounted_target="$(findmnt -n -o TARGET --target "$MOUNT_ROOT" 2>/dev/null || true)"
    [[ "$mounted_target" == "$MOUNT_ROOT" ]] || {
        log ERROR "${MOUNT_ROOT} no es un punto de montaje activo."
        return 1
    }
    [[ -f "$SSH_KEY" ]] || { log ERROR "No existe ${SSH_KEY}."; return 1; }
    key_mode="$(stat -c '%a' "$SSH_KEY")"
    [[ "$key_mode" == 600 ]] || { log ERROR "La llave debe tener modo 600."; return 1; }

    mkdir -p "$DESTINATION"
    chmod 0700 "$DESTINATION"
    case "$(realpath -m -- "$DESTINATION")" in
        "$(realpath -m -- "$MOUNT_ROOT")"/*) ;;
        *) log ERROR "Destino rechazado: ${DESTINATION}"; return 1 ;;
    esac
}

latest_remote_set() {
    rsync --archive --list-only -e "$SSH_COMMAND" \
        "${REMOTE_USER}@${REMOTE_HOST}:${REMOTE_METADATA}/" |
        awk '$1 ~ /^d/ && $NF ~ /^[0-9]{4}-[0-9]{2}-[0-9]{2}_[0-9]{2}-[0-9]{2}-[0-9]{2}$/ {print $NF}' |
        sort | tail -n 1
}

pull_set() {
    local set_name="$1" previous="" link_option=()
    local final_dir="${DESTINATION}/${set_name}"
    [[ ! -e "$final_dir" ]] || { log INFO "El conjunto ${set_name} ya existe."; return 0; }

    STAGING_DIR="$(mktemp -d "${DESTINATION}/.incoming.XXXXXX")"
    chmod 0700 "$STAGING_DIR"
    mkdir -p "${STAGING_DIR}/metadata" "${STAGING_DIR}/media"

    log INFO "Copiando metadatos preparados ${set_name}."
    rsync --archive --partial -e "$SSH_COMMAND" \
        "${REMOTE_USER}@${REMOTE_HOST}:${REMOTE_METADATA}/${set_name}/" \
        "${STAGING_DIR}/metadata/"
    (cd "${STAGING_DIR}/metadata" && sha256sum --check SHA256SUMS)

    previous="$(find "$DESTINATION" -mindepth 1 -maxdepth 1 -type d \
        -name '????-??-??_??-??-??' -printf '%f\n' | sort | tail -n 1)"
    if [[ -n "$previous" && -d "${DESTINATION}/${previous}/media" ]]; then
        link_option=(--link-dest="${DESTINATION}/${previous}/media")
    fi

    log INFO "Copiando biblioteca con snapshot incremental."
    rsync --archive --delete --numeric-ids --partial \
        --chmod=Du=rwx,Dgo=,Fu=rw,Fgo= "${link_option[@]}" \
        -e "$SSH_COMMAND" \
        "${REMOTE_USER}@${REMOTE_HOST}:${REMOTE_MEDIA}/" \
        "${STAGING_DIR}/media/"

    {
        printf 'USB snapshot: %s\n' "$set_name"
        printf 'Completed: %s\n' "$(date --iso-8601=seconds)"
        du -sh "${STAGING_DIR}/metadata" "${STAGING_DIR}/media"
    } > "${STAGING_DIR}/USB-MANIFEST.txt"
    chmod -R go-rwx "$STAGING_DIR"
    mv -- "$STAGING_DIR" "$final_dir"
    STAGING_DIR=""
    log SUCCESS "Snapshot aceptado: ${final_dir}"
}

apply_retention() {
    local -a sets=()
    local index
    mapfile -d '' -t sets < <(
        find "$DESTINATION" -mindepth 1 -maxdepth 1 -type d \
            -name '????-??-??_??-??-??' -printf '%p\0' | sort -z -r
    )
    for ((index = RETENTION; index < ${#sets[@]}; index++)); do
        log INFO "Eliminando snapshot fuera de retencion: ${sets[$index]}"
        rm -rf --one-file-system -- "${sets[$index]}"
    done
    log SUCCESS "Snapshots USB validos conservados: $((${#sets[@]} < RETENTION ? ${#sets[@]} : RETENTION))."
}

main() {
    local set_name
    exec 9>"$LOCK_FILE"
    flock -n 9 || { log ERROR "Ya existe otra transferencia en ejecucion."; exit 1; }
    validate_environment
    set_name="$(latest_remote_set)"
    [[ -n "$set_name" ]] || { log ERROR "No hay preparaciones remotas."; exit 1; }
    pull_set "$set_name"
    apply_retention
}

main "$@"

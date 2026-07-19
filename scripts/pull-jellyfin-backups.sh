#!/usr/bin/env bash

set -Eeuo pipefail
IFS=$'\n\t'

readonly REMOTE_HOST="${JELLYFIN_BACKUP_HOST:-192.168.1.30}"
readonly REMOTE_USER="${JELLYFIN_BACKUP_USER:-root}"
readonly SSH_KEY="${JELLYFIN_BACKUP_KEY:-/root/.ssh/quesadalab-jellyfin-backup}"
readonly MOUNT_ROOT="${JELLYFIN_USB_MOUNT:-/mnt/quesadalab-backup}"
readonly DESTINATION="${JELLYFIN_USB_DESTINATION:-${MOUNT_ROOT}/jellyfin}"
readonly RETENTION="${JELLYFIN_USB_RETENTION:-7}"
readonly LOCK_FILE="/run/lock/quesadalab-jellyfin-usb-pull.lock"

STAGING_DIR=""

log() { printf '[%s] [%s] %s\n' "$(date '+%Y-%m-%d %H:%M:%S')" "$1" "$2"; }

cleanup() {
    local status=$?
    [[ -z "$STAGING_DIR" || ! -d "$STAGING_DIR" ]] || rm -rf --one-file-system -- "$STAGING_DIR"
    [[ $status -eq 0 ]] || log ERROR "La transferencia termino con codigo ${status}."
}
trap cleanup EXIT
trap 'log ERROR "Fallo en la linea ${LINENO}."' ERR

validate_environment() {
    local command_name mounted_target
    [[ $EUID -eq 0 && "$RETENTION" =~ ^[1-9][0-9]*$ ]] || return 1
    for command_name in find findmnt flock mktemp realpath rsync sha256sum ssh tar; do
        command -v "$command_name" >/dev/null 2>&1 || return 1
    done
    mounted_target="$(findmnt -n -o TARGET --target "$MOUNT_ROOT" 2>/dev/null || true)"
    [[ "$mounted_target" == "$MOUNT_ROOT" ]] || { log ERROR "USB no montado en ${MOUNT_ROOT}."; return 1; }
    [[ -f "$SSH_KEY" && "$(stat -c '%a' "$SSH_KEY")" == 600 ]] || {
        log ERROR "Llave SSH ausente o con permisos incorrectos: ${SSH_KEY}"
        return 1
    }
    mkdir -p "$DESTINATION"
    chmod 0700 "$DESTINATION"
    case "$(realpath -m -- "$DESTINATION")" in
        "$(realpath -m -- "$MOUNT_ROOT")"/*) ;;
        *) log ERROR "Destino rechazado: ${DESTINATION}"; return 1 ;;
    esac
}

validate_set() {
    local set_dir="$1" required
    for required in configuration.tar.gz manifest.txt SHA256SUMS; do
        [[ -s "${set_dir}/${required}" ]] || return 1
    done
    (cd "$set_dir" && sha256sum --check SHA256SUMS)
    tar -tzf "${set_dir}/configuration.tar.gz" >/dev/null
}

pull_sets() {
    local set_dir set_name final_dir
    STAGING_DIR="$(mktemp -d "${DESTINATION}/.incoming.XXXXXX")"
    chmod 0700 "$STAGING_DIR"
    log INFO "Copiando respaldos Jellyfin desde ${REMOTE_HOST}."
    rsync --archive --partial \
        -e "ssh -i ${SSH_KEY} -o IdentitiesOnly=yes -o BatchMode=yes -o ConnectTimeout=10" \
        "${REMOTE_USER}@${REMOTE_HOST}:" "${STAGING_DIR}/"
    while IFS= read -r -d '' set_dir; do
        set_name="$(basename -- "$set_dir")"
        final_dir="${DESTINATION}/${set_name}"
        validate_set "$set_dir"
        if [[ -e "$final_dir" ]]; then
            log INFO "El respaldo ya existe: ${set_name}."
        else
            mv -- "$set_dir" "$final_dir"
            chmod 0700 "$final_dir"
            log SUCCESS "Respaldo aceptado en USB: ${final_dir}"
        fi
    done < <(find "$STAGING_DIR" -mindepth 1 -maxdepth 1 -type d \
        -name '????-??-??_??-??-??' -print0 | sort -z)
}

apply_retention() {
    local -a sets=()
    local index
    mapfile -d '' -t sets < <(find "$DESTINATION" -mindepth 1 -maxdepth 1 -type d \
        -name '????-??-??_??-??-??' -printf '%p\0' | sort -z -r)
    for ((index = RETENTION; index < ${#sets[@]}; index++)); do
        log INFO "Eliminando respaldo USB fuera de retencion: ${sets[$index]}"
        rm -rf --one-file-system -- "${sets[$index]}"
    done
    log SUCCESS "Respaldos Jellyfin conservados en USB: $((${#sets[@]} < RETENTION ? ${#sets[@]} : RETENTION))."
}

main() {
    exec 9>"$LOCK_FILE"
    flock -n 9 || { log ERROR "Ya existe otra transferencia en ejecucion."; exit 1; }
    validate_environment
    pull_sets
    apply_retention
}
main "$@"

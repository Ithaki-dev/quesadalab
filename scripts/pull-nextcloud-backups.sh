#!/usr/bin/env bash

set -Eeuo pipefail
IFS=$'\n\t'

readonly REMOTE_HOST="${NEXTCLOUD_BACKUP_HOST:-192.168.1.30}"
readonly REMOTE_USER="${NEXTCLOUD_BACKUP_USER:-root}"
readonly SSH_KEY="${NEXTCLOUD_BACKUP_KEY:-/root/.ssh/quesadalab-nextcloud-backup}"
readonly MOUNT_ROOT="${NEXTCLOUD_USB_MOUNT:-/mnt/quesadalab-backup}"
readonly DESTINATION="${NEXTCLOUD_USB_DESTINATION:-${MOUNT_ROOT}/nextcloud}"
readonly RETENTION="${NEXTCLOUD_USB_RETENTION:-7}"
readonly LOCK_FILE="/run/lock/quesadalab-nextcloud-usb-pull.lock"

STAGING_DIR=""

log() {
    printf '[%s] [%s] %s\n' "$(date '+%Y-%m-%d %H:%M:%S')" "$1" "$2"
}

cleanup() {
    local status=$?

    if [[ -n "$STAGING_DIR" && -d "$STAGING_DIR" ]]; then
        rm -rf --one-file-system -- "$STAGING_DIR"
    fi

    [[ $status -eq 0 ]] || log ERROR "La transferencia terminó con código ${status}."
}

trap cleanup EXIT
trap 'log ERROR "Fallo en la línea ${LINENO}."' ERR

validate_environment() {
    local command_name mounted_target key_mode

    [[ $EUID -eq 0 ]] || { log ERROR "Debe ejecutarse como root."; return 1; }
    [[ "$RETENTION" =~ ^[1-9][0-9]*$ ]] || {
        log ERROR "La retención debe ser un entero mayor que cero."
        return 1
    }

    for command_name in find findmnt flock mktemp realpath rsync sha256sum ssh; do
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

    [[ -f "$SSH_KEY" ]] || { log ERROR "No existe la llave ${SSH_KEY}."; return 1; }
    key_mode="$(stat -c '%a' "$SSH_KEY")"
    [[ "$key_mode" == 600 ]] || {
        log ERROR "La llave debe tener modo 600; modo actual: ${key_mode}."
        return 1
    }

    mkdir -p "$DESTINATION"
    chmod 0700 "$DESTINATION"

    case "$(realpath -m -- "$DESTINATION")" in
        "$(realpath -m -- "$MOUNT_ROOT")"/*) ;;
        *) log ERROR "Destino rechazado por seguridad: ${DESTINATION}"; return 1 ;;
    esac
}

pull_to_staging() {
    STAGING_DIR="$(mktemp -d "${DESTINATION}/.incoming.XXXXXX")"
    chmod 0700 "$STAGING_DIR"

    log INFO "Copiando conjuntos disponibles desde ${REMOTE_HOST}."
    rsync --archive --partial \
        -e "ssh -i ${SSH_KEY} -o IdentitiesOnly=yes -o BatchMode=yes -o ConnectTimeout=10" \
        "${REMOTE_USER}@${REMOTE_HOST}:" \
        "${STAGING_DIR}/"
}

validate_set() {
    local backup_dir="$1" required

    for required in database.dump application.tar.gz user-data.tar.gz SHA256SUMS manifest.txt; do
        [[ -s "${backup_dir}/${required}" ]] || {
            log ERROR "Conjunto incompleto: falta ${backup_dir}/${required}."
            return 1
        }
    done

    (cd "$backup_dir" && sha256sum --check SHA256SUMS)
}

promote_sets() {
    local backup_dir backup_name final_dir promoted=0

    while IFS= read -r -d '' backup_dir; do
        backup_name="$(basename -- "$backup_dir")"
        final_dir="${DESTINATION}/${backup_name}"

        validate_set "$backup_dir"

        if [[ -e "$final_dir" ]]; then
            log INFO "El conjunto ya existe y fue verificado: ${backup_name}."
            continue
        fi

        mv -- "$backup_dir" "$final_dir"
        chmod 0700 "$final_dir"
        log SUCCESS "Conjunto aceptado en USB: ${final_dir}"
        ((promoted += 1))
    done < <(
        find "$STAGING_DIR" -mindepth 1 -maxdepth 1 -type d \
            -name '????-??-??_??-??-??' -print0 | sort -z
    )

    if (( promoted == 0 )); then
        log INFO "No se encontraron conjuntos nuevos para promover."
    fi
}

apply_retention() {
    local -a backups=()
    local index backup_path kept_count

    mapfile -d '' -t backups < <(
        find "$DESTINATION" -mindepth 1 -maxdepth 1 -type d \
            -name '????-??-??_??-??-??' -printf '%f\0' |
        sort -z -r
    )

    for ((index = RETENTION; index < ${#backups[@]}; index++)); do
        backup_path="${DESTINATION}/${backups[$index]}"
        log INFO "Eliminando conjunto USB fuera de retención: ${backup_path}"
        rm -rf --one-file-system -- "$backup_path"
    done

    kept_count="${#backups[@]}"

    if (( kept_count > RETENTION )); then
        kept_count="$RETENTION"
    fi

    log SUCCESS "Conjuntos válidos conservados en USB: ${kept_count}."
}

main() {
    exec 9>"$LOCK_FILE"
    flock -n 9 || { log ERROR "Ya existe otra transferencia en ejecución."; exit 1; }

    validate_environment
    pull_to_staging
    promote_sets
    apply_retention
}

main "$@"

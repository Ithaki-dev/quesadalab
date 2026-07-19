#!/usr/bin/env bash

set -Eeuo pipefail
IFS=$'\n\t'

readonly ROOT="/opt/quesadalab"
readonly STACK_DIR="${ROOT}/stacks/jellyfin"
readonly CONFIG_DIR="${ROOT}/data/jellyfin/config"
readonly CONTAINER="jellyfin"

validate_backup() {
    local set_dir="$1" entry
    for entry in configuration.tar.gz manifest.txt SHA256SUMS; do
        [[ -s "${set_dir}/${entry}" ]] || { echo "Falta ${entry}." >&2; return 1; }
    done
    (cd "$set_dir" && sha256sum --check SHA256SUMS)
    ! tar -tzf "${set_dir}/configuration.tar.gz" | grep -Eq '(^/|(^|/)\.\.(/|$))'
    tar -tzf "${set_dir}/configuration.tar.gz" |
        grep -Fxq 'opt/quesadalab/data/jellyfin/config/data/jellyfin.db'
    tar -tzf "${set_dir}/configuration.tar.gz" |
        grep -Fxq 'opt/quesadalab/stacks/jellyfin/.env'
}

main() {
    local set_dir="${1:-}" answer work_dir rollback_root timestamp attempt
    [[ $EUID -eq 0 ]] || { echo "Debe ejecutarse como root." >&2; exit 1; }
    [[ -n "$set_dir" ]] || { echo "Uso: $0 /ruta/al/respaldo"; exit 1; }
    for command_name in docker mktemp rsync sha256sum tar; do
        command -v "$command_name" >/dev/null 2>&1 || { echo "Falta ${command_name}." >&2; exit 1; }
    done
    validate_backup "$set_dir"
    printf 'Se reemplazaran la configuracion, usuarios y base de datos de Jellyfin.\n'
    printf 'Los archivos multimedia bajo /srv/jellyfin-media no se modificaran.\n'
    read -r -p 'Escriba RESTORE-JELLYFIN para continuar: ' answer
    [[ "$answer" == RESTORE-JELLYFIN ]] || { echo "Operacion cancelada."; exit 0; }

    work_dir="$(mktemp -d /tmp/jellyfin-restore.XXXXXX)"
    trap 'rm -rf -- "$work_dir"' EXIT
    tar -xzf "${set_dir}/configuration.tar.gz" -C "$work_dir"
    timestamp="$(date '+%Y-%m-%d_%H-%M-%S')"
    rollback_root="${ROOT}/backups/jellyfin-restore-rollback/${timestamp}"
    install -d -o root -g root -m 0700 "$rollback_root"

    docker stop --time 60 "$CONTAINER" >/dev/null
    rsync -a "$CONFIG_DIR/" "${rollback_root}/config/"
    rsync -a "$STACK_DIR/" "${rollback_root}/stack/"
    rsync -a --delete "${work_dir}/opt/quesadalab/data/jellyfin/config/" "$CONFIG_DIR/"
    rsync -a --delete "${work_dir}/opt/quesadalab/stacks/jellyfin/" "$STACK_DIR/"
    chown -R 1000:1000 "$CONFIG_DIR"
    chown -R root:root "$STACK_DIR"
    chmod 0600 "${STACK_DIR}/.env"
    docker start "$CONTAINER" >/dev/null
    for attempt in {1..60}; do
        [[ "$(docker inspect -f '{{if .State.Health}}{{.State.Health.Status}}{{end}}' "$CONTAINER")" == healthy ]] && {
            printf 'Restauracion completada. Rollback: %s\n' "$rollback_root"
            exit 0
        }
        sleep 2
    done
    echo "Jellyfin no alcanzo estado healthy; use el rollback ${rollback_root}." >&2
    exit 1
}
main "$@"

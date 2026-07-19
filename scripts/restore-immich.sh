#!/usr/bin/env bash

set -Eeuo pipefail
IFS=$'\n\t'

readonly ROOT="/opt/quesadalab"
readonly STACK_DIR="${ROOT}/stacks/immich"
readonly ENV_FILE="${STACK_DIR}/.env"
readonly COMPOSE_FILE="${STACK_DIR}/docker-compose.yml"
readonly MEDIA_DIR="/srv/immich-data/library"
readonly DB_DIR="${ROOT}/data/immich/postgres"

compose() {
    docker compose --env-file "$ENV_FILE" --project-directory "$STACK_DIR" \
        -f "$COMPOSE_FILE" "$@"
}

validate_environment() {
    local command_name
    for command_name in docker findmnt gzip install mktemp mv rsync sed sha256sum tar; do
        command -v "$command_name" >/dev/null 2>&1 || {
            echo "Falta el comando requerido: ${command_name}" >&2
            return 1
        }
    done
    findmnt -rn --target /srv/immich-data >/dev/null || {
        echo "/srv/immich-data no esta montado." >&2
        return 1
    }
    [[ -f "$ENV_FILE" && -f "$COMPOSE_FILE" && -d "$DB_DIR" ]] || return 1
}

validate_backup() {
    local set_dir="$1" required
    [[ $EUID -eq 0 ]] || { echo "Debe ejecutarse como root." >&2; return 1; }
    [[ -d "${set_dir}/metadata" && -d "${set_dir}/media" ]] || return 1
    for required in database.sql.gz configuration.tar.gz manifest.txt SHA256SUMS; do
        [[ -s "${set_dir}/metadata/${required}" ]] || return 1
    done
    (cd "${set_dir}/metadata" && sha256sum --check SHA256SUMS)
    gzip -t "${set_dir}/metadata/database.sql.gz"
    tar -tzf "${set_dir}/metadata/configuration.tar.gz" |
        grep -Eq '(^/|(^|/)\.\.(/|$))' && {
            echo "El archivo de configuracion contiene rutas inseguras." >&2
            return 1
        }
    tar -tzf "${set_dir}/metadata/configuration.tar.gz" |
        grep -Fxq 'opt/quesadalab/stacks/immich/.env'
}

main() {
    local set_dir="${1:-}" answer work_dir rollback_dir timestamp
    [[ -n "$set_dir" ]] || { echo "Uso: $0 /ruta/al/snapshot"; exit 1; }
    validate_environment
    validate_backup "$set_dir"
    printf 'Se reemplazaran la base, configuracion y biblioteca de Immich.\n'
    read -r -p 'Escriba RESTORE-IMMICH para continuar: ' answer
    [[ "$answer" == RESTORE-IMMICH ]] || { echo "Operacion cancelada."; exit 0; }

    work_dir="$(mktemp -d /tmp/immich-restore.XXXXXX)"
    trap 'rm -rf -- "$work_dir"' EXIT
    tar -xzf "${set_dir}/metadata/configuration.tar.gz" -C "$work_dir"

    timestamp="$(date '+%Y-%m-%d_%H-%M-%S')"
    rollback_dir="${DB_DIR}.before-restore-${timestamp}"
    [[ ! -e "$rollback_dir" ]] || { echo "Ya existe ${rollback_dir}." >&2; exit 1; }

    compose down
    rsync -a --delete "${set_dir}/media/" "$MEDIA_DIR/"
    rsync -a --delete "${work_dir}/opt/quesadalab/stacks/immich/" "$STACK_DIR/"
    rsync -a --delete "${work_dir}/opt/quesadalab/security/immich/" \
        "${ROOT}/security/immich/"

    mv -- "$DB_DIR" "$rollback_dir"
    install -d -o root -g root -m 0700 "$DB_DIR"

    compose create
    docker start immich-postgres
    for _ in {1..30}; do
        [[ "$(docker inspect -f '{{if .State.Health}}{{.State.Health.Status}}{{end}}' immich-postgres)" == healthy ]] && break
        sleep 2
    done
    gzip -dc "${set_dir}/metadata/database.sql.gz" |
        sed "s/SELECT pg_catalog.set_config('search_path', '', false);/SELECT pg_catalog.set_config('search_path', 'public, pg_catalog', true);/g" |
        docker exec -i immich-postgres psql --dbname=immich --username=immich \
            --single-transaction --set ON_ERROR_STOP=on
    compose up -d
    printf 'Restauracion completada. Base anterior conservada en: %s\n' "$rollback_dir"
    echo "Valide API, login, assets y trabajos antes de eliminar el rollback."
}

main "$@"

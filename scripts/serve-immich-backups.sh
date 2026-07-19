#!/usr/bin/env bash

set -Eeuo pipefail

readonly METADATA_ROOT="/opt/quesadalab/backups/immich"
readonly MEDIA_ROOT="/srv/immich-data/library"
readonly ORIGINAL_COMMAND="${SSH_ORIGINAL_COMMAND:-}"

deny() {
    printf 'Immich backup access denied.\n' >&2
    exit 1
}

[[ -n "$ORIGINAL_COMMAND" ]] || deny

[[ "$ORIGINAL_COMMAND" != *$'\n'* && "$ORIGINAL_COMMAND" != *$'\r'* ]] || deny
[[ "$ORIGINAL_COMMAND" == rsync\ --server\ --sender\ * ]] || deny

remote_path="${ORIGINAL_COMMAND##* }"
case "$remote_path" in
    "${METADATA_ROOT}"|"${METADATA_ROOT}/"|"${METADATA_ROOT}/"????-??-??_??-??-??|"${METADATA_ROOT}/"????-??-??_??-??-??/) ;;
    "${MEDIA_ROOT}"|"${MEDIA_ROOT}/") ;;
    *) deny ;;
esac

command_without_path="${ORIGINAL_COMMAND% "${remote_path}"}"
[[ "$command_without_path" != *"${METADATA_ROOT}"* &&
   "$command_without_path" != *"${MEDIA_ROOT}"* ]] || deny

exec /usr/bin/rrsync -ro /

#!/usr/bin/env bash

set -Eeuo pipefail
IFS=$'\n\t'

readonly IMAGE_REPOSITORY="docker.io/diegosouzapw/omniroute"
readonly IMAGE_VERSION="3.8.48"
readonly IMAGE_DIGEST="sha256:badb560971fdc23c2fb84b3e8695116239ff215b4cca4b07076201a8efae7f0d"
readonly IMAGE_REFERENCE="${IMAGE_REPOSITORY}@${IMAGE_DIGEST}"
readonly EXPECTED_SOURCE="https://github.com/diegosouzapw/OmniRoute"

if [[ "$(hostname)" != "docker01" ]]; then
    echo "[ERROR] Run this script inside docker01"
    exit 1
fi

if [[ "$(id -u)" -ne 0 ]]; then
    echo "[ERROR] Run this script as root"
    exit 1
fi

for command_name in docker grep; do
    if ! command -v "$command_name" >/dev/null 2>&1; then
        echo "[ERROR] Missing required command: $command_name"
        exit 1
    fi
done

echo "=== OMNIROUTE IMAGE PREPARATION ==="
echo "version=$IMAGE_VERSION"
echo "image=$IMAGE_REFERENCE"

echo "=== PULL IMMUTABLE IMAGE ==="

docker pull "$IMAGE_REFERENCE"

echo "=== IMAGE VALIDATION ==="

image_user="$(
    docker image inspect "$IMAGE_REFERENCE" \
        --format '{{.Config.User}}'
)"
image_architecture="$(
    docker image inspect "$IMAGE_REFERENCE" \
        --format '{{.Architecture}}'
)"
image_os="$(
    docker image inspect "$IMAGE_REFERENCE" \
        --format '{{.Os}}'
)"
image_source="$(
    docker image inspect "$IMAGE_REFERENCE" \
        --format '{{index .Config.Labels "org.opencontainers.image.source"}}'
)"
repo_digests="$(
    docker image inspect "$IMAGE_REFERENCE" \
        --format '{{range .RepoDigests}}{{println .}}{{end}}'
)"

docker image inspect "$IMAGE_REFERENCE" \
    --format 'id={{.Id}} size={{.Size}} user={{.Config.User}} architecture={{.Architecture}} os={{.Os}}'

printf '%s\n' "$repo_digests"

if ! grep -Fxq \
    "diegosouzapw/omniroute@${IMAGE_DIGEST}" \
    <<<"$repo_digests"; then
    echo "[ERROR] Pulled image does not expose the reviewed repository digest"
    exit 1
fi

if [[ "$image_user" != "node" ]]; then
    echo "[ERROR] OmniRoute image does not use the expected non-root user"
    exit 1
fi

if [[ "$image_architecture" != "amd64" || "$image_os" != "linux" ]]; then
    echo "[ERROR] OmniRoute image has an unexpected platform"
    exit 1
fi

if [[ "$image_source" != "$EXPECTED_SOURCE" ]]; then
    echo "[ERROR] OmniRoute image has an unexpected source label"
    exit 1
fi

echo "[OK] Pinned official OmniRoute image is ready"

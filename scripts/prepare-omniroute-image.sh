#!/usr/bin/env bash

set -Eeuo pipefail
IFS=$'\n\t'

readonly UPSTREAM_REPOSITORY="https://github.com/diegosouzapw/OmniRoute.git"
readonly UPSTREAM_TAG="v3.8.48"
readonly UPSTREAM_COMMIT="4f00f84b5a12f90fca2f1d72a60404cf6f5bf059"
readonly IMAGE_NAME="quesadalab/omniroute:${UPSTREAM_TAG}"
readonly BUILD_ROOT="/opt/quesadalab/tmp"

build_dir=""

cleanup() {
    if [[ -n "$build_dir" && -d "$build_dir" ]]; then
        case "$build_dir" in
            "${BUILD_ROOT}"/omniroute-build.*)
                rm -rf -- "$build_dir"
                ;;
            *)
                printf '[WARNING] Refusing cleanup outside %s: %s\n' \
                    "$BUILD_ROOT" "$build_dir" >&2
                ;;
        esac
    fi
}

trap cleanup EXIT
trap 'exit 130' INT TERM

if [[ "$(hostname)" != "docker01" ]]; then
    echo "[ERROR] Run this script inside docker01"
    exit 1
fi

if [[ "$(id -u)" -ne 0 ]]; then
    echo "[ERROR] Run this script as root"
    exit 1
fi

for command_name in docker git install mktemp; do
    if ! command -v "$command_name" >/dev/null 2>&1; then
        echo "[ERROR] Missing required command: $command_name"
        exit 1
    fi
done

echo "=== OMNIROUTE IMAGE PREPARATION ==="
echo "upstream-tag=$UPSTREAM_TAG"
echo "expected-commit=$UPSTREAM_COMMIT"
echo "image=$IMAGE_NAME"

if docker image inspect "$IMAGE_NAME" >/dev/null 2>&1; then
    existing_commit="$(
        docker image inspect "$IMAGE_NAME" \
            --format '{{index .Config.Labels "org.opencontainers.image.revision"}}'
    )"

    if [[ "$existing_commit" == "$UPSTREAM_COMMIT" ]]; then
        echo "[OK] Verified image already exists"
        exit 0
    fi

    echo "[ERROR] Image tag exists with an unexpected source revision"
    echo "actual-commit=${existing_commit:-missing}"
    exit 1
fi

install -d -o root -g root -m 0750 "$BUILD_ROOT"
build_dir="$(mktemp -d "${BUILD_ROOT}/omniroute-build.XXXXXX")"

echo "=== FETCH PINNED SOURCE ==="

git clone \
    --branch "$UPSTREAM_TAG" \
    --depth 1 \
    "$UPSTREAM_REPOSITORY" \
    "$build_dir/source"

actual_commit="$(git -C "$build_dir/source" rev-parse HEAD)"
echo "actual-commit=$actual_commit"

if [[ "$actual_commit" != "$UPSTREAM_COMMIT" ]]; then
    echo "[ERROR] Upstream tag does not match the reviewed commit"
    exit 1
fi

echo "=== BUILD RUNNER-BASE IMAGE ==="

docker build \
    --target runner-base \
    --label "org.opencontainers.image.source=$UPSTREAM_REPOSITORY" \
    --label "org.opencontainers.image.version=$UPSTREAM_TAG" \
    --label "org.opencontainers.image.revision=$UPSTREAM_COMMIT" \
    --tag "$IMAGE_NAME" \
    "$build_dir/source"

echo "=== IMAGE VALIDATION ==="

docker image inspect "$IMAGE_NAME" \
    --format 'id={{.Id}} user={{.Config.User}} size={{.Size}} revision={{index .Config.Labels "org.opencontainers.image.revision"}}'

image_user="$(
    docker image inspect "$IMAGE_NAME" \
        --format '{{.Config.User}}'
)"

if [[ "$image_user" != "node" && "$image_user" != "1000" ]]; then
    echo "[ERROR] OmniRoute image does not use the expected non-root user"
    exit 1
fi

echo "[OK] Pinned OmniRoute runner-base image is ready"

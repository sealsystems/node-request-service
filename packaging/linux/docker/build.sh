#!/bin/bash -e

if [ -z "${CI_TOKEN}" ]; then
  echo "Error: Environment variable CI_TOKEN must be set."
  exit 1
fi
if [ -z "${NODE_AUTH_TOKEN}" ]; then
  echo "Error: Environment variable NODE_AUTH_TOKEN must be set."
  exit 1
fi
if [ -z "${DELIVERY_CREDENTIALS}" ] && grep -q "DELIVERY_CREDENTIALS" Dockerfile; then
  echo "Error: Environment variable DELIVERY_CREDENTIALS must be set."
fi

echo "Log in to container registry..."

echo "${CI_TOKEN}" | docker login https://ghcr.io -u comgit --password-stdin

echo "Building container images..."

export NAME=$(jq -r .name < package.json)
export VERSION="$(jq -r .version < package.json)"

export label_authors="$(jq -r .author < package.json)"
export label_created="$(date -u +"%Y-%m-%dT%H:%M:%SZ")"
export label_description="$(jq -r .description < package.json)"
export label_documentation="https://sos.sealsystems.de"
export label_licenses="$(jq -r .license < package.json)"
export label_ref_name=""
export label_revision="${COMMIT_SHA}"
export label_source="$(jq -r .repository.url < package.json)"
export label_title="${NAME}"
export label_url="https://ghcr.io/sealsystems/${NAME}"
export label_vendor="$(jq -r .author.name < package.json)"
export label_version="${VERSION}.${BUILD_NUMBER}"

echo "Building image for AMD64..."

docker build \
  -f Dockerfile \
  -t "ghcr.io/sealsystems/${NAME}:linux-amd64-${VERSION}" \
  --build-arg "NODE_AUTH_TOKEN" \
  --build-arg "DELIVERY_CREDENTIALS" \
  --build-arg "label_authors" \
  --build-arg "label_created" \
  --build-arg "label_description" \
  --build-arg "label_documentation" \
  --build-arg "label_licenses" \
  --build-arg "label_ref_name" \
  --build-arg "label_revision" \
  --build-arg "label_source" \
  --build-arg "label_title" \
  --build-arg "label_url" \
  --build-arg "label_vendor" \
  --build-arg "label_version" \
  .

docker tag \
  "ghcr.io/sealsystems/${NAME}:linux-amd64-${VERSION}" \
  "ghcr.io/sealsystems/${NAME}:linux-amd64-${VERSION}.${BUILD_NUMBER}"

# if [ -e Dockerfile.arm ]; then
#   echo "Building image for ARM..."
#
#   docker run \
#     --rm \
#     --privileged \
#     multiarch/qemu-user-static:register –-reset
#
#   docker create \
#     --name register \
#     hypriot/qemu-register
#
#   docker cp register:qemu-arm qemu-arm-static
#
#   docker build \
#     -f Dockerfile.arm \
#     -t "ghcr.io/sealsystems/${NAME}:linux-arm-${VERSION}" \
#     --build-arg "NODE_AUTH_TOKEN" \
#     --build-arg "DELIVERY_CREDENTIALS" \
#     --build-arg "label_authors" \
#     --build-arg "label_created" \
#     --build-arg "label_description" \
#     --build-arg "label_documentation" \
#     --build-arg "label_licenses" \
#     --build-arg "label_ref_name" \
#     --build-arg "label_revision" \
#     --build-arg "label_source" \
#     --build-arg "label_title" \
#     --build-arg "label_url" \
#     --build-arg "label_vendor" \
#     --build-arg "label_version" \
#     .
#
#   docker tag \
#     "ghcr.io/sealsystems/${NAME}:linux-arm-${VERSION}" \
#     "ghcr.io/sealsystems/${NAME}:linux-arm-${VERSION}.${BUILD_NUMBER}"
# fi
#
# if [ -e Dockerfile.arm64 ]; then
#   echo "Building image for ARM64..."
#
#   docker run \
#     --rm \
#     --privileged \
#     multiarch/qemu-user-static:register –-reset
#
#    docker create \
#     --name register1 \
#     hypriot/qemu-register
#
#    docker cp register1:qemu-aarch64 qemu-aarch64-static
#
#   docker build \
#     -f Dockerfile.arm64 \
#     -t "ghcr.io/sealsystems/${NAME}:linux-arm64-${VERSION}" \
#     --build-arg "NODE_AUTH_TOKEN" \
#     --build-arg "DELIVERY_CREDENTIALS" \
#     --build-arg "label_authors" \
#     --build-arg "label_created" \
#     --build-arg "label_description" \
#     --build-arg "label_documentation" \
#     --build-arg "label_licenses" \
#     --build-arg "label_ref_name" \
#     --build-arg "label_revision" \
#     --build-arg "label_source" \
#     --build-arg "label_title" \
#     --build-arg "label_url" \
#     --build-arg "label_vendor" \
#     --build-arg "label_version" \
#     .
#
#   docker tag \
#     "ghcr.io/sealsystems/${NAME}:linux-arm64-${VERSION}" \
#     "ghcr.io/sealsystems/${NAME}:linux-arm64-${VERSION}.${BUILD_NUMBER}"
# fi

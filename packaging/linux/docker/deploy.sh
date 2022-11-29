#!/bin/bash -e

if [ -z "${CI_TOKEN}" ]; then
  echo "Environment variable CI_TOKEN must be set."
  exit 1
fi

NAME=$(jq -r .name < package.json)
VERSION=$(jq -r .version < package.json)

echo "Log in to container registry..."

echo "${CI_TOKEN}" | docker login https://ghcr.io -u comgit --password-stdin

echo "Pushing Linux images..."

# Workaround while manifest tool is not working
docker tag  "ghcr.io/sealsystems/${NAME}:linux-amd64-${VERSION}" "ghcr.io/sealsystems/${NAME}"
docker tag  "ghcr.io/sealsystems/${NAME}:linux-amd64-${VERSION}" "ghcr.io/sealsystems/${NAME}:${VERSION}"
docker tag  "ghcr.io/sealsystems/${NAME}:linux-amd64-${VERSION}" "ghcr.io/sealsystems/${NAME}:${VERSION}.${BUILD_NUMBER}"
docker push "ghcr.io/sealsystems/${NAME}"
docker push "ghcr.io/sealsystems/${NAME}:${VERSION}"
docker push "ghcr.io/sealsystems/${NAME}:${VERSION}.${BUILD_NUMBER}"

# TODO: Reactivate if manifest tool is working correctly again!
#
# PLATFORMS=linux/amd64
# docker push "${NAME}:linux-amd64-${VERSION}"
# docker push "${NAME}:linux-amd64-${VERSION}.${BUILD_NUMBER}"
#
# # if [ -e Dockerfile.windows ]; then
# #   PLATFORMS=${PLATFORMS},windows/amd64
# # fi
#
# # if [ -e Dockerfile.arm ]; then
# #   PLATFORMS=${PLATFORMS},linux/arm
# #   docker push "${NAME}:linux-arm-${VERSION}"
# #   docker push "${NAME}:linux-arm-${VERSION}.${BUILD_NUMBER}"
# # fi
# #
# # if [ -e Dockerfile.arm64 ]; then
# #   PLATFORMS=${PLATFORMS},linux/arm64
# #   docker push "${NAME}:linux-arm64-${VERSION}"
# #   docker push "${NAME}:linux-arm64-${VERSION}.${BUILD_NUMBER}"
# # fi
#
# echo "Pushing manifest lists..."
#
# ./manifest-tool push from-args \
#   --platforms ${PLATFORMS}  \
#   --template "${NAME}:OS-ARCH-${VERSION}" \
#   --target "${NAME}:latest"
#
# ./manifest-tool push from-args \
#   --platforms ${PLATFORMS}  \
#   --template "${NAME}:OS-ARCH-${VERSION}" \
#   --target "${NAME}:${VERSION}"
#
# ./manifest-tool push from-args \
#   --platforms ${PLATFORMS}  \
#   --template "${NAME}:OS-ARCH-${VERSION}" \
#   --target "${NAME}:${VERSION}.${BUILD_NUMBER}"

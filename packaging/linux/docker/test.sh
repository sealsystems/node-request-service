#!/bin/bash -e

PACKAGE_NAME=$(jq -r .name < package.json)
PACKAGE_VERSION=$(jq -r .version < package.json)

echo "Pulling container image..."

while ! docker pull ghcr.io/sealsystems/${PACKAGE_NAME}:${PACKAGE_VERSION}.${BUILD_NUMBER}; do
  echo "Retrying in 10 seconds"
  sleep 10
done

echo "Testing container image..."

# Patch Dockerfile
sed -i "s/<%= name %>/${PACKAGE_NAME}/g" packaging/linux/docker/test/Dockerfile
sed -i "s/<%= version %>/${PACKAGE_VERSION}.${BUILD_NUMBER}/g" packaging/linux/docker/test/Dockerfile

cat packaging/linux/docker/test/Dockerfile

. packaging/linux/rpm/test.sh

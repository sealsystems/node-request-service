#!/bin/bash -e

cd output

FILE=$(ls -1 *.rpm)
NAME=$(jq -r .name < ../package.json)
VERSION=$(jq -r .version < ../package.json)

if [ -z "${FILE}" ]; then
  echo "No RPM file found!"
  exit 1
fi

# Upload to delivery.sealsystems.de
node ../.github/scripts/webdav.js push "${FILE}" "/SEAL Development/workspace/${NAME}/${VERSION}/${FILE}"

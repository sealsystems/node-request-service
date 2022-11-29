#!/bin/bash -e

sudo gem install bundler fpm

sudo apt-get install -y rpm

if [ -n "${NODE_VERSION}" ]; then
  echo "Copying /mnt/3rd-party/nodejs/${NODE_VERSION}/linux/node-v${NODE_VERSION}-linux-x64.tar.gz ..."
  node .github/scripts/webdav.js pull "/SEAL Development/3rd-party/nodejs/${NODE_VERSION}/linux/node-v${NODE_VERSION}-linux-x64.tar.gz" "node-v${NODE_VERSION}-linux-x64.tar.gz"
  tar xzf node-v${NODE_VERSION}-linux-x64.tar.gz node-v${NODE_VERSION}-linux-x64/bin/node
  mv node-v${NODE_VERSION}-linux-x64/bin/node node
  chmod 755 node
fi

if [ -n "${ENVCONSUL_VERSION}" ]; then
  echo "Copying /mnt/3rd-party/envconsul/${ENVCONSUL_VERSION}/linux/envconsul_${ENVCONSUL_VERSION}_linux_amd64.zip"
  node .github/scripts/webdav.js pull "SEAL Development/3rd-party/envconsul/${ENVCONSUL_VERSION}/linux/envconsul_${ENVCONSUL_VERSION}_linux_amd64.zip" "envconsul_${ENVCONSUL_VERSION}_linux_amd64.zip"
  unzip -o envconsul_${ENVCONSUL_VERSION}_linux_amd64.zip
  chmod 755 envconsul
fi

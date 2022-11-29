#!/bin/bash -e

sudo gem install bundler

echo "Downloading manifest-tool for container images..."

curl -k --fail -L https://github.com/estesp/manifest-tool/releases/download/v1.0.0/manifest-tool-linux-amd64 > manifest-tool
chmod +x manifest-tool
./manifest-tool --version

#!/bin/bash -e

set -x

if [ ! -e package.json ]; then
  echo "Error: No package.json found!"
  exit 1
fi

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

PREFIX=/opt/seal

AUTHOR_NAME=$(jq -r .author.name < package.json)
AUTHOR_EMAIL=$(jq -r .author.email < package.json)
AUTHOR_URL=$(jq -r .author.url < package.json)
LICENSE="SEAL End User License"
PACKAGE_VERSION=$(jq -r .version < package.json)
PACKAGE_NAME=$(jq -r .name < package.json)
PACKAGE_DESCRIPTION=$(jq -r .description < package.json)
SERVICE_NAME=$(jq -r .seal.service.name < package.json)
SERVICE_TAGS=$(jq -r .seal.service.tags < package.json)
NODE_DEPENDENCIES=$(jq -r '.dependencies' < package.json)

RESOURCE="${PWD}/packaging/linux/rpm/resource"

echo "Set common fpm arguments"
declare -a FPM_ARGS
FPM_ARGS+=(--architecture $ARCHITECTURE)
FPM_ARGS+=(-s dir)
FPM_ARGS+=(-t ${PACKAGE_TYPE})
FPM_ARGS+=(--force)
FPM_ARGS+=(--verbose)
FPM_ARGS+=(--vendor "${AUTHOR_NAME}")
FPM_ARGS+=(--category "net")
FPM_ARGS+=(--maintainer "${AUTHOR_NAME} <${AUTHOR_EMAIL}>")
FPM_ARGS+=(--url "${AUTHOR_URL}")
FPM_ARGS+=(--license "${LICENSE}")
FPM_ARGS+=(--name "${PACKAGE_NAME}")
FPM_ARGS+=(--version "${PACKAGE_VERSION}")
FPM_ARGS+=(--description "${PACKAGE_DESCRIPTION}")
FPM_ARGS+=(--prefix ${PREFIX})
FPM_ARGS+=(--iteration ${BUILD_NUMBER})
FPM_ARGS+=(--package ../output/)
FPM_ARGS+=(--rpm-rpmbuild-define "_build_id_links none")

echo "Create output and temp dir"
rm -rf output temp
mkdir output
mkdir temp

echo "Execute all steps from within the temp dir"
cd temp

echo "Create and switch to application dir"
mkdir "${PACKAGE_NAME}"
pushd "${PACKAGE_NAME}"

# Node.js application
if [ "${NODE_DEPENDENCIES}" != "null" ]; then
  echo "Copy source files"
  cp ../../README.md .
  cp ../../package.json .
  cp -r ../../bin/ bin/
  cp -r ../../lib/ lib/
  echo "Install Node.js modules"
  npm install --production
fi

if [ -n "${NODE_VERSION}" ]; then
  echo "Copy downdloaded Node.js"
  cp ../../node .
  # after-install must allow the Node.js binary to open privileged ports
  SETCAP_TARGET=node
fi

if [ -n "${ENVCONSUL_VERSION}" ]; then
  echo "Copy downdloaded envconsul"
  cp ../../envconsul .
fi

if [ -e "${DIR}/build.sh.include" ]; then
  echo "Execute custom build steps"
  . "${DIR}/build.sh.include"
fi

echo "Go back to temp dir"
popd

echo "Patch resources"
for file in ${RESOURCE}/*.include ${RESOURCE}/*; do
  if [ -f "${file}" ]; then
    echo Name...
    sed -i "s/<%= name %>/${PACKAGE_NAME}/g" "${file}"
    echo Name without dashes and in captial letters for sudoers config...
    sed -i "s/<%= name-sudoers %>/$(tr "[:lower:]" "[:upper:]" <<< "${PACKAGE_NAME//-/_}")/g" "${file}"
    echo Description...
    sed -i "s/<%= description %>/${PACKAGE_DESCRIPTION}/g" "${file}"
    echo Service name...
    sed -i "s/<%= service-name %>/${SERVICE_NAME}/g" "${file}"
    echo Service tags...
    sed -i "s/<%= service-tags %>/${SERVICE_TAGS}/g" "${file}"
    echo Executable to apply setcap to...
    sed -i "s/<%= setcap-executable %>/${SETCAP_TARGET}/g" "${file}"
    echo Custom after-install steps...
    sed -i -e "/after-install-include/{ r ${RESOURCE}/after-install.sh.include" -e "d }" "${file}"
    echo Custom before-remove steps...
    sed -i -e "/before-remove-include/{ r ${RESOURCE}/before-remove.sh.include" -e "d }" "${file}"
  fi;
done

# Only needed for Node.js application but included everywhere to minimize
# differences of build configurations.
echo "Copy envconsul.json.template"
cp "${RESOURCE}/envconsul.json.template" "${PACKAGE_NAME}"

echo "Copy start script"
if [ -e "${RESOURCE}/start.sh.custom" ]; then
  echo "Using start.sh.custom"
  cp "${RESOURCE}/start.sh.custom" "${PACKAGE_NAME}/start.sh"
else
  cp "${RESOURCE}/start.sh" "${PACKAGE_NAME}"
fi

echo "Copy systemd service and sudoers config"
cp "${RESOURCE}/service" "${PACKAGE_NAME}/${PACKAGE_NAME}.service"
cp "${RESOURCE}/sudoers" "${PACKAGE_NAME}"

echo "Include init scripts"
test -e "${RESOURCE}/after-install.sh" && FPM_ARGS+=(--after-install "${RESOURCE}/after-install.sh")
test -e "${RESOURCE}/before-remove.sh" && FPM_ARGS+=(--before-remove "${RESOURCE}/before-remove.sh")

echo "Include config files"
if [ -d "${RESOURCE}/etc" ]; then
  for file in ${RESOURCE}/etc/*; do
    file=${file#${RESOURCE}/} # Remove resource dir name
    FPM_ARGS+=(--config-files "${PREFIX}/${file}")
  done;
  cp -r "${RESOURCE}/etc" .
fi

echo "Copy standard (selfsigned) certificate from seal-tlscert into tls directory"
mkdir -p ${PACKAGE_NAME}/tls
cp -r ../tls/* ${PACKAGE_NAME}/tls

echo "Build package"
set -x
fpm "${FPM_ARGS[@]}" .

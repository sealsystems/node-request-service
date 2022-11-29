#!/bin/bash -e

export PACKAGE_VERSION=$(cat package.json | jq -r .version)
export PACKAGE_NAME=$(cat package.json | jq -r .name)

cd packaging/linux/${PACKAGE_TYPE}/test
bundle install

# copy the deb file to test directory to add them into the docker image
if [ -d "../../../../output" ]; then
  cp -r ../../../../output .
fi

echo "Running ${PACKAGE_TYPE} serverspec tests ..."
bundle exec rspec --color --format documentation spec/*_spec.rb

#!/usr/bin/env bash

set -e

MY_PATH="$(dirname -- "${BASH_SOURCE[0]}")"
cd ${MY_PATH}

# Local installation
BUNDLE_PATH=$(realpath ${BUNDLE_PATH:-"lib/ruby/gems"})
mkdir -p ${BUNDLE_PATH}
echo "export GEM_PATH=\${GEM_PATH}:${BUNDLE_PATH}" > ./.gem_path

source env.sh

echo "Installing bundle"
bundle install
gem install --install-dir ${BUNDLE_PATH} gli


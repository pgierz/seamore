#!/usr/bin/env bash

set -e

MY_PATH="$(dirname -- "${BASH_SOURCE[0]}")"
cd ${MY_PATH}

# Local installation
BUNDLE_PATH=${BUNDLE_PATH:-"lib"}
mkdir -p ${BUNDLE_PATH}
BUNDLE_PATH=$(realpath ${BUNDLE_PATH})

source env.sh

RUBY_VERSION=$(ruby --version | grep -oE '[0-9]+\.[0-9]+\.[0-9]+')
echo "export GEM_PATH=\${GEM_PATH}:${BUNDLE_PATH}/ruby/${RUBY_VERSION}" > ./.gem_path

echo "Installing bundle"
bundle config set --local path "lib"
bundle install
gem install --install-dir ${BUNDLE_PATH}/ruby/${RUBY_VERSION} gli

echo "Downloading submodules"
git submodule update --init

echo "Installing ncn"
cd gitmodules/ncn
source env.sh


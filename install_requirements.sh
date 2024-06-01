#!/bin/bash

PACKS='
meson
ninja-build
python3-pyelftools
python3-pip
pkg-config
rdma-core
libibverbs-dev
libnuma-dev
msr-tools
'

set -xe

sudo apt update
sudo apt install -y ${PACKS}

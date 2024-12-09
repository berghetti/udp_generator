#!/bin/bash

PACKS='
python3-pyelftools
python3-pip
pkg-config
rdma-core
libibverbs-dev
libnuma-dev
msr-tools
'

# Ubuntu
VERSION=$(grep -oP '(?<=VERSION_ID=")\d+' /etc/os-release)

set -xe

sudo apt update
sudo apt install -y ${PACKS}

# Check if the major version is below 20
if [[ $VERSION -le 20 ]]; then
  sudo pip3 install meson ninja
else
  sudo apt install meson ninja-build
fi

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

# to process results
if [[ $VERSION -le 20 ]]; then
  # install python 3.8
  sudo apt-get install -y python3.8 python3.8-dev python3.8-distutils python3.8-venv
  curl https://bootstrap.pypa.io/get-pip.py -o get-pip.py
  python3.8 get-pip.py
  rm get-pip.py
  python3.8 -m pip install json5 polars
else
  sudo apt install -y python3-json5
  pip3 install polars
fi

# Check if the major version is below 20
if [[ $VERSION -le 20 ]]; then
  sudo pip3 install meson ninja
else
  sudo apt install -y meson ninja-build
fi

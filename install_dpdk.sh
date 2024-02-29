#!/bin/bash

git clone https://github.com/DPDK/dpdk.git -o dpdk
git checkout v23.03

pushd ./dpdk

meson build
meson configure -Dprefix=$PWD/build build
ninja -C build
sudo ninja -C build install

popd


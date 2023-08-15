#!/bin/bash

git clone https://github.com/DPDK/dpdk.git -o dpdk
git checkout v22.11

pushd ./dpdk

meson build
meson configure -Dprefix=$PWD/build build
ninja -C build
sudo ninja -C build install

echo "$PWD/build/lib64/" | sudo tee /etc/ld.so.conf.d/dpdk.conf
sudo ldconfig

popd


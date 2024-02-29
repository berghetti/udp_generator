#!/bin/bash

git clone https://github.com/DPDK/dpdk.git -o dpdk
git checkout v23.03

pushd ./dpdk

meson build
meson configure -Dprefix=$PWD/build build
ninja -C build
ninja -C build install

popd

# install igb_uio driver
git clone https://dpdk.org/git/dpdk-kmods
make -C dpdk-kmods/linux/igb_uio/
sudo modprobe uio
sudo insmod dpdk-kmods/linux/igb_uio/igb_uio.ko

# TODO: bind interface
# ./dpdk/usertools/dpdk-devbind.py -b igb_uio 18:00.1

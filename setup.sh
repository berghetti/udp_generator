#!/bin/bash

# 16GiB
sudo bash -c 'echo 8192 > /sys/devices/system/node/node0/hugepages/hugepages-2048kB/nr_hugepages'

sudo ip link set down dev enp24s0f1
sudo modprobe uio
sudo insmod dpdk-kmods/linux/igb_uio/igb_uio.ko
sudo ./dpdk/usertools/dpdk-devbind.py -b igb_uio 18:00.1

./misc/turbo.sh disable

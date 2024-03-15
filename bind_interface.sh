#!/bin/bash

sudo ip link set down dev enp24s0f1
./dpdk/usertools/dpdk-devbind.py -b igb_uio 18:00.1

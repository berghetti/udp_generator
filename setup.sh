#!/bin/bash
source $(dirname $0)/MACHINE_CONFIG

# disable whatchdog
sudo sysctl -w kernel.watchdog=0

# set hugepages
sudo bash -c "echo 8192 > /sys/devices/system/node/node${NUMA_ID}/hugepages/hugepages-2048kB/nr_hugepages"

# disabe turbo boost
$(dirname $0)/misc/turbo.sh disable 2&>1 /dev/null

# bind NIC
if [[ "$NIC_BIND" != "false" ]]; then
  sudo modprobe uio
  sudo insmod $(dirname $0)/dpdk-kmods/linux/igb_uio/igb_uio.ko
  sudo ip link set down dev ${NIC_NAME}
  sudo $(dirname $0)/dpdk/usertools/dpdk-devbind.py -b igb_uio ${NIC_PCI}
fi


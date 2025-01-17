#!/bin/bash

set -xe

git clone https://github.com/DPDK/dpdk.git -o dpdk

pushd ./dpdk

git checkout v23.11

# See https://networkbuilders.intel.com/docs/networkbuilders/power-management-enhanced-power-management-for-low-latency-workloads-technology-guide-1617438252.pdf A.9
git apply ../dpdk_i40e.patch

git apply ../dpdk.patch

disable_apps='dumpcap,pdump,proc-info,test-acl,test-bbdev,test-cmdline,test-compress-perf,test-crypto-perf,test-eventdev,test-fib,test-flow-perf,test-gpudev,test-mldev,test-pipeline,test-pmd,test-regex,test-sad,test-security-perf,graph,test-dma-perf'

disable_libs='node,graph,pipeline,table,port,fib,pdcp,ipsec,vhost,stack,security,sched,reorder,rib,mldev,regexdev,rawdev,power,pcapng,member,lpm,latencystats,jobstats,dispatcher,gpudev,cryptodev,distributor'

disable_drivers='crypto/*,gpu/*,baseband/*,compress/*'

meson setup \
  -Dc_args=-DRTE_LIBRTE_I40E_16BYTE_RX_DESC \
  -Dplatform=native \
  -Dtests=false \
  -Dexamples='' \
  -Ddisable_apps=$disable_apps \
  -Ddisable_libs=$disable_libs \
  -Ddisable_drivers=$disable_drivers \
  -Dprefix=$PWD/build build

ninja -C build
ninja -C build install

popd

# install igb_uio driver
git clone https://dpdk.org/git/dpdk-kmods
make -C dpdk-kmods/linux/igb_uio/
sudo modprobe uio
sudo insmod dpdk-kmods/linux/igb_uio/igb_uio.ko


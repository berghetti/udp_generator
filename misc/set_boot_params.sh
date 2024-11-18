#!/bin/bash
source $(dirname $0)/../MACHINE_CONFIG

# Define the new line
new_line="GRUB_CMDLINE_LINUX_DEFAULT=\"tsc=reliable isolcpus=${CPUS_RESERVED} rcu_nocbs=${CPUS_RESERVED} nohz_full=${CPUS_RESERVED} nohz=on nokaslr\""
set -xe

# Replace the line in the file
sudo sed -i "s/^GRUB_CMDLINE_LINUX_DEFAULT=.*/$new_line/" /etc/default/grub

sudo update-grub


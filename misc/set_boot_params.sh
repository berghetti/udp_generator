#!/bin/bash

# Define the new line
new_line='GRUB_CMDLINE_LINUX_DEFAULT="tsc=reliable isolcpus=0,2,4,6,8,10,12,14,16,18,20,22,24,26,28 rcu_nocbs=0,2,4,6,8,10,12,14,16,18,20,22,24,26,28 nohz_full=0,2,4,6,8,10,12,14,16,18,20,22,24,26,28"'

set -xe

# Replace the line in the file
sudo sed -i "s/^GRUB_CMDLINE_LINUX_DEFAULT=.*/$new_line/" /etc/default/grub

sudo update-grub


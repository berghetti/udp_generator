#!/bin/bash

#Usage: set_ip.sh src_ip dst_ip

CONF_FILE="$(dirname $0)/../config.cfg"

# set src address
sed -i '/\[ipv4\]/{n;s/\(src\s*=\s*\)[0-9.]\+/\1'$1'/;}' $CONF_FILE

# set dst address
sed -i '/\[ipv4\]/{n;n;s/\(dst\s*=\s*\)[0-9.]\+/\1'$2'/;}' $CONF_FILE

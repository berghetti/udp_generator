#!/bin/bash
set -x

mkdir ktemp
pushd ktemp

wget https://kernel.ubuntu.com/mainline/v4.4.185/linux-headers-4.4.185-0404185_4.4.185-0404185.201907100448_all.deb \
  https://kernel.ubuntu.com/mainline/v4.4.185/linux-headers-4.4.185-0404185-generic_4.4.185-0404185.201907100448_amd64.deb \
  https://kernel.ubuntu.com/mainline/v4.4.185/linux-modules-4.4.185-0404185-generic_4.4.185-0404185.201907100448_amd64.deb \
  https://kernel.ubuntu.com/mainline/v4.4.185/linux-image-unsigned-4.4.185-0404185-generic_4.4.185-0404185.201907100448_amd64.deb

sudo  dpkg  -i  *.deb

sudo sed -i 's/GRUB_DEFAULT=0/GRUB_DEFAULT="1>2"/g' /etc/default/grub

sudo update-grub

popd
rm -rf ktemp

#!/bin/bash
set -xe

sudo apt update
sudo apt install -y python3-pip
pip install -r ./requirements.txt
sudo apt remove -y python3-openssl

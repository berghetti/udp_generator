#!/bin/bash

set -xe

sudo apt update
sudo apt install -y $(cat ./prerequisites.txt)

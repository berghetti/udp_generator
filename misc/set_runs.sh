#!/bin/bash

sed -i "s/^RUNS=.*/RUNS=$1/" $(dirname $0)/../run_common.sh


#!/bin/bash

N_CLIENTS=6
BASE_DIR='/proj/demeter-PG0/users/fabricio/afp_tests'

for rate in {1000..6000..1000}; do
#for rate in 1000; do
  rate=$((rate * 1000 / N_CLIENTS))
  ./shremote.py psp_run.yml psp -- --basedir $BASE_DIR --rate $rate --wk wk1
done


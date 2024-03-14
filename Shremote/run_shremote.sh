#!/bin/bash

N_CLIENTS=6

#for rate in {1000..5000..1000}; do
for rate in 1000; do
  rate=$((rate * 1000 / N_CLIENTS))
  ./shremote.py config.cfg hello -- --rate $rate --wk wk2
done


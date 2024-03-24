#!/bin/bash
#
# Usage: ./run_clients.sh afp|psp

N_CLIENTS=6
N_TESTS=5
BASE_DIR='/proj/demeter-PG0/users/fabricio/afp_tests'

RANDOMS=(7 365877 374979 853172 908081 227836 64991 493663 174817 73997)

for rate in {500..4500..500}; do
  rate=$((rate * 1000 / N_CLIENTS))

  for i in $(seq 0 $((N_TESTS-1))); do
    rand=${RANDOMS[$i]}

    until ./shremote.py clients.yml $1 -- --basedir $BASE_DIR --rate $rate --wk wk1 --rand $rand --test $i --policy $1
    do
      echo "Trying again after 30 seconds"
      sleep 60
    done
  done
done


#!/bin/bash
set -e
#
# Usage: ./run_clients.sh afp|psp

source $(dirname $0)/../run/common.sh

N_CLIENTS=5
N_TESTS=1
BASE_DIR='/proj/demeter-PG0/users/fabricio/afp_tests'

TOT_WORKER=14
AVG_SERVICE_TIME=1
#AVG_SERVICE_TIME=$(awk 'BEGIN {print 0.5*0.995 + 500*0.005 }')

# create RPS[] based on TOT_WORKER and AVG_SERVICE_TIME
create_rps_array 10 90 10

RANDOMS=(7 365877 374979 853172 908081 227836 64991 493663 174817 73997)

for rate in ${RPS[@]}; do
  rate=$((rate / N_CLIENTS)) # per client rate

  for i in $(seq 0 $((N_TESTS-1))); do
    rand=${RANDOMS[$i]}

    #until ./shremote.py clients.yml $1 -- --basedir $BASE_DIR --rate $rate --wk wk1 --rand $rand --test $i --policy $1
    until ./shremote.py clients.yml $1 -- --basedir $BASE_DIR --rate $rate --wk shorts --rand $rand --test $i --policy $1
    do
      echo "Trying again after 60 seconds"
      sleep 60
    done
  done
done


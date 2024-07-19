#!/bin/bash
set -e
#
# Usage: ./run_clients.sh afp|psp

source $(dirname $0)/../run/common.sh

N_CLIENTS=5
N_TESTS=5
BASE_DIR='/proj/demeter-PG0/users/fabricio/afp_tests'

WK="extreme"

TOT_WORKER=14

case $WK in
  "shorts") AVG_SERVICE_TIME=$(awk 'BEGIN {print 1.0*1.0 }')  ;; #only one type
  "extreme") AVG_SERVICE_TIME=$(awk 'BEGIN {print 0.8*0.995 + 650*0.005 }') ;; #extreme 99.5%/0.5%
  "high") AVG_SERVICE_TIME=$(awk 'BEGIN {print 0.8*0.5 + 650*0.5 }') ;;   #high 50%/50%
esac

# create RPS[] based on TOT_WORKER and AVG_SERVICE_TIME
create_rps_array 10 90 10
echo ${RPS[@]}

RANDOMS=(7 365877 374979 853172 908081 227836 64991 493663 174817 73997)

for rate in ${RPS[@]}; do
#for rate in ${RPS[0]}; do
  echo "Rate: ${rate}"
  rate=$((rate / N_CLIENTS)) # per client rate

  for i in $(seq 0 $((N_TESTS-1))); do
    rand=${RANDOMS[$i]}

    until ./shremote.py clients.yml $1 -- --basedir $BASE_DIR --rate $rate --wk wk1 --rand $rand --test $i --policy $1
    do
      echo "Trying again after 60 seconds"
      sleep 60
    done
  done
done


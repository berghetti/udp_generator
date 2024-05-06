#!/bin/bash
set -e

source $(dirname $0)/common.sh

RUNS=1
TOT_WORKER=14
AVG_SERVICE_TIME=$(awk 'BEGIN {print 1*0.99 + 100*0.01 }')

create_rps_array

run()
{
  policy=$1
  load_name='1_100'
  set_w2

  for dist in 'exponential'; do

    for rate in ${RPS[@]}; do
      test_dir="${dist}/${load_name}/${policy}/${rate}"
      echo "Runing ${policy} with rate ${rate}"
      run_test $test_dir $dist $rate
    done

  done
}

set_classification_time 0
run "psp-cl0"


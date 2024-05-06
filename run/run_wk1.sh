#!/bin/bash
set -e

source $(dirname $0)/common.sh

RUNS=1
TOT_WORKER=14
AVG_SERVICE_TIME=$(awk 'BEGIN {print 0.5*0.995 + 500*0.005 }')

create_rps_array

run()
{
  policy=$1
  load_name='0.5_500'
  set_w1

  for dist in 'exponential'; do

    for rate in ${RPS[@]}; do
      test_dir="${dist}/${load_name}/${policy}/${rate}"
      echo "Runing ${policy} with rate ${rate}"
      run_test $test_dir $dist $rate
    done

  done
}

set_classification_time 0
run "afp-cl0-ws"

#!/bin/bash
set -e

source $(dirname $0)/common.sh

RUNS=1
TOT_WORKER=14
AVG_SERVICE_TIME=1

create_rps_array

run()
{
  policy=$1
  load_name="shorts-${AVG_SERVICE_TIME}us"
  set_only_shorts_rate $((AVG_SERVICE_TIME * 1000))

  for dist in 'exponential'; do

    for rate in ${RPS[@]}; do
      test_dir="${dist}/${load_name}/${policy}/${rate}"
      echo "Runing ${policy} with rate ${rate}"
      run_test $test_dir $dist $rate
    done

  done
}

set_classification_time 0
run "afp-shorts-2us"

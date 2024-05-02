#!/bin/bash

source ./run_common.sh

TOT_WORKER=14
AVG_SERVICE_TIME=2

RPS=()

create_rps_array()
{
  # load percent
  for load in {10..90..10};
  do
    r=$(awk -v st=$AVG_SERVICE_TIME -v w=$TOT_WORKER -v load=$load 'BEGIN { print 10^6 / st * w * (load / 100)}')
    RPS+=($r)
  done
}


run()
{
  policy=$1
  rate=$2
  load_name='shorts-2us'
  set_only_shorts_rate 2000

  create_rps_array

  for dist in 'exponential'; do

    for rate in ${RPS[@]}; do
      #rate=$((rate * 1000))
      test_dir="${dist}/${load_name}/${policy}/${rate}"
      echo "Runing ${policy} with rate ${rate}"
      run_test $test_dir $dist $rate
    done

  done
}

set_classification_time 0
run "afp-shorts-2us"

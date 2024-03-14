#!/bin/bash

source ./run_common.sh

run_w1()
{
  policy=$1
  rate=$2
  load_name='0.5_500'
  set_w1

  for dist in 'exponential'; do

    #for rate in {1000..5000..1000}; do
    #for rate in 1000; do
      rate=$((rate * 1000))
      test_dir="${dist}/${load_name}/${policy}/${rate}"
      echo "Runing ${policy} with rate ${rate}"
      run_test $test_dir $dist $rate
    #done

  done
}

set_classification_time 0
run_w1 "psp-cl0" $2

#!/bin/bash

source ./run_common.sh


run_w1()
{
  policy=$1
  load_name='1_100'
  set_w2

  for dist in 'exponential'; do

    for rate in {1000..5000..1000}; do
    #for rate in 5000; do
      rate=$((rate * 1000))
      test_dir="${dist}/${load_name}/${policy}/${rate}"
      echo "Runing ${policy} with rate ${rate}"
      run_test $test_dir $dist $rate
    done

  done
}

set_classification_time 0
#run_w1 "psp-cl0"
run_w1 "afp-cl0-ws"
#run_w1 "rss-cl0"
#run_w1 "afp-cl0"
#run_w1 "afp-cl0-sig"

#set_classification_time 50
#run_w1 "psp-cl50"
#run_w1 "afp-cl50"

#set_classification_time 100
#run_w1 "psp-cl100"
#run_w1 "afp-cl100"


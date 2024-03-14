#!/bin/bash

source ./run_common.sh

run_w1()
{
  set_w1
  policy=$1
  rate=$2
  load_name='0.5_500'
  dist='exponential'

  rate=$((rate * 1000))
  test_dir="${dist}/${load_name}/${policy}/${rate}"
  echo "Runing ${policy} with rate ${rate}"
  run_test $test_dir $dist $rate
}

run_w2()
{
  set_w2
  policy=$1
  rate=$2
  load_name='1_100'
  dist='exponential'

  rate=$((rate * 1000))
  test_dir="${dist}/${load_name}/${policy}/${rate}"
  echo "Runing ${policy} with rate ${rate}"
  run_test $test_dir $dist $rate
}

set_classification_time 0

policy=$2
rate=$3
wk=$4

if [ "$wk" = "wk1" ]; then
  run_w1 $policy $rate
fi;

if [ "$wk" = "wk2" ]; then
  run_w2 $policy $rate
fi;

#!/bin/bash

source $(dirname $0)/../run/common.sh

policy=$2
rate=$3
wk=$4
rand=$5
test_i=$6
dist='exponential'

set_classification_time 0

echo "Runing ${policy} with rate ${rate}"

run_w1()
{
  set_w1
  load_name='0.5_500'

  test_dir="${dist}/${load_name}/${policy}/${rate}"
  run_one $test_dir $dist $rate $rand $test_i
}

run_w2()
{
  set_w2
  load_name='1_100'

  test_dir="${dist}/${load_name}/${policy}/${rate}"
  run_one $test_dir $dist $rate $rand $test_i
}

run_shorts()
{
  set_only_shorts
  load_name='shorts_1'

  test_dir="${dist}/${load_name}/${policy}/${rate}"
  run_one $test_dir $dist $rate $rand $test_i
}



if [ "$wk" = "wk1" ]; then
  run_w1
fi;

if [ "$wk" = "wk2" ]; then
  run_w2
fi;

if [ "$wk" = "shorts" ]; then
  run_shorts
fi;

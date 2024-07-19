#!/bin/bash

# Script utilized to run in multiples clientes using Shremote

source $(dirname $0)/../run/common.sh

BASE_DIR=$1
policy=$2
rate=$3
wk=$4
rand=$5
test_i=$6
dist='exponential'

set_classification_time 0

echo "Runing ${policy} with rate ${rate}"

run_extreme()
{
  set_extreme
  load_name='extreme'

  test_dir="${dist}/${load_name}/${policy}/${rate}"
  run_one $test_dir $dist $rate $rand $test_i
}

run_high()
{
  set_high
  load_name='high'

  test_dir="${dist}/${load_name}/${policy}/${rate}"
  run_one $test_dir $dist $rate $rand $test_i
}

run_shorts()
{
  set_only_shorts
  load_name='shorts'

  test_dir="${dist}/${load_name}/${policy}/${rate}"
  run_one $test_dir $dist $rate $rand $test_i
}



if [ "$wk" = "extreme" ]; then
  run_extreme
fi;

if [ "$wk" = "high" ]; then
  run_high
fi;

if [ "$wk" = "shorts" ]; then
  run_shorts
fi;

#!/bin/bash

source $(dirname $0)/common.sh

BASE_DIR=$1
policy=$2
rate=$3
wk=$4
rand=$5
test_i=$6
dist='exponential'

set_classification_time 0

echo "Runing ${policy} with rate ${rate}"

_run()
{
  load_name=$1
  
  test_dir="${dist}/${load_name}/${policy}/${rate}"
  run_one $test_dir $dist $rate $rand $test_i
}

if [ "$wk" = "extreme" ]; then
  set_extreme
elif [ "$wk" = "high" ]; then
  set_high
elif [ "$wk" = "shorts" ]; then
  set_only_shorts
elif [ "$wk" = "very_shorts" ]; then
  set_very_shorts
else
  echo "${wk} unknow"
  exit 1
fi;
  
_run $wk

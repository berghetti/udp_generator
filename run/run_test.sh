#!/bin/bash

# Usage: ./run_clients.sh afp|psp <workload>

#set -euo pipefail

source $(dirname "$0")/common.sh

N_CLIENTS=1
N_TESTS=5
BASE_DIR="/proj/demeter-PG0/users/fabricio/afp_tests/"
TOT_WORKER=14

#if [[ $# -lt 1 ]]; then
#  echo "Usage: $0 <policy> <workload>"
#  exit 1
#fi

generate_rates()
{
  local workload=$1
  echo "Workload: ${workload}"

  # Calculate average service time based on the workload
  case $workload in
    "shorts") AVG_SERVICE_TIME=$(awk 'BEGIN {print 1.0*1.0}')  ;;
    "very_shorts") AVG_SERVICE_TIME=$(awk 'BEGIN {print 0.5*1.0}')  ;;
    "extreme") AVG_SERVICE_TIME=$(awk 'BEGIN {print 0.5*0.995 + 500*0.005}') ;;
    "leveldb_extreme") AVG_SERVICE_TIME=$(awk 'BEGIN {print 0.85*0.97 + 95*0.03}') ;;
    "leveldb_high") AVG_SERVICE_TIME=$(awk 'BEGIN {print 0.85*0.5 + 95*0.5}') ;;
    "high") AVG_SERVICE_TIME=$(awk 'BEGIN {print 1*0.5 + 100*0.5}') ;;
    "zippydb") AVG_SERVICE_TIME=$(awk 'BEGIN {print 0.5*0.78 + 2.5*0.19 + 100*0.03}') ;;
    "zippydb2") AVG_SERVICE_TIME=$(awk 'BEGIN {print 0.5*0.78 + 2.5*0.19 + 500*0.03}') ;;
    "up2x") AVG_SERVICE_TIME=$(awk 'BEGIN {print 0.5*0.075 + 5*0.925}') ;;
    *) echo "Invalid workload: $workload"; exit 1 ;;
  esac

  # clear RPS array
  RPS=()
  echo "Average Service Time: $AVG_SERVICE_TIME"

  # Define RPS array based on workload and TOT_WORKER
  case $workload in
    "shorts") create_rps_array 1 50 3 ;;
    "high")
      create_rps_array 10 50 10
      create_rps_array 55 95 5
      create_rps_array 96 100 1
      ;;
    "extreme")
      create_rps_array 10 30 10
      create_rps_array 35 85 5
      create_rps_array 75 85 2
      ;;
    "leveldb_extreme")
      #create_rps_array 10 30 5
      create_rps_array 20 20 5
      ;;
    "leveldb_high")
      #create_rps_array 10 120 10
      create_rps_array 102 110 2
      ;;
    "zippydb")
      create_rps_array 10 50 10
      create_rps_array 55 100 5
      ;;
    "zippydb2")
      create_rps_array 10 50 10
      create_rps_array 55 90 5
      create_rps_array 92 100 2
      ;;
    "up2x")
      create_rps_array 10 40 10
      create_rps_array 45 90 5
      ;;
    *) create_rps_array 5 100 5 ;;
  esac

  echo "RPS Array: ${RPS[*]}"
}

SSH="ssh 130.127.133.190"

# Function to stop the server
stop_server() {
  local server=$1
  echo "Stopping server: $server"
  $SSH "sudo killall -2 -r $server; sleep 1;"
}

DB_SIZE=1000

# Function to start the server and ensure it runs in the background
start_server() {
  local server=$1
  local workload=$2
  local rate=$3
  echo "Starting server: $server"

  local command=""
  case $server in
    "rss"*) command="afp-all/scripts/afp_run.sh $server $DB_SIZE" ;;
    #"afp"*) command="afp-all/scripts/afp_run.sh $server $DB_SIZE" ;;
    "afp"*) command="afp-all/scripts/afp_run.sh $server $workload $rate" ;;
    "psp") command="afp-all/scripts/psp_run.sh $DB_SIZE";;
    "tq") command="afp-all/scripts/tq_run.sh" ;;
    "shinjuku"*) command="afp-all/scripts/shinjuku_run.sh $server $workload" ;;
    "concord") command="afp-all/scripts/concord_run.sh $DB_SIZE" ;;
    *) echo "Unknown server type: $server"; exit 1 ;;
  esac

  $SSH "$command" &
}

#NFLOWS=(8 16 32 64 512)
NFLOWS=(512)
RANDOMS=(7 365877 3779 9283 908081 227836 64991 493663 174817 73997)
TAG=0

process_test()
{
  pushd ../process
  ./process_experiments.sh $1 $2 $TAG && sudo ./process_experiments.sh $1 $2 clean
  popd
}

RPS=(750079)

# Function to run tests
run_test() {
  local workload=$1
  local policy=$2

  for nflow in "${NFLOWS[@]}"; do

    for rate in "${RPS[@]}"; do
      echo "Rate: $rate"
      local per_client_rate=$((rate / N_CLIENTS))

      #for i in $(seq 0 $((N_TESTS-1))); do
      for i in 0; do
        #start_server "${policy}-flows${nflow}" $workload $rate
        start_server $policy $workload $rate
        sleep 20

        echo "Starting client with rate: $per_client_rate"
        #$(dirname "$0")/run.sh "$BASE_DIR" "${policy}-flows${nflow}" "$per_client_rate" "$workload" "${RANDOMS[$i]}" "$i" $nflow
        $(dirname "$0")/run.sh "$BASE_DIR" "${policy}" "$per_client_rate" "$workload" "${RANDOMS[$i]}" "$i" $nflow

        stop_server $policy
        #process_test $wk "${policy}-flows${nflow}"
        process_test $wk $policy
      done

    done
  done
}

TAG="int_save"
#POLICYS=(
##  "afp"
##  "tq"
#  "psp"
#  "shinjuku-ci"
#  "shinjuku"
#  "concord"
#)
#
##for wk in {high,zippydb2,extreme}; do
#for wk in zippydb2; do
#  generate_rates $wk
#
#  for pol in ${POLICYS[@]}; do
#    echo $wk $pol
#    run_test $wk $pol
#  done
#done

POLICYS=(
  "afp"
#  "tq"
#  "psp"
#  "shinjuku-ci"
#  "shinjuku"
#  "concord"
)

for wk in zippydb2; do
  generate_rates $wk

  for pol in ${POLICYS[@]}; do
    echo $wk $pol
    run_test $wk $pol
  done
done


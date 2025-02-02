#!/bin/bash

# Usage: ./run_clients.sh afp|psp <workload>

#set -euo pipefail

source $(dirname "$0")/common.sh

N_CLIENTS=1
N_TESTS=1
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
    "high") AVG_SERVICE_TIME=$(awk 'BEGIN {print 1*0.5 + 100*0.5}') ;;
    "zippydb") AVG_SERVICE_TIME=$(awk 'BEGIN {print 0.6*0.78 + 2.3*0.19 + 500*0.03}') ;;
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
      create_rps_array 55 100 5
      ;;
    "extreme")
      #create_rps_array 50 50 10
      create_rps_array 10 50 10
      create_rps_array 55 85 5
      ;;
    "zippydb")
      create_rps_array 10 50 10
      create_rps_array 55 100 5
      ;;
    *) create_rps_array 5 100 5 ;;
  esac

  echo "RPS Array: ${RPS[*]}"
}

SSH="ssh 130.127.133.198"

# Function to stop the server
stop_server() {
  local server=$1
  echo "Stopping server: $server"
  $SSH "sudo killall -2 -r $server; sleep 1;"
}

# Function to start the server and ensure it runs in the background
start_server() {
  local server=$1
  echo "Starting server: $server"

  local command=""
  case $server in
    "rss"*) command="make run -C afp-all/afp/apps/fake/ APP=$server" ;;
    "afp") command="afp-all/scripts/afp_run.sh" ;;
    "psp") command="afp-all/scripts/psp_run.sh" ;;
    "shinjuku") command="afp-all/scripts/shinjuku_run.sh" ;;
    "concord") command="afp-all/scripts/concord_run.sh" ;;
    *) echo "Unknown server type: $server"; exit 1 ;;
  esac

  $SSH "$command" &
}

RANDOMS=(7 365877 374979 853172 908081 227836 64991 493663 174817 73997)

process_test()
{
  pushd ../process
  ./process_experiments.sh $1 $2 && sudo ./process_experiments.sh $1 $2 clean
  popd
}

# Function to run tests
run_test() {
  local workload=$1
  local policy=$2

  for rate in "${RPS[@]}"; do
    echo "Rate: $rate"
    local per_client_rate=$((rate / N_CLIENTS))

    for i in $(seq 0 $((N_TESTS-1))); do
      start_server $policy
      sleep 20

      echo "Starting client with rate: $per_client_rate"
      $(dirname "$0")/run.sh "$BASE_DIR" "$policy" "$per_client_rate" "$workload" "${RANDOMS[$i]}" "$i"

      stop_server $policy
      process_test $wk $pol
    done

  done
}

#run_test

#POLICYS=(
#  "rss"
#  "rss-ci"
#  "rss-ws"
#  "rss-ws-ci"
#  "rss-ws-ci-wq"
#  "rss-ws-ci-wq-cp"
#  "rss-ws-ci-wq-cp-feed-qa"
#  "rss-ws-ci-wq-cp-feed-qa-tw"
#)

POLICYS=(
  "afp"
  "psp"
  "shinjuku"
  "concord"
)

for wk in {extreme,high,zippydb}; do
  generate_rates $wk

  for pol in ${POLICYS[@]}; do
    echo $wk $pol
    run_test $wk $pol
  done
done

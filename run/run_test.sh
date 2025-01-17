#!/bin/bash

# Usage: ./run_clients.sh afp|psp [workload]

#set -euo pipefail

source $(dirname "$0")/common.sh

N_CLIENTS=1
N_TESTS=1
BASE_DIR="/proj/demeter-PG0/users/fabricio/afp_tests/"
TOT_WORKER=14

if [[ $# -lt 1 ]]; then
  echo "Usage: $0 <policy> [workload]"
  exit 1
fi

POLICY=$1
WK=${2:-"extreme"}

echo "Workload: $WK"

# Calculate average service time based on the workload
case $WK in
  "shorts") AVG_SERVICE_TIME=$(awk 'BEGIN {print 1.0*1.0}')  ;;
  "very_shorts") AVG_SERVICE_TIME=$(awk 'BEGIN {print 0.5*1.0}')  ;;
  "extreme") AVG_SERVICE_TIME=$(awk 'BEGIN {print 0.5*0.995 + 500*0.005}') ;;
  "high") AVG_SERVICE_TIME=$(awk 'BEGIN {print 1*0.5 + 100*0.5}') ;;
  "zippydb") AVG_SERVICE_TIME=$(awk 'BEGIN {print 0.6*0.78 + 2.3*0.19 + 500*0.03}') ;;
  *) echo "Invalid workload: $WK"; exit 1 ;;
esac

echo "Average Service Time: $AVG_SERVICE_TIME"

# Define RPS array based on workload and TOT_WORKER
case $WK in
  "shorts") create_rps_array 1 50 3 ;;
  "high")
    create_rps_array 5 50 10
    create_rps_array 50 100 5
    ;;
  "extreme")
    create_rps_array 5 30 10
    create_rps_array 30 85 5
    ;;
  "zippydb")
    create_rps_array 5 100 5
    ;;
  *) create_rps_array 5 100 5 ;;
esac

echo "RPS Array: ${RPS[*]}"

SSH="ssh 130.127.133.237"

# Function to stop the server
stop_server() {
  local server=$1
  echo "Stopping server: $server"
  $SSH "sudo killall -2 -w $server"
}

# Function to start the server and ensure it runs in the background
start_server() {
  local server=$1
  echo "Starting server: $server"

  local command=""
  case $server in
    "rss"*) command="make run -C afp-all/afp/apps/fake/ APP=$server" ;;
    "afp"*"ci") command="sudo afp/deps/dpdk/usertools/dpdk-devbind.py -b igb_uio 18:00.1; make run -C afp/apps/fake/ APP=fake-app-ci" ;;
    "afp"*"ipi") command="sudo afp/deps/dpdk/usertools/dpdk-devbind.py -b igb_uio 18:00.1; make run -C afp/apps/fake/ APP=fake-app-kmod-ipi" ;;
    *"concord"*) command="cd concord/concord-shinjuku/; sudo ./deps/dpdk/tools/dpdk_nic_bind.py --force -u 18:00.1; sudo ./dp/shinjuku" ;;
    *"shinjuku"*) command="cd shinjuku/; sudo ./deps/dpdk/tools/dpdk_nic_bind.py --force -u 18:00.1; sudo ./dp/shinjuku" ;;
    *"psp"*) command="pushd psp/; sudo submodules/dpdk/usertools/dpdk-devbind.py -b igb_uio 18:00.1; ./run.sh" ;;
    *"cfcfs"*) command="pushd psp/; sudo submodules/dpdk/usertools/dpdk-devbind.py -b igb_uio 18:00.1; ./run_cfcfs.sh" ;;
    *) echo "Unknown server type: $server"; exit 1 ;;
  esac

  $SSH "$command" &

}

RANDOMS=(7 365877 374979 853172 908081 227836 64991 493663 174817 73997)

# Function to run tests
run_test() {
  for rate in "${RPS[@]}"; do
    echo "Rate: $rate"
    local per_client_rate=$((rate / N_CLIENTS))

    for i in $(seq 0 $((N_TESTS-1))); do
      stop_server "$POLICY"
      start_server "$POLICY"
      sleep 20

      echo "Starting client with rate: $per_client_rate"
      $(dirname "$0")/run.sh "$BASE_DIR" "$POLICY" "$per_client_rate" "$WK" "${RANDOMS[$i]}" "$i"

      stop_server "$POLICY"
    done
  done

  stop_server "$POLICY"
}

run_test


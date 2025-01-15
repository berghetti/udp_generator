#!/bin/bash
set -e
#
# Usage: ./run_clients.sh afp|psp

source $(dirname $0)/common.sh

N_CLIENTS=1
N_TESTS=1
BASE_DIR=/proj/demeter-PG0/users/fabricio/afp_tests/
TOT_WORKER=14

POLICY=$1

if [[ $# -eq 2 ]]; then
  WK=$2
else
  WK="extreme"
fi

echo $WK

case $WK in
  "shorts") AVG_SERVICE_TIME=$(awk 'BEGIN {print 1.0*1.0 }')  ;; # 100% 1us
  "very_shorts") AVG_SERVICE_TIME=$(awk 'BEGIN {print 0.5.0*1.0 }')  ;; # 100% 0.5us
  "extreme") AVG_SERVICE_TIME=$(awk 'BEGIN {print 0.5*0.995 + 500*0.005 }') ;; #extreme 99.5%/0.5%
  "high") AVG_SERVICE_TIME=$(awk 'BEGIN {print 1*0.5 + 100*0.5 }') ;;   #high 50%/50%
esac

# create RPS[] based on TOT_WORKER and AVG_SERVICE_TIME

if [[ $WK == "shorts" ]]; then
  create_rps_array 1 50 3
elif [[ $WK == "high" ]]; then
  create_rps_array 5 50 10
  create_rps_array 50 100 5
elif [[ $WK == "extreme" ]]; then
  create_rps_array 5 85 5
else
  create_rps_array 5 100 5
fi

#create_rps_array 90 90 5
echo ${RPS[@]}

SSH="ssh 130.127.133.237"

stop_server()
{
  echo "Stoping ${1}"
  $SSH "sudo pkill -2 ${1}; sleep 2; sudo pkill -9 ${1};" &

  wait $!
}

start_server()
{
  echo "Starting ${1}"

  if [[ $1 == "rss"* ]]; then
    $SSH "make run -C afp/apps/fake/ APP=${1}" &
  elif [[ $1 == "afp"*"ci" ]]; then
    $SSH 'sudo afp/deps/dpdk/usertools/dpdk-devbind.py -b igb_uio 18:00.1; make run -C afp/apps/fake/ APP=fake-app-ci' &
  elif [[ $1 == "afp"*"ipi" ]]; then
    $SSH 'sudo afp/deps/dpdk/usertools/dpdk-devbind.py -b igb_uio 18:00.1; make run -C afp/apps/fake/ APP=fake-app-kmod-ipi' &
  elif [[ $1 == *"concord"* ]]; then
    $SSH 'cd concord/concord-shinjuku/; sudo ./deps/dpdk/tools/dpdk_nic_bind.py --force -u 18:00.1; sudo ./dp/shinjuku' &
  elif [[ $1 == *"shinjuku"* ]]; then
    $SSH 'cd shinjuku/; sudo ./deps/dpdk/tools/dpdk_nic_bind.py --force -u 18:00.1; sudo ./dp/shinjuku' &
  elif [[ $1 == *"psp"* ]]; then
    $SSH 'pushd psp/; sudo submodules/dpdk/usertools/dpdk-devbind.py -b igb_uio 18:00.1; ./run.sh' &
  elif [[ $1 == *"cfcfs"* ]]; then
    $SSH 'pushd psp/; sudo submodules/dpdk/usertools/dpdk-devbind.py -b igb_uio 18:00.1; ./run_cfcfs.sh' &
  fi
}

RANDOMS=(7 365877 374979 853172 908081 227836 64991 493663 174817 73997)
run_test()
{
  for rate in ${RPS[@]}; do
    echo "Rate: ${rate}"
    RATE=$((rate / N_CLIENTS)) # per client rate

    for i in $(seq 0 $((N_TESTS-1))); do
      start_server $POLICY; sleep 20

      echo "Starting client"
      $(dirname $0)/run.sh $BASE_DIR $POLICY $RATE $WK ${RANDOMS[$i]} $i

      stop_server $POLICY

      #if [ $? -ne 0 ]; then
      #  echo "Error test"
      #  exit 1
      #fi
    done
  done

  stop_server $POLICY
}

run_test


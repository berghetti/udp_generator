#!/bin/bash
set -e
#
# Usage: ./run_clients.sh afp|psp

source $(dirname $0)/common.sh

N_CLIENTS=1
N_TESTS=1
BASE_DIR=/proj/demeter-PG0/users/fabricio/afp_tests/

WK="extreme"

TOT_WORKER=14

POLICY=$1

case $WK in
  "shorts") AVG_SERVICE_TIME=$(awk 'BEGIN {print 1.0*1.0 }')  ;; # 100% 1us
  "very_shorts") AVG_SERVICE_TIME=$(awk 'BEGIN {print 0.5.0*1.0 }')  ;; # 100% 0.5us
  "extreme") AVG_SERVICE_TIME=$(awk 'BEGIN {print 0.5*0.995 + 500*0.005 }') ;; #extreme 99.5%/0.5%
  "high") AVG_SERVICE_TIME=$(awk 'BEGIN {print 1*0.5 + 100*0.5 }') ;;   #high 50%/50%
esac

# create RPS[] based on TOT_WORKER and AVG_SERVICE_TIME
create_rps_array 2 2 1
#create_rps_array 10 85 5
echo ${RPS[@]}

SSH="ssh 130.127.133.237"

stop_server()
{
  if [[ $1 == *"afp"* ]]; then
    $SSH 'sudo pkill -9 fake-app*;'
  elif [[ $1 == *"concord"* || $1 == *"shinjuku"* ]]; then
    $SSH 'sudo pkill -9 shinjuku;' > /dev/null
  elif [[ $1 == *"psp"* || $1 == *"cfcfs"* ]]; then
    $SSH 'sudo pkill -9 psp-app;' > /dev/null
  fi
}

restart_server()
{
  echo Restating server

  if [[ $1 == "afp"*"ci" ]]; then
    $SSH 'sudo pkill -9 fake-app*; sudo afp/deps/dpdk/usertools/dpdk-devbind.py -b igb_uio 18:00.1; make run -C afp/apps/fake/ APP=fake-app-ci' &
  elif [[ $1 == "afp"*"ipi" ]]; then
    $SSH 'sudo pkill -9 fake-app*; sudo afp/deps/dpdk/usertools/dpdk-devbind.py -b igb_uio 18:00.1; make run -C afp/apps/fake/ APP=fake-app-kmod-ipi' &
  elif [[ $1 == *"concord"* ]]; then
    $SSH 'sudo pkill -9 shinjuku; cd concord/concord-shinjuku/; sudo ./deps/dpdk/tools/dpdk_nic_bind.py --force -u 18:00.1; sudo ./dp/shinjuku' &
  elif [[ $1 == *"shinjuku"* ]]; then
    $SSH 'sudo pkill -9 shinjuku; cd shinjuku/; sudo ./deps/dpdk/tools/dpdk_nic_bind.py --force -u 18:00.1; sudo ./dp/shinjuku' &
  elif [[ $1 == *"psp"* || $1 == *"cfcfs"* ]]; then
    $SSH 'sudo pkill -9 psp-app; pushd psp/; sudo submodules/dpdk/usertools/dpdk-devbind.py -b igb_uio 18:00.1; ./run.sh' &
  fi
}

RANDOMS=(7 365877 374979 853172 908081 227836 64991 493663 174817 73997)
run_test()
{
  for rate in ${RPS[@]}; do
    echo "Rate: ${rate}"
    RATE=$((rate / N_CLIENTS)) # per client rate

    for i in $(seq 0 $((N_TESTS-1))); do
      restart_server $POLICY; sleep 20

      echo "Starting client"
      $(dirname $0)/run.sh $BASE_DIR $POLICY $RATE $WK ${RANDOMS[$i]} $i

      if [ $? -ne 0 ]; then
        echo "Error test"
        exit 1
      fi
      sleep 5
    done
  done

  stop_server $POLICY
}

run_test


#!/bin/bash
set -e
#
# Usage: ./run_clients.sh afp|psp

source $(dirname $0)/../run/common.sh

SV_IP=130.127.134.16

stop_server()
{
  if [[ $1 == *"afp"* ]]; then
    ssh fabricio@$SV_IP 'sudo pkill -9 fake-app;'
  fi

}

restart_server()
{
  echo Restating server

  if [[ $1 == *"afp"* ]]; then
    ssh fabricio@$SV_IP 'sudo pkill -9 fake-app; make run -C afp/apps/fake/' &
  fi

}

N_CLIENTS=1
N_TESTS=1
BASE_DIR='/proj/demeter-PG0/users/fabricio/afp_tests'

WK="high"

TOT_WORKER=14

POLICY=$1

case $WK in
  "shorts") AVG_SERVICE_TIME=$(awk 'BEGIN {print 1.0*1.0 }')  ;; # 100% 1us
  "very_shorts") AVG_SERVICE_TIME=$(awk 'BEGIN {print 0.5.0*1.0 }')  ;; # 100% 0.5us
  "extreme") AVG_SERVICE_TIME=$(awk 'BEGIN {print 0.5*0.995 + 500*0.005 }') ;; #extreme 99.5%/0.5%
  "high") AVG_SERVICE_TIME=$(awk 'BEGIN {print 1*0.5 + 100*0.5 }') ;;   #high 50%/50%
esac

# create RPS[] based on TOT_WORKER and AVG_SERVICE_TIME
create_rps_array 1 6 5
#create_rps_array 10 90 10
#create_rps_array 65 90 5
echo ${RPS[@]}

RANDOMS=(7 365877 374979 853172 908081 227836 64991 493663 174817 73997)

for rate in ${RPS[@]}; do
  echo "Rate: ${rate}"
  RATE=$((rate / N_CLIENTS)) # per client rate

  for i in $(seq 0 $((N_TESTS-1))); do
    #restart_server $POLICY
    #sleep 20

    echo "Starting client"
    $(dirname $0)/run.sh $BASE_DIR $POLICY $RATE $WK ${RANDOMS[$i]} $i

    if [ $? -ne 0 ]; then
      echo "Error test"
      exit 1
    fi
  done
done

stop_server $POLICY


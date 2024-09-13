#!/bin/bash

ROOT_PATH=$(dirname $0)"/.."
source $(ROOT_PATH)/MACHINE_CONFIG

# Default base_dir
BASE_DIR=${BASE_DIR:-/proj/demeter-PG0/users/fabricio/afp_tests/}

# times to run same test
RUNS=${RUNS:-1}

TOT_WORKER=14
AVG_SERVICE_TIME=1

RPS=()

create_rps_array()
{
  start=$1
  end=$2
  step=$3

  echo "Creating RPS array to $TOT_WORKER worker and average service time $AVG_SERVICE_TIME"
  # load percent
  for load in $(seq $start $step $end);
  do
    r=$(awk -v st=$AVG_SERVICE_TIME -v w=$TOT_WORKER -v load=$load 'BEGIN { OFMT="%d"; print 10^6 / st * w * (load / 100)}')
    RPS+=($r)
  done
}

RANDOMS=(7 365877 374979 853172 908081 227836 64991 493663 174817 73997)

CONF_FILE="${ROOT_PATH}/config.cfg"
run_test()
{
  DIR="${BASE_DIR}/tests/${1}"
  DIST=$2
  RATE=$3

  mkdir -p $DIR

  # run each rate RUNS times
  for i in $(seq 0 $((RUNS-1))); do

    RAND=${RANDOMS[$i]}
    if [ -n "$4" ]; then
      RAND=$((RAND+$4))
    fi
    echo $RAND

    date +%H:%M:%S:%N > ${DIR}/start_time$i;
    set -x;
    sudo ${ROOT_PATH}/build/udp-generator \
    -l ${CPUS} -- \
    -d ${DIST} \
    -r ${RATE} \
    -f 256 -s 90 -t 10 -q 1 \
    -c ${CONF_FILE} \
    -o ${DIR}/test$i \
    -x ${RAND} > ${DIR}/stats$i
    set +x


    if [ $? -ne 0 ]; then
      echo "Error start test"
      exit 1
    fi

    sleep 5
  done

}

run_one()
{
  DIR="${BASE_DIR}/tests/${1}"
  DIST=$2
  RATE=$3
  RAND=$4
  TEST_N=$5

  mkdir -p $DIR

  date +%H:%M:%S:%N > ${DIR}/start_time$TEST_N;
  sudo ./build/udp-generator \
  -l $(seq -s , 0 2 28) -- \
  -d ${DIST} \
  -r ${RATE} \
  -f 256 -s 90 -t 10 -q 1 \
  -c ${CONF_FILE} \
  -o ${DIR}/test$TEST_N \
  -x ${RAND} > ${DIR}/stats$TEST_N

  if [ $? -ne 0 ]; then
    echo "Error start test"
    exit 1
  fi
}

set_extreme()
{
  SHORT=500
  LONG=500000
  sed -i '/\[requests_service_time\]/{n;s/\(short\s*=\s*\)[0-9]\+/\1'${SHORT}'/;}' $CONF_FILE
  sed -i '/\[requests_service_time\]/{n;n;s/\(long\s*=\s*\)[0-9]\+/\1'${LONG}'/;}' $CONF_FILE

  SHORT_RATIO=995
  LONG_RATIO=005
  sed -i '/\[requests_ratio\]/{n;s/\(short\s*=\s*\)[0-9]\+/\1'${SHORT_RATIO}'/;}' $CONF_FILE
  sed -i '/\[requests_ratio\]/{n;n;s/\(long\s*=\s*\)[0-9]\+/\1'${LONG_RATIO}'/;}' $CONF_FILE
}

set_high()
{
  SHORT=1000
  LONG=100000
  sed -i '/\[requests_service_time\]/{n;s/\(short\s*=\s*\)[0-9]\+/\1'${SHORT}'/;}' $CONF_FILE
  sed -i '/\[requests_service_time\]/{n;n;s/\(long\s*=\s*\)[0-9]\+/\1'${LONG}'/;}' $CONF_FILE

  SHORT_RATIO=500
  LONG_RATIO=500
  sed -i '/\[requests_ratio\]/{n;s/\(short\s*=\s*\)[0-9]\+/\1'${SHORT_RATIO}'/;}' $CONF_FILE
  sed -i '/\[requests_ratio\]/{n;n;s/\(long\s*=\s*\)[0-9]\+/\1'${LONG_RATIO}'/;}' $CONF_FILE
}

set_only_shorts()
{
  SHORT=1000
  LONG=100000
  sed -i '/\[requests_service_time\]/{n;s/\(short\s*=\s*\)[0-9]\+/\1'${SHORT}'/;}' $CONF_FILE
  sed -i '/\[requests_service_time\]/{n;n;s/\(long\s*=\s*\)[0-9]\+/\1'${LONG}'/;}' $CONF_FILE

  SHORT_RATIO=1000
  LONG_RATIO=0
  sed -i '/\[requests_ratio\]/{n;s/\(short\s*=\s*\)[0-9]\+/\1'${SHORT_RATIO}'/;}' $CONF_FILE
  sed -i '/\[requests_ratio\]/{n;n;s/\(long\s*=\s*\)[0-9]\+/\1'${LONG_RATIO}'/;}' $CONF_FILE
}

set_only_shorts_rate()
{
  SHORT=$1
  LONG=100000000000000000
  sed -i '/\[requests_service_time\]/{n;s/\(short\s*=\s*\)[0-9]\+/\1'${SHORT}'/;}' $CONF_FILE
  sed -i '/\[requests_service_time\]/{n;n;s/\(long\s*=\s*\)[0-9]\+/\1'${LONG}'/;}' $CONF_FILE

  SHORT_RATIO=1000
  LONG_RATIO=0
  sed -i '/\[requests_ratio\]/{n;s/\(short\s*=\s*\)[0-9]\+/\1'${SHORT_RATIO}'/;}' $CONF_FILE
  sed -i '/\[requests_ratio\]/{n;n;s/\(long\s*=\s*\)[0-9]\+/\1'${LONG_RATIO}'/;}' $CONF_FILE
}

set_classification_time()
{
  TIME=$1
  sed -i '/\[classification_time\]/{n;s/\(time\s*=\s*\)[0-9]\+/\1'${TIME}'/;}' $CONF_FILE
}

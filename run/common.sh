#!/bin/bash

ROOT_PATH=$(dirname $0)"/.."
source ${ROOT_PATH}/MACHINE_CONFIG

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
    r=$(awk -v st=$AVG_SERVICE_TIME -v w=$TOT_WORKER -v L=$load 'BEGIN { OFMT="%.0f"; print (10^6) / st * w * (L / 100)}')
    RPS+=($r)
  done
}

CONF_FILE="${ROOT_PATH}/config.cfg"

SHORT=0
LONG=0
SHORT_RATIO=0

run_one()
{
  DIR="${BASE_DIR}/tests/${1}"
  DIST=$2
  RATE=$3
  RAND=$4
  TEST_N=$5

  mkdir -p $DIR
  SHORT_RATIO=$(awk -v ratio=$SHORT_RATIO 'BEGIN {print ratio / 1000}') \

  date +%H:%M:%S:%N > ${DIR}/start_time$TEST_N;

  set -xe
  #~/shinjuku/client/bimodal 192.168.10.50 6789 \
  #  ${RATE} \
  #  ${SHORT} \
  #  ${LONG} \
  #  ${SHORT_RATIO} \
  #  20 \
  #  ${DIR}/test${TEST_N}

  sudo ~/udp_generator/build/udp-generator \
  -a ${NIC_PCI} \
  -l ${CPUS} -- \
  -d ${DIST} \
  -r ${RATE} \
  -f 512 -s 128 -t 60 \
  -c ${CONF_FILE} \
  -o ${DIR}/test$TEST_N \
  -x ${RAND} > ${DIR}/stats$TEST_N
  set +xe
}

set_extreme()
{
  ZERO=0

  SHORT=500
  LONG=500000
  sed -i '/\[requests_service_time\]/{n;s/\(type1\s*=\s*\)[0-9]\+/\1'${SHORT}'/;}' $CONF_FILE
  sed -i '/\[requests_service_time\]/{n;n;s/\(type2\s*=\s*\)[0-9]\+/\1'${LONG}'/;}' $CONF_FILE
  sed -i '/\[requests_service_time\]/{n;n;n;s/\(type3\s*=\s*\)[0-9]\+/\1'${ZERO}'/;}' $CONF_FILE
  sed -i '/\[requests_service_time\]/{n;n;n;n;s/\(type4\s*=\s*\)[0-9]\+/\1'${ZERO}'/;}' $CONF_FILE

  SHORT_RATIO=995
  LONG_RATIO=005
  sed -i '/\[requests_ratio\]/{n;s/\(type1\s*=\s*\)[0-9]\+/\1'${SHORT_RATIO}'/;}' $CONF_FILE
  sed -i '/\[requests_ratio\]/{n;n;s/\(type2\s*=\s*\)[0-9]\+/\1'${LONG_RATIO}'/;}' $CONF_FILE
  sed -i '/\[requests_ratio\]/{n;n;n;s/\(type3\s*=\s*\)[0-9]\+/\1'${ZERO}'/;}' $CONF_FILE
  sed -i '/\[requests_ratio\]/{n;n;n;n;s/\(type4\s*=\s*\)[0-9]\+/\1'${ZERO}'/;}' $CONF_FILE
}

set_high()
{
  ZERO=0

  SHORT=1000
  LONG=100000
  sed -i '/\[requests_service_time\]/{n;s/\(type1\s*=\s*\)[0-9]\+/\1'${SHORT}'/;}' $CONF_FILE
  sed -i '/\[requests_service_time\]/{n;n;s/\(type2\s*=\s*\)[0-9]\+/\1'${LONG}'/;}' $CONF_FILE
  sed -i '/\[requests_service_time\]/{n;n;n;s/\(type3\s*=\s*\)[0-9]\+/\1'${ZERO}'/;}' $CONF_FILE
  sed -i '/\[requests_service_time\]/{n;n;n;n;s/\(type4\s*=\s*\)[0-9]\+/\1'${ZERO}'/;}' $CONF_FILE

  SHORT_RATIO=500
  LONG_RATIO=500
  sed -i '/\[requests_ratio\]/{n;s/\(type1\s*=\s*\)[0-9]\+/\1'${SHORT_RATIO}'/;}' $CONF_FILE
  sed -i '/\[requests_ratio\]/{n;n;s/\(type2\s*=\s*\)[0-9]\+/\1'${LONG_RATIO}'/;}' $CONF_FILE
  sed -i '/\[requests_ratio\]/{n;n;n;s/\(type3\s*=\s*\)[0-9]\+/\1'${ZERO}'/;}' $CONF_FILE
  sed -i '/\[requests_ratio\]/{n;n;n;n;s/\(type4\s*=\s*\)[0-9]\+/\1'${ZERO}'/;}' $CONF_FILE
}

set_zippydb()
{
  ZERO=0

  GET=500
  PUT_DELETE=2500
  SCAN=100000
  sed -i '/\[requests_service_time\]/{n;s/\(type1\s*=\s*\)[0-9]\+/\1'${GET}'/;}' $CONF_FILE
  sed -i '/\[requests_service_time\]/{n;n;s/\(type2\s*=\s*\)[0-9]\+/\1'${PUT_DELETE}'/;}' $CONF_FILE
  sed -i '/\[requests_service_time\]/{n;n;n;s/\(type3\s*=\s*\)[0-9]\+/\1'${SCAN}'/;}' $CONF_FILE
  sed -i '/\[requests_service_time\]/{n;n;n;n;s/\(type4\s*=\s*\)[0-9]\+/\1'${ZERO}'/;}' $CONF_FILE

  GET_RATIO=780
  PUT_DELETE_RATIO=190
  SCAN_RATIO=030
  sed -i '/\[requests_ratio\]/{n;s/\(type1\s*=\s*\)[0-9]\+/\1'${GET_RATIO}'/;}' $CONF_FILE
  sed -i '/\[requests_ratio\]/{n;n;s/\(type2\s*=\s*\)[0-9]\+/\1'${PUT_DELETE_RATIO}'/;}' $CONF_FILE
  sed -i '/\[requests_ratio\]/{n;n;n;s/\(type3\s*=\s*\)[0-9]\+/\1'${SCAN_RATIO}'/;}' $CONF_FILE
  sed -i '/\[requests_ratio\]/{n;n;n;n;s/\(type4\s*=\s*\)[0-9]\+/\1'${ZERO}'/;}' $CONF_FILE
}

set_up2x()
{
  ZERO=0

  GET=500
  MERGE_PUT=5000
  sed -i '/\[requests_service_time\]/{n;s/\(type1\s*=\s*\)[0-9]\+/\1'${GET}'/;}' $CONF_FILE
  sed -i '/\[requests_service_time\]/{n;n;s/\(type2\s*=\s*\)[0-9]\+/\1'${MERGE_PUT}'/;}' $CONF_FILE
  sed -i '/\[requests_service_time\]/{n;n;n;s/\(type3\s*=\s*\)[0-9]\+/\1'${ZERO}'/;}' $CONF_FILE
  sed -i '/\[requests_service_time\]/{n;n;n;n;s/\(type4\s*=\s*\)[0-9]\+/\1'${ZERO}'/;}' $CONF_FILE

  MERGE_PUT_RATIO=925
  GET_RATIO=075
  sed -i '/\[requests_ratio\]/{n;s/\(type1\s*=\s*\)[0-9]\+/\1'${GET_RATIO}'/;}' $CONF_FILE
  sed -i '/\[requests_ratio\]/{n;n;s/\(type2\s*=\s*\)[0-9]\+/\1'${MERGE_PUT_RATIO}'/;}' $CONF_FILE
  sed -i '/\[requests_ratio\]/{n;n;n;s/\(type3\s*=\s*\)[0-9]\+/\1'${ZERO}'/;}' $CONF_FILE
  sed -i '/\[requests_ratio\]/{n;n;n;n;s/\(type4\s*=\s*\)[0-9]\+/\1'${ZERO}'/;}' $CONF_FILE
}

set_only_shorts()
{
  ZERO=0

  SHORT=1000
  LONG=100000
  sed -i '/\[requests_service_time\]/{n;s/\(type1\s*=\s*\)[0-9]\+/\1'${SHORT}'/;}' $CONF_FILE
  sed -i '/\[requests_service_time\]/{n;n;s/\(type2\s*=\s*\)[0-9]\+/\1'${LONG}'/;}' $CONF_FILE
  sed -i '/\[requests_service_time\]/{n;n;n;s/\(type3\s*=\s*\)[0-9]\+/\1'${ZERO}'/;}' $CONF_FILE
  sed -i '/\[requests_service_time\]/{n;n;n;n;s/\(type4\s*=\s*\)[0-9]\+/\1'${ZERO}'/;}' $CONF_FILE

  SHORT_RATIO=1000
  LONG_RATIO=0
  sed -i '/\[requests_ratio\]/{n;s/\(type1\s*=\s*\)[0-9]\+/\1'${SHORT_RATIO}'/;}' $CONF_FILE
  sed -i '/\[requests_ratio\]/{n;n;s/\(type2\s*=\s*\)[0-9]\+/\1'${LONG_RATIO}'/;}' $CONF_FILE
  sed -i '/\[requests_ratio\]/{n;n;n;s/\(type3\s*=\s*\)[0-9]\+/\1'${ZERO}'/;}' $CONF_FILE
  sed -i '/\[requests_ratio\]/{n;n;n;n;s/\(type4\s*=\s*\)[0-9]\+/\1'${ZERO}'/;}' $CONF_FILE
}

set_very_shorts()
{
  ZERO=0
  SHORT=500
  LONG=10000000000
  sed -i '/\[requests_service_time\]/{n;s/\(type1\s*=\s*\)[0-9]\+/\1'${SHORT}'/;}' $CONF_FILE
  sed -i '/\[requests_service_time\]/{n;n;s/\(type2\s*=\s*\)[0-9]\+/\1'${LONG}'/;}' $CONF_FILE
  sed -i '/\[requests_service_time\]/{n;n;n;s/\(type3\s*=\s*\)[0-9]\+/\1'${ZERO}'/;}' $CONF_FILE
  sed -i '/\[requests_service_time\]/{n;n;n;n;s/\(type4\s*=\s*\)[0-9]\+/\1'${ZERO}'/;}' $CONF_FILE

  SHORT_RATIO=1000
  sed -i '/\[requests_ratio\]/{n;s/\(type1\s*=\s*\)[0-9]\+/\1'${SHORT_RATIO}'/;}' $CONF_FILE
  sed -i '/\[requests_ratio\]/{n;n;s/\(type2\s*=\s*\)[0-9]\+/\1'${ZERO}'/;}' $CONF_FILE
  sed -i '/\[requests_ratio\]/{n;n;n;s/\(type3\s*=\s*\)[0-9]\+/\1'${ZERO}'/;}' $CONF_FILE
  sed -i '/\[requests_ratio\]/{n;n;n;n;s/\(type4\s*=\s*\)[0-9]\+/\1'${ZERO}'/;}' $CONF_FILE
}

set_only_shorts_rate()
{
  ZERO=0
  SHORT=$1
  LONG=100000000000000000
  sed -i '/\[requests_service_time\]/{n;s/\(type1\s*=\s*\)[0-9]\+/\1'${SHORT}'/;}' $CONF_FILE
  sed -i '/\[requests_service_time\]/{n;n;s/\(type2\s*=\s*\)[0-9]\+/\1'${LONG}'/;}' $CONF_FILE
  sed -i '/\[requests_service_time\]/{n;n;n;s/\(type3\s*=\s*\)[0-9]\+/\1'${ZERO}'/;}' $CONF_FILE
  sed -i '/\[requests_service_time\]/{n;n;n;n;s/\(type4\s*=\s*\)[0-9]\+/\1'${ZERO}'/;}' $CONF_FILE

  SHORT_RATIO=1000
  sed -i '/\[requests_ratio\]/{n;s/\(type1\s*=\s*\)[0-9]\+/\1'${SHORT_RATIO}'/;}' $CONF_FILE
  sed -i '/\[requests_ratio\]/{n;n;s/\(type2\s*=\s*\)[0-9]\+/\1'${ZERO}'/;}' $CONF_FILE
  sed -i '/\[requests_ratio\]/{n;n;n;s/\(type3\s*=\s*\)[0-9]\+/\1'${ZERO}'/;}' $CONF_FILE
  sed -i '/\[requests_ratio\]/{n;n;n;n;s/\(type4\s*=\s*\)[0-9]\+/\1'${ZERO}'/;}' $CONF_FILE
}

set_classification_time()
{
  TIME=$1
  sed -i '/\[classification_time\]/{n;s/\(time\s*=\s*\)[0-9]\+/\1'${TIME}'/;}' $CONF_FILE
}

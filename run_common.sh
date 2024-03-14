#!/bin/bash

if [ -z $1 ]; then
  #BASE_DIR=$PWD
  BASE_DIR=/proj/demeter-PG0/users/fabricio/afp_tests/
else
  BASE_DIR=${1}
fi

RANDOMS=(7 365877 374979 853172 908081 227836 64991 493663 174817 73997)

# times to run same test
RUNS=1
CONF_FILE="${PWD}/addr.cfg"
run_test()
{
  DIR="${BASE_DIR}/tests/${1}"
  mkdir -p $DIR
  DIST=$2
  RATE=$3

  # run each rate RUNS times
  for i in $(seq 0 $((RUNS-1))); do
    (set -x;
    sudo ./build/udp-generator \
    -l $(seq -s , 0 2 28) -- \
    -d ${DIST} \
    -r ${RATE} \
    -f 256 -s 90 -t 10 -q 1 \
    -c ${CONF_FILE} \
    -o ${DIR}/test$i \
    -x ${RANDOMS[$i]} > ${DIR}/stats$i
    )

    if [ $? -ne 0 ]; then
      echo "Error start test"
      exit 1
    fi

    sleep 5
  done

  # compress result
  #pushd $DIR
  #cd ..
  #tar -caf ${RATE}.tar.bz2 ${RATE}
  #popd
}

set_w1()
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

set_w2()
{
  SHORT=1000
  LONG=100000
  sed -i '/\[requests_service_time\]/{n;s/\(short\s*=\s*\)[0-9]\+/\1'${SHORT}'/;}' $CONF_FILE
  sed -i '/\[requests_service_time\]/{n;n;s/\(long\s*=\s*\)[0-9]\+/\1'${LONG}'/;}' $CONF_FILE

  SHORT_RATIO=990
  LONG_RATIO=010
  sed -i '/\[requests_ratio\]/{n;s/\(short\s*=\s*\)[0-9]\+/\1'${SHORT_RATIO}'/;}' $CONF_FILE
  sed -i '/\[requests_ratio\]/{n;n;s/\(long\s*=\s*\)[0-9]\+/\1'${LONG_RATIO}'/;}' $CONF_FILE
}

set_classification_time()
{
  TIME=$1
  sed -i '/\[classification_time\]/{n;s/\(time\s*=\s*\)[0-9]\+/\1'${TIME}'/;}' $CONF_FILE
}

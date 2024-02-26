#!/bin/bash

if [ -z $1 ]; then
  #BASE_DIR=$PWD
  BASE_DIR=/media/data
else
  #BASE_DIR=${1%/}
  BASE_DIR=${1}
fi

# times to run same test
RUNS=5
CLIENT_DIR="/home/user/udp_generator"
CONF_FILE="${CLIENT_DIR}/addr.cfg"
run_test()
{
  DIR="${BASE_DIR}/tests/${1}"
  mkdir -p $DIR
  DIST=$2
  RATE=$3

  pushd ${CLIENT_DIR}

  cmd_template="\
    sudo ./build/udp-generator -l 1-16 -- \
    -d ${DIST} \
    -r ${RATE} \
    -f 128 -s 256 -t 10 -q 5 \
    -c ${CONF_FILE} \
    -o ${DIR}/test\$i \
    -x \$i \
      > ${DIR}/stats\$i"

  # run each rate RUNS times
  for i in $(seq 0 $((RUNS-1))); do
    cmd="${cmd_template//\$i/${i}}"
    echo $cmd
    eval ${cmd};

    if [ $? -ne 0 ]; then
      echo "Error start test"
      exit 1
    fi

    sleep 5
  done

  popd

  #./process_folder_tests.py "${dir}/"
}

set_1_100_load()
{
  SHORT=1000
  LONG=100000
  sed -i '/\[requests_service_time\]/{n;s/\(short\s*=\s*\)[0-9]\+/\1${SHORT}/;}' $CONF_FILE
  sed -i '/\[requests_service_time\]/{n;s/\(long\s*=\s*\)[0-9]\+/\1${LONG}/;}' $CONF_FILE

  SHORT_RATIO=99
  LONG_RADIO=1
  sed -i '/\[requests_ratio\]/{n;s/\(short\s*=\s*\)[0-9]\+/\1${SHORT_RATIO}/;}' $CONF_FILE
  sed -i '/\[requests_ratio\]/{n;s/\(long\s*=\s*\)[0-9]\+/\1${LONG_RATIO}/;}' $CONF_FILE
}

set_classification_time()
{
  TIME=$1
  sed -i '/\[classification_time\]/{n;s/\(time\s*=\s*\)[0-9]\+/\1'${TIME}'/;}' $CONF_FILE
}

run_1_100()
{
  policy=$1
  load_name='1_100'

  #for dist in 'uniform' 'exponential'; do
  for dist in 'exponential'; do

    for rate in {1000..6000..1000}; do
    #for rate in 4000; do
      rate=$((rate * 1000))
      test_dir="${dist}/${load_name}/${policy}/${rate}"
      echo "Runing ${policy} with rate ${rate}"
      run_test $test_dir $dist $rate
    done

  done
}

run_w1()
{
  policy=$1
  load_name='0.5_100'

  #for dist in 'uniform' 'exponential'; do
  for dist in 'exponential'; do

    for rate in {1000..6000..1000}; do
    #for rate in 1000; do
      rate=$((rate * 1000))
      test_dir="${dist}/${load_name}/${policy}/${rate}"
      echo "Runing ${policy} with rate ${rate}"
      run_test $test_dir $dist $rate
    done

  done
}

set_classification_time 0
#run_w1 "psp-cl0"
#run_w1 "afp-cl0"
run_w1 "rss-cl0"

#set_classification_time 50
#run_w1 "psp-cl50"
#run_w1 "afp-cl50"

#set_classification_time 100
#run_w1 "psp-cl100"
#run_w1 "afp-cl100"


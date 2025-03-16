#!/bin/bash
set -e

# concat all individual clients results and process each policy.

BASE_DIR='/proj/demeter-PG0/users/fabricio/afp_tests'
CLIENT_COUNT=0

concat_policy()
{
  pol=$1
  general_folder=$2

    # for each client rate
    rates=$(ls $pol)
    for rate in $rates; do
      rate_total=$((rate * CLIENT_COUNT))
      dir_test=$general_folder/$rate_total

      if [ -d "$dir_test" ]; then
        echo "Removing old files in $dir_test"
        rm -f "$dir_test"/*
      else
        echo "Creating $dir_test"
        mkdir -p $dir_test
      fi

      # runs using same rate
      runs=$(ls $pol/$rate/test[0-9.] | wc -l)

      for i in $(seq 0 $((runs-1))); do
        # concat requests
        cat client[0-9.]/$general_folder/$rate/test$i > $dir_test/test$i

        # sum reached rps
        offered=$(cat client[0-9.]/$general_folder/$rate/test${i}_rate | awk '$2 ~ /^[0-9]+$/ {sum += $1} END {print sum}')
        reached=$(cat client[0-9.]/$general_folder/$rate/test${i}_rate | awk '$2 ~ /^[0-9]+$/ {sum += $2} END {print sum}')
        tot_tx=$(cat client[0-9.]/$general_folder/$rate/test${i}_rate | awk '$2 ~ /^[0-9]+$/ {sum += $3} END {print sum}')
        tot_rx=$(cat client[0-9.]/$general_folder/$rate/test${i}_rate | awk '$2 ~ /^[0-9]+$/ {sum += $4} END {print sum}')
        dropped=$(cat client[0-9.]/$general_folder/$rate/test${i}_rate | awk '$2 ~ /^[0-9]+$/ {sum += $5} END {print sum}')

        echo -e "offered\treached\ttot_tx\ttot_rx\tdropped\n$offered\t$reached\t$tot_tx\t$tot_rx\t$dropped" > $general_folder/$rate_total/test${i}_rate
      done

    done

    # remove computed policy to save disk space
    rm -rf $pol
}

# join individual client results
concat_results()
{
  pushd $BASE_DIR
  CLIENT_COUNT=$(ls -l ./client[0-9.] | grep -c ^d)
  echo "Client counting: ${CLIENT_COUNT}"

  for pol in client0/tests/*/*/*; do
  #for pol in client0/tests/exponential/extreme/afp-teste; do
    #remove client0/ of pol
    general_folder="${pol//client0\//}"

    echo $general_folder

    concat_policy $pol $general_folder &

  done
  wait
  popd
}

remove_processed_test()
{
  folder=$1
  pushd $folder

  #  policy/rate/test0
  rm */test[0-9]

  popd
}

# shorts, high, extreme
#WK="extreme"
#POL="rss"
WK=$1
POL=$2
TAG=$3

process()
{
  echo "Processing ${WK}"
  for p in {p50,p99,p999}; do
    echo $p
    #$(dirname $0)/process_policys.py "fake_${WK}" $p $BASE_DIR/tests/exponential/${WK}/${POL}/
    #$(dirname $0)/process_policys.py "leveldb_${WK}" $p $BASE_DIR/tests/exponential/${WK}/${POL}/
    $(dirname $0)/process_policys.py "${TAG}_${WK}" $p $BASE_DIR/tests/exponential/${WK}/${POL}/
  done
}

if [ "$2" == concat ]; then
  concat_results
  exit 0
fi

if [ "$3" == clean ]; then
  remove_processed_test $BASE_DIR/tests/exponential/${WK}/${POL}
  exit 0
fi

process



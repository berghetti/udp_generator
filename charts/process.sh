#!/bin/bash

BASE_DIR='/proj/demeter-PG0/users/fabricio/afp_tests'

pushd $BASE_DIR

# join individual client results

CLIENT_COUNT=$(ls -l ./client[0-9.] | grep -c ^d)

# for each client rate
for pol in client0/tests/*/*/*; do
  rate=$(ls $pol)
  rate_total=$((rate * CLIENT_COUNT))

  #remove client0/ of pol
  general_folder="${pol//client0\//}"

  # runs using same rate
  runs=$(ls $pol/$rate/test[0-9.] | wc -l)

  #echo $rate
  #echo $general_folder
  echo "Creating $general_folder"

  mkdir -p $general_folder/$rate_total

  for i in $(seq 0 $((runs-1))); do
    # concat requests
    cat client[0-9.]/$general_folder/$rate/test$i > $general_folder/$rate_total/test$i

    # sum reached rps
    offered=$(cat client[0-9.]/$general_folder/$rate/test${i}_rate | awk '$2 ~ /^[0-9]+$/ {sum += $1} END {print sum}')
    reached=$(cat client[0-9.]/$general_folder/$rate/test${i}_rate | awk '$2 ~ /^[0-9]+$/ {sum += $2} END {print sum}')

    echo -e "offered\treached\n$offered\t$reached" > $general_folder/$rate_total/test${i}_rate

  done

done

popd

# finally compute tail latency for each policy
for pol in $BASE_DIR/tests/*/*/*; do

  #echo $pol
  ./process.py 'wk2' p999 $pol

done

#./process.py 'wk1' p999 $BASE_DIR/tests/exponential/0.5_500/*



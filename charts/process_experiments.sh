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
      echo "Creating $general_folder/$rate_total"

      mkdir -p $general_folder/$rate_total

      # runs using same rate
      runs=$(ls $pol/$rate/test[0-9.] | wc -l)

      for i in $(seq 0 $((runs-1))); do
        # concat requests
        cat client[0-9.]/$general_folder/$rate/test$i > $general_folder/$rate_total/test$i

        # sum reached rps
        offered=$(cat client[0-9.]/$general_folder/$rate/test${i}_rate | awk '$2 ~ /^[0-9]+$/ {sum += $1} END {print sum}')
        reached=$(cat client[0-9.]/$general_folder/$rate/test${i}_rate | awk '$2 ~ /^[0-9]+$/ {sum += $2} END {print sum}')
        tot_tx=$(cat client[0-9.]/$general_folder/$rate/test${i}_rate | awk '$2 ~ /^[0-9]+$/ {sum += $3} END {print sum}')
        tot_rx=$(cat client[0-9.]/$general_folder/$rate/test${i}_rate | awk '$2 ~ /^[0-9]+$/ {sum += $4} END {print sum}')
        dropped=$(cat client[0-9.]/$general_folder/$rate/test${i}_rate | awk '$2 ~ /^[0-9]+$/ {sum += $5} END {print sum}')

        echo -e "offered\treached\ttot_tx\ttot_rx\tdropped\n$offered\t$reached\t$tot_tx\t$tot_rx\t$dropped" > $general_folder/$rate_total/test${i}_rate

      done
    done
}

# join individual client results
concat_results()
{
  pushd $BASE_DIR
  CLIENT_COUNT=$(ls -l ./client[0-9.] | grep -c ^d)
  echo "Client counting: ${CLIENT_COUNT}"

  for pol in client0/tests/*/*/*; do
    #remove client0/ of pol
    general_folder="${pol//client0\//}"

    echo $general_folder

    concat_policy $pol $general_folder &

  done
  wait
  popd
}

if [ "$1" == concat ]; then
  concat_results
fi

$(dirname $0)/process_policys.py 'shorts_1' p999 $BASE_DIR/tests/exponential/shorts_1/*
#$(dirname $0)/process_policys.py 'shorts_1' p999 $BASE_DIR/tests/exponential/shorts_1/afp-cfcfs


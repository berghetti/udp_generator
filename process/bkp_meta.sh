#!/bin/bash

DATE=$(date +%F)
BASE_DST=~/afp-experiments

for meta in $(ls *meta.dat*); do
  APP_NAME=$(echo $meta | cut -d '_' -f 1)
  LOAD_NAME=$(echo $meta | cut -d '_' -f 2)

  DIR=$BASE_DST/$LOAD_NAME/$APP_NAME/$DATE

  mkdir -p $DIR
  cp $meta $DIR
done

pushd $BASE_DST
git pull
git add .
git commit -m "added new test"
git push
popd

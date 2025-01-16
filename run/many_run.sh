
process_test()
{
  pushd ../process
  ./process_experiments.sh $1 $2 && sudo ./process_experiments.sh $1 $2 clean
  popd
}

#for wk in high; do
#  for pol in cfcfs; do
#    echo $wk $pol
#    ./run_test.sh $pol $wk
#    process_test $wk
#  done
#done

#POLICYS=(
#  "rss"
#  "rss-ci"
#  "rss-ws"
#  "rss-ws-ci"
#  "rss-ws-ci-wq"
#  "rss-ws-ci-wq-cp"
#  "rss-ws-ci-wq-cp-feed-qa"
#  "rss-ws-ci-wq-cp-feed-qa-tw"
#)

POLICYS=(
  "rss-ws-ci-wq-q2"
)


for wk in high; do
  #for pol in ${POLICYS[@]:2}; do
  for pol in ${POLICYS[@]}; do
    echo $wk $pol
    ./run_test.sh $pol $wk
    process_test $wk $pol
  done
done

for wk in extreme; do
  for pol in ${POLICYS[@]}; do
    echo $wk $pol
    ./run_test.sh $pol $wk
    process_test $wk $pol
  done
done

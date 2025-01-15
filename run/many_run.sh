
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

POLICYS=("rss-ci" "rss-ws" "rss-ws-ci" "rss-ws-ci-wq" "rss-ws-ci-wq-cp"
"rss-ws-ci-wq-cp-feed+qa" "rss-ws-ci-wq-cp-feed+qa+tw")


for wk in high; do
  for pol in ${POLICYS[@]}; do
    echo $wk $pol
    ./run_test.sh $pol $wk
    process_test $wk $pol
  done
done

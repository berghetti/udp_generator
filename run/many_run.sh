
process_test()
{
  pushd ../process
  ./process_experiments.sh $1 && sudo ./process_experiments.sh clean
  popd
}

for wk in {shorts,high,extreme}; do
  for pol in {afp-ipi,afp-ci,psp,concord,shinjuku}; do
    echo $wk $pol
    ./run_test.sh $pol $wk
    process_test $wk
  done
done


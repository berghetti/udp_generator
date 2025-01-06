
process_test()
{
  pushd ../process
  ./process_experiments.sh && sudo ./process_experiments.sh clean
  popd
}

./run_test.sh afp-kmod-ipi
process_test

./run_test.sh afp-ci
process_test

./run_test.sh psp
process_test

./run_test.sh concord
process_test

./run_test.sh shinjuku
process_test

#!/bin/bash

# ensure nothing is running on server
reset_server()
{
./shremote.py prepare_machines.yml prepare_machines -- --server-generic --cmd "sudo pkill -2 helloworld"
./shremote.py prepare_machines.yml prepare_machines -- --server-generic --cmd "sudo pkill -2 psp-app"
}

start_clients()
{
  echo "Running ${1}"
  ./run_clients.sh $1
  reset_server
}

./shremote.py prepare_machines.yml prepare_machines -- --server-generic --cmd "pushd afp && CFLAGS+=-DWORKSTEALING make -B"
./shremote.py prepare_machines.yml start_afp -- --server-generic --cmd "pushd afp && ./run.sh" &
sleep 5
sudo kill -9 $!
start_clients "afp-ws"

./shremote.py prepare_machines.yml prepare_machines -- --server-generic --cmd "pushd afp && make -B"
./shremote.py prepare_machines.yml start_afp -- --server-generic --cmd "pushd afp && ./run.sh" &
sleep 5
sudo kill -9 $!
Policy="afp"
start_clients "afp"

#./shremote.py prepare_machines.yml start_psp -- --server-generic --cmd "pushd psp && bash run_psp.txt" &
#sleep 5
#sudo kill -9 $!
#start_clients "psp"

pushd ../charts
./process.sh


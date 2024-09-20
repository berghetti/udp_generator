
## Install requirements
bash ./setup.sh

## Edit address of remote clients and ensure than this server can login using ssh on clients
Edit `hosts.yml`

## Test

This not should show any error.
`./clients-generic.sh "echo oi"`

## Prepare clients machines

Part1 (install DPDK, adjusts clients IPs, set boot parameters and reboot):
`./prepare_clients.sh`

Part2: (reserve hugepages, bind NIC and disable CPU frequency turbo)
`./clients-generic.sh "pushd udp_generator && ./setup.sh"`

## Run a workload using multiple clients

Edit run_clients
`./run_clients.sh afp`

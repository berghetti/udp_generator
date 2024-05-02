# UDP_generator

Tested using DPDK 23.11 and ubuntu 20.04

## Building

```bash
git clone https://github.com/carvalhof/udp_generator
cd udp_generator
./install_prerequisites.sh
./install_dpdk.sh
make
```

## Running

```bash
./setup.sh # once
sudo ./build/udp-generator -a 41:00.0 -n 4 -c 0xff -- -d $DISTRIBUTION -r $RATE -f $FLOWS -s $SIZE -t $DURATION -q $QUEUES -c $ADDR_FILE -o $OUTPUT_FILE -x $SEED
```

> **Example**

```bash
sudo ./build/udp-generator -a 41:00.0 -n 4 -c 0xff -- -d exponential -r 100000 -f 1 -s 128 -t 10 -q 1 -c addr.cfg -o output.dat -x 7
```

### Parameters

- `$DISTRIBUTION` : interarrival distribution (_e.g.,_ uniform or exponential)
- `$RATE` : packet rate in _pps_
- `$FLOWS` : number of flows
- `$SIZE` : packet size in _bytes_
- `$DURATION` : duration of execution in _seconds_ (we double for warming up)
- `$QUEUES` : number of RX/TX queues
- `$ADDR_FILE` : name of address file (_e.g.,_ 'addr.cfg')
- `$OUTPUT_FILE` : name of output file containg the latency for each packet
- `$SEED`: seed to random number generator. If not set, an internal value is used


### _address file structure_

```
[ethernet]
src = 0c:42:a1:8c:db:1c
dst = 0c:42:a1:8c:dc:54

[ipv4]
src = 192.168.1.2
dst = 192.168.1.1

[udp]
dst = 12345

[server]
nr_servers = 1
```

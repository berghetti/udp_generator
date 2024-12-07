# UDP_generator

This client is used to test AFP.

Tested using DPDK 23.11 and ubuntu 20.04 and 18.04

## Building

```bash
git clone -b afp_changes https://github.com/berghetti/udp_generator.git
cd udp_generator
./install_requirements.sh; ./install_dpdk.sh; make
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
src = 00:11:22:33:44:55
dst = 3C:FD:FE:55:20:FA

[ipv4]
src = 192.168.10.1
dst = 192.168.10.10

[udp]
dst = 6789

;request service time in nanoseconds
[requests_service_time]
short = 1000
long = 100000

[requests_ratio]
short = 1000
long = 0

;request classification time in nanosseconds
[classification_time]
time = 0
```

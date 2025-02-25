#ifndef _GNU_SOURCE
#define _GNU_SOURCE
#endif

#include <errno.h>
#include <math.h>
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>

#include "dpdk_util.h"
#include "udp_util.h"
#include "util.h"

// Application parameters
uint64_t rate;
uint64_t duration;
uint64_t nr_flows;
uint16_t nr_servers;
uint32_t min_lcores;
uint32_t frame_size;
uint32_t udp_payload_size;

// General variables
uint64_t TICKS_PER_US;
uint16_t *flow_indexes_array;
uint64_t *interarrival_array;
config_request_type_t cfg_request_types[TOTAL_RTYPES];
request_type_t *request_types;
uint64_t classification_time;

// Heap and DPDK allocated
node_t *incoming_array;
uint64_t incoming_idx;
struct rte_mempool *pktmbuf_pool_tx;
struct rte_mempool *pktmbuf_pool_rx;
control_block_t *control_blocks;

struct queue_rps q_rps[MAX_QUEUES];

// Internal threads variables
volatile uint8_t quit_rx = 0;
volatile uint8_t quit_tx = 0;
volatile uint32_t ack_dup = 0;
volatile uint32_t ack_empty = 0;
volatile uint8_t quit_rx_ring = 0;
volatile uint64_t nr_never_sent = 0;
uint16_t portid = 0;
lcore_param lcore_params[RTE_MAX_LCORE];
struct rte_ring *rx_ring;

// seed
uint64_t seed = DEFAULT_SEED;

// Connection variables
uint16_t dst_udp_port;
uint32_t dst_ipv4_addr;
uint32_t src_ipv4_addr;
struct rte_ether_addr dst_eth_addr;
struct rte_ether_addr src_eth_addr;

// Process the incoming UDP packet
int process_rx_pkt(struct rte_mbuf *pkt, node_t *incoming,
                   uint64_t *incoming_idx) {
  // process only UDP packets
  struct rte_ipv4_hdr *ipv4_hdr = rte_pktmbuf_mtod_offset(
      pkt, struct rte_ipv4_hdr *, sizeof(struct rte_ether_hdr));
  if (unlikely(ipv4_hdr->next_proto_id != IPPROTO_UDP)) {
    return 0;
  }

  // get UDP header
  struct rte_udp_hdr *udp_hdr = rte_pktmbuf_mtod_offset(
      pkt, struct rte_udp_hdr *,
      sizeof(struct rte_ether_hdr) + (ipv4_hdr->version_ihl & 0x0f) * 4);

  // get UDP payload size
  uint32_t packet_data_size = rte_be_to_cpu_16(ipv4_hdr->total_length) -
                              ((ipv4_hdr->version_ihl & 0x0f) * 4) -
                              sizeof(struct rte_udp_hdr);

  // do not process empty packets
  if (unlikely(packet_data_size == 0)) {
    return 0;
  }

  node_t *node = &incoming[(*incoming_idx)++];

  // obtain both timestamp from the packet
  uint64_t *payload =
      (uint64_t *)(((uint8_t *)udp_hdr) + (sizeof(struct rte_udp_hdr)));

  node->timestamp_tx = payload[SEND_TIME];
  node->timestamp_rx = payload[RECV_TIME];
  node->type = payload[TYPE];
  node->service_time = payload[SERVICE_TIME];

  // node->flow_id = payload[FLOW_ID];
  // node->rx_time = payload[RX_TIME];
  // node->app_recv_time = payload[APP_RECV_TIME];
  // node->app_send_time = payload[APP_SEND_TIME];
  // node->tx_time = payload[TX_TIME];
  // node->worker_rx = payload[WORKER_RX];
  // node->worker_tx = payload[WORKER_TX];
  // node->interrupt_count = payload[INTERRUPT_COUNT];

  return 1;
}

// RX processing
static int lcore_rx_ring(void *arg) {
  uint16_t nb_rx;
  struct rte_mbuf *pkts[BURST_SIZE];

  incoming_idx = 0;

  while (!quit_rx_ring) {
    // retrieve packets from the RX core
    nb_rx = rte_ring_sc_dequeue_burst(rx_ring, (void **)pkts, BURST_SIZE, NULL);
    for (int i = 0; i < nb_rx; i++) {
      rte_prefetch_non_temporal(rte_pktmbuf_mtod(pkts[i], void *));
      // process the incoming packet
      process_rx_pkt(pkts[i], incoming_array, &incoming_idx);
      // free the packet
      rte_pktmbuf_free(pkts[i]);
    }
  }

  // process all remaining packets that are in the RX ring (not from the NIC)
  do {
    nb_rx = rte_ring_sc_dequeue_burst(rx_ring, (void **)pkts, BURST_SIZE, NULL);
    for (int i = 0; i < nb_rx; i++) {
      rte_prefetch_non_temporal(rte_pktmbuf_mtod(pkts[i], void *));
      // process the incoming packet
      process_rx_pkt(pkts[i], incoming_array, &incoming_idx);
      // free the packet
      rte_pktmbuf_free(pkts[i]);
    }
  } while (nb_rx != 0);

  return 0;
}

// Main RX processing
static int lcore_rx(void *arg) {
  lcore_param *rx_conf = (lcore_param *)arg;
  uint16_t portid = rx_conf->portid;
  uint8_t qid = rx_conf->qid;

  uint64_t now;
  uint16_t nb_rx;
  struct rte_mbuf *pkts[BURST_SIZE];

  uint64_t tot_nb_rx = 0;
  uint64_t start = 0;

  start = rte_rdtsc();

  while (!quit_rx) {
    // retrieve the packets from the NIC
    nb_rx = rte_eth_rx_burst(portid, qid, pkts, BURST_SIZE);
    if (!nb_rx)
      continue;

    tot_nb_rx += nb_rx;

    // retrive the current timestamp
    now = rte_rdtsc();
    for (int i = 0; i < nb_rx; i++) {
      // fill the timestamp into packet payload
      fill_payload_pkt(pkts[i], RECV_TIME, now);
    }

    if (rte_ring_sp_enqueue_burst(rx_ring, (void *const *)pkts, nb_rx, NULL) !=
        nb_rx) {
      rte_exit(EXIT_FAILURE,
               "Cannot enqueue the packet to the RX thread: %s.\n",
               rte_strerror(errno));
    }
  }

  q_rps[qid].rps_reached =
      tot_nb_rx / ((rte_rdtsc() - start) / rte_get_timer_hz());

  q_rps[qid].tot_rx = tot_nb_rx;

  return 0;
}

// Main TX processing
static int lcore_tx(void *arg) {
  lcore_param *tx_conf = (lcore_param *)arg;
  uint16_t portid = tx_conf->portid;
  uint8_t qid = tx_conf->qid;
  uint64_t nr_elements = rate * duration;
  request_type_t *rtype = request_types;

  uint16_t nb_tx;
  struct rte_mbuf *pkt;
  uint64_t next_tsc;
  uint64_t start;

  uint64_t tot_nb_tx = 0;

  start = next_tsc = rte_rdtsc();
  for (uint64_t i = 0; i < nr_elements && !quit_tx; i++) {
    // update the counter
    next_tsc += interarrival_array[i];
    // unable to keep up with the requested rate
    if (unlikely(rte_rdtsc() > (next_tsc + 5 * TICKS_PER_US))) {
      // count this batch as dropped
      nr_never_sent++;
      // next_tsc += (interarrival_array[i] + TICKS_PER_US);
      continue;
    }

    // choose the flow to send
    uint16_t flow_id = flow_indexes_array[i];

    // generate packets
    pkt = rte_pktmbuf_alloc(pktmbuf_pool_tx);
    // fill the packet with the flow information
    fill_udp_packet(flow_id, pkt);

    // fill the payload to gather server information
    // fill_payload_pkt(pkts[nb_pkts], FLOW_ID, flow_id);

    fill_payload_pkt(pkt, SEND_TIME, next_tsc);

    uint8_t type = get_type(rtype[i]);

    fill_payload_pkt(pkt, TYPE, type);
    fill_payload_pkt(pkt, SERVICE_TIME,
                     cfg_request_types[type - 1].service_time);
#ifdef DB
    fill_payload_pkt(pkt, DB_KEY, rtype[i].key);
#endif

#ifdef RESP

    fill_payload_resp_request(pkt, RESP_REQUEST, rtype[i].resp_buff,
                              strlen(rtype[i].resp_buff) + 1);

#endif

    // sleep for while
    while (rte_rdtsc() < next_tsc)
      ;

    // send the batch
    nb_tx = rte_eth_tx_burst(portid, qid, &pkt, 1);
    if (unlikely(nb_tx != 1)) {
      rte_exit(EXIT_FAILURE, "Cannot send the target packets.\n");
    }

    tot_nb_tx++;
  }

  q_rps[qid].rps_offered =
      tot_nb_tx / ((rte_rdtsc() - start) / rte_get_timer_hz());

  q_rps[qid].tot_tx = tot_nb_tx;

  return 0;
}

// main function
int main(int argc, char **argv) {
  // init EAL
  int ret = rte_eal_init(argc, argv);
  if (ret < 0) {
    rte_exit(EXIT_FAILURE, "Invalid EAL parameters\n");
  }

  argc -= ret;
  argv += ret;

  // parse application arguments (after the EAL ones)
  ret = app_parse_args(argc, argv);
  if (ret < 0) {
    rte_exit(EXIT_FAILURE, "Invalid arguments\n");
  }

  // initialize DPDK
  init_DPDK(portid, 1);

  //// allocate nodes for incoming packets
  create_incoming_array();

  //// create flow indexes array
  create_flow_indexes_array();

  // create interarrival array
  create_interarrival_array();

  create_request_types_array();

  // initialize the control blocks
  init_blocks();

  // create the DPDK rings for RX threads
  create_dpdk_rings();

  // start RX and TX threads
  uint32_t id_lcore = rte_lcore_id();
  for (unsigned i = 0; i < 1; i++) {
    lcore_params[i].portid = portid;
    lcore_params[i].qid = i;

    id_lcore = rte_get_next_lcore(id_lcore, 1, 1);
    rte_eal_remote_launch(lcore_rx_ring, (void *)&lcore_params[i], id_lcore);

    id_lcore = rte_get_next_lcore(id_lcore, 1, 1);
    rte_eal_remote_launch(lcore_rx, (void *)&lcore_params[i], id_lcore);

    id_lcore = rte_get_next_lcore(id_lcore, 1, 1);
    rte_eal_remote_launch(lcore_tx, (void *)&lcore_params[i], id_lcore);
  }

  // wait for duration parameter
  wait_timeout();

  // wait for RX/TX threads
  uint32_t lcore_id;
  RTE_LCORE_FOREACH_WORKER(lcore_id) {
    if (rte_eal_wait_lcore(lcore_id) < 0)
      return -1;
  }

  // print stats
  print_stats_output();

  // print DPDK stats
  print_dpdk_stats(portid);

  // clean up
  clean_heap();
  clean_hugepages();

  return 0;
}

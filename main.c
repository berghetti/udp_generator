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
uint64_t nr_queues;
uint16_t nr_servers;
uint32_t min_lcores;
uint32_t frame_size;
uint32_t udp_payload_size;

// General variables
uint64_t TICKS_PER_US;
uint16_t **flow_indexes_array;
uint64_t **interarrival_array;
request_type_t cfg_request_types[TOTAL_RTYPES];
request_type_t **request_types;
uint64_t classification_time;

// Heap and DPDK allocated
node_t **incoming_array;
uint64_t *incoming_idx_array;
struct rte_mempool *pktmbuf_pool;
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
struct rte_ring *rx_rings[RTE_MAX_LCORE];

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
  // uint32_t packet_data_size = rte_be_to_cpu_16(ipv4_hdr->total_length) -
  //                            ((ipv4_hdr->version_ihl & 0x0f) * 4) -
  //                            sizeof(struct rte_udp_hdr);

  //// do not process empty packets
  // if (unlikely(packet_data_size == 0)) {
  //  return 0;
  //}

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

// Start the client to configure the rte_flow properly
void start_client(uint16_t portid) {
  for (int i = 0; i < nr_flows; i++) {
    // insert the rte_flow in the NIC to retrieve the flow id for incoming
    // packets of this flow
    insert_flow(portid, i);
  }
}

// RX processing
static int lcore_rx_ring(void *arg) {
  lcore_param *rx_conf = (lcore_param *)arg;
  uint8_t qid = rx_conf->qid;

  uint16_t nb_rx;
  uint64_t *incoming_idx = &incoming_idx_array[qid];
  node_t *incoming = incoming_array[qid];
  struct rte_mbuf *pkts[BURST_SIZE];
  struct rte_ring *rx_ring = rx_rings[qid];

  while (!quit_rx_ring) {
    // retrieve packets from the RX core
    nb_rx = rte_ring_sc_dequeue_burst(rx_ring, (void **)pkts, BURST_SIZE, NULL);
    for (int i = 0; i < nb_rx; i++) {
      rte_prefetch_non_temporal(rte_pktmbuf_mtod(pkts[i], void *));
      // process the incoming packet
      process_rx_pkt(pkts[i], incoming, incoming_idx);
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
      process_rx_pkt(pkts[i], incoming, incoming_idx);
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
  struct rte_ring *rx_ring = rx_rings[qid];

  uint64_t tot_nb_rx = 0;
  uint64_t start = 0;

  while (!quit_rx) {
    nb_rx = rte_eth_rx_burst(portid, qid, pkts, BURST_SIZE);
    if (nb_rx) {
      // only set start time when first pkt arrive
      start = rte_get_tsc_cycles();
      goto rx_path;
    }
  }

  while (!quit_rx) {
    // retrieve the packets from the NIC
    nb_rx = rte_eth_rx_burst(portid, qid, pkts, BURST_SIZE);

  rx_path:
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
      tot_nb_rx / ((rte_get_tsc_cycles() - start) / rte_get_timer_hz());

  q_rps[qid].tot_rx = tot_nb_rx;

  return 0;
}

// Main TX processing
static int lcore_tx(void *arg) {
  lcore_param *tx_conf = (lcore_param *)arg;
  uint16_t portid = tx_conf->portid;
  uint8_t qid = tx_conf->qid;
  uint64_t nr_elements = tx_conf->nr_elements;

  uint64_t i = 0;
  uint16_t n = 1;
  uint16_t nb_tx;
  uint16_t nb_pkts = 0;
  struct rte_mbuf *pkts[BURST_SIZE];
  uint16_t *flow_indexes = flow_indexes_array[qid];
  uint64_t *interarrival_gap = interarrival_array[qid];
  request_type_t *rtype = request_types[qid];

  uint64_t next_tsc = rte_rdtsc() + interarrival_gap[i++];

  uint64_t start = rte_get_tsc_cycles();
  uint64_t tot_nb_tx = 0;

  while (!quit_tx) {
    // reach the limit
    if (unlikely(i >= nr_elements)) {
      break;
    }

    // choose the flow to send
    uint16_t flow_id = flow_indexes[i];

    // generate packets
    for (; nb_pkts < n; nb_pkts++) {
      pkts[nb_pkts] = rte_pktmbuf_alloc(pktmbuf_pool);
      // fill the packet with the flow information
      fill_udp_packet(flow_id, pkts[nb_pkts]);

      // fill the payload to gather server information
      // fill_payload_pkt(pkts[nb_pkts], FLOW_ID, flow_id);

      fill_payload_pkt(pkts[nb_pkts], SEND_TIME, next_tsc);

      fill_payload_pkt(pkts[nb_pkts], TYPE, rtype[i].type);
      fill_payload_pkt(pkts[nb_pkts], SERVICE_TIME, rtype[i].service_time);
      fill_payload_pkt(pkts[nb_pkts], CLASSIFICATION_TIME, classification_time);
    }

    // unable to keep up with the requested rate
    if (unlikely(rte_rdtsc() > (next_tsc + 5 * TICKS_PER_US))) {
      // count this batch as dropped
      nr_never_sent++;
      next_tsc += interarrival_gap[i++];
      continue;
    }

    // sleep for while
    while (rte_rdtsc() < next_tsc)
      ;

    // send the batch
    nb_tx = rte_eth_tx_burst(portid, qid, pkts, nb_pkts);
    if (unlikely(nb_tx != nb_pkts)) {
      rte_exit(EXIT_FAILURE, "Cannot send the target packets.\n");
    }

    tot_nb_tx += nb_pkts;

    // update the counter
    nb_pkts = 0;
    next_tsc += interarrival_gap[i++];
  }

  q_rps[qid].rps_offered =
      tot_nb_tx / ((rte_get_tsc_cycles() - start) / rte_get_timer_hz());

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
  init_DPDK(portid, nr_queues);

  // allocate nodes for incoming packets
  allocate_incoming_nodes();

  // create flow indexes array
  create_flow_indexes_array();

  // create interarrival array
  create_interarrival_array();

  create_request_types_array();

  // initialize the control blocks
  init_blocks();

  // start client (3-way handshake for each flow)
  start_client(portid);

  // create the DPDK rings for RX threads
  create_dpdk_rings();

  // start RX and TX threads
  uint32_t id_lcore = rte_lcore_id();
  for (int i = 0; i < nr_queues; i++) {
    lcore_params[i].portid = portid;
    lcore_params[i].qid = i;
    lcore_params[i].nr_elements = (rate / nr_queues) * 2 * duration;

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
    if (rte_eal_wait_lcore(lcore_id) < 0) {
      return -1;
    }
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

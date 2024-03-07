#ifndef __UTIL_H__
#define __UTIL_H__

#include <math.h>
#include <stdio.h>
#include <stdint.h>
#include <getopt.h>
#include <string.h>

#include <rte_ip.h>
#include <rte_eal.h>
#include <rte_log.h>
#include <rte_udp.h>
#include <rte_flow.h>
#include <rte_mbuf.h>
#include <rte_ring.h>
#include <rte_ether.h>
#include <rte_atomic.h>
#include <rte_ethdev.h>
#include <rte_malloc.h>
#include <rte_cfgfile.h>
#include <rte_mempool.h>

// Constants
#define EPSILON						0.00001
#define MAXSTRLEN					128
#define UNIFORM_VALUE				0
#define EXPONENTIAL_VALUE			1
#define IPV4_ADDR(a, b, c, d)		(((d & 0xff) << 24) | ((c & 0xff) << 16) | ((b & 0xff) << 8) | (a & 0xff))

typedef struct lcore_parameters {
	uint8_t qid;
	uint16_t portid;
	uint64_t nr_elements;
} __rte_cache_aligned lcore_param;

typedef struct timestamp_node_t {
	uint64_t flow_id;
	//uint64_t thread_id;
	//uint64_t ack_dup;
	//uint64_t ack_empty;
	uint64_t timestamp_rx;
	uint64_t timestamp_tx;
	uint64_t nr_never_sent;

  uint32_t type;
  uint32_t service_time;

  // server times
  uint64_t rx_time, app_recv_time, app_send_time, tx_time, worker_rx, worker_tx, interrupt_count;
} node_t;

enum rtype
{
  SHORT = 0,
  LONG,

  TOTAL_RTYPES
};

typedef struct request_type
{
  enum rtype type;
  uint32_t ratio;
  uint64_t service_time; // in nanoseconds
} request_type_t;

extern uint64_t rate;
extern uint16_t portid;
extern uint64_t duration;
extern uint64_t nr_flows;
extern uint64_t nr_queues;
extern uint16_t nr_servers;
extern uint32_t frame_size;
extern uint32_t min_lcores;
extern uint32_t udp_payload_size;

extern request_type_t cfg_request_types[TOTAL_RTYPES];
extern request_type_t **request_types;

extern uint64_t TICKS_PER_US;
extern uint16_t **flow_indexes_array;
extern uint64_t **interarrival_array;
extern uint64_t classification_time;

extern uint16_t dst_udp_port;
extern uint32_t dst_ipv4_addr;
extern uint32_t src_ipv4_addr;
extern struct rte_ether_addr dst_eth_addr;
extern struct rte_ether_addr src_eth_addr;

extern volatile uint8_t quit_rx;
extern volatile uint8_t quit_tx;
extern volatile uint8_t quit_rx_ring;

extern node_t **incoming_array;
extern uint64_t *incoming_idx_array;

extern uint64_t seed;

void clean_heap();
void wait_timeout();
void print_dpdk_stats();
void print_stats_output();
void process_config_file();
double sample(double lambda);
void allocate_incoming_nodes();
void create_interarrival_array();
void create_flow_indexes_array();
void create_request_types_array();
int app_parse_args(int argc, char **argv);

enum payload_item
{
  FLOW_ID = 0,
  SEND_TIME,
  RECV_TIME,
  TYPE, // 3
  SERVICE_TIME,
  CLASSIFICATION_TIME,

  /* server times */
  //RX_TIME, // 6
  //APP_RECV_TIME,
  //APP_SEND_TIME,
  //TX_TIME,
  //WORKER_RX,
  //WORKER_TX,
  //INTERRUPT_COUNT,

  PAYLOAD_TOTAL_ITEMS
};

void fill_payload_pkt(struct rte_mbuf *pkt, enum payload_item item, uint64_t value);

#endif // __UTIL_H__

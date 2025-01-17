#ifndef __UDP_UTIL_H__
#define __UDP_UTIL_H__

#include <stdint.h>

#include <rte_atomic.h>
#include <rte_eal.h>
#include <rte_ethdev.h>
#include <rte_ether.h>
#include <rte_flow.h>
#include <rte_ip.h>
#include <rte_log.h>
#include <rte_malloc.h>
#include <rte_mbuf.h>
#include <rte_mempool.h>
#include <rte_ring.h>
#include <rte_udp.h>

// Control Block
typedef struct control_block_s
{
  // used only by the TX
  uint32_t src_addr;
  uint32_t dst_addr;
  uint16_t src_port;
  // uint16_t dst_port;
} __rte_cache_aligned control_block_t;

#define ETH_IPV4_TYPE_NETWORK 0x0008

extern uint16_t dst_udp_port;
extern uint32_t dst_ipv4_addr;
extern uint32_t src_ipv4_addr;
extern struct rte_ether_addr dst_eth_addr;
extern struct rte_ether_addr src_eth_addr;

extern uint64_t nr_flows;
extern uint16_t nr_servers;
extern uint32_t frame_size;
extern uint32_t udp_payload_size;
extern struct rte_mempool *pktmbuf_pool_tx;
extern struct rte_mempool *pktmbuf_pool_rx;
extern control_block_t *control_blocks;

void init_blocks ();
void fill_udp_packet (uint16_t i, struct rte_mbuf *pkt);
void fill_udp_payload (uint8_t *payload, uint32_t length);

#endif // __UDP_UTIL_H__

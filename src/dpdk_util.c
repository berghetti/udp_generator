#include "dpdk_util.h"

extern uint64_t seed;

// Initialize DPDK configuration
void
init_DPDK (uint16_t portid, uint64_t nr_queues)
{
  // check the number of DPDK logical cores
  if (rte_lcore_count () < min_lcores)
    {
      rte_exit (EXIT_FAILURE, "No available worker cores!\n");
    }

  // init the seed for random numbers
  rte_srand (seed);

  // get the number of cycles per us
  TICKS_PER_US = rte_get_timer_hz () / 1000000;

  // flush all flows of the NIC
  struct rte_flow_error error;
  rte_flow_flush (portid, &error);

  // allocate the packet pool
  char s[64];
  snprintf (s, sizeof (s), "mbuf_pool_rx");
  pktmbuf_pool_rx = rte_pktmbuf_pool_create (
      s, PKTMBUF_POOL_ELEMENTS, MEMPOOL_CACHE_SIZE, 0,
      RTE_MBUF_DEFAULT_BUF_SIZE, rte_eth_dev_socket_id (portid));
  if (pktmbuf_pool_rx == NULL)
    {
      rte_exit (EXIT_FAILURE, "Cannot init RX mbuf pool on socket %d\n",
                rte_eth_dev_socket_id (portid));
    }

  snprintf (s, sizeof (s), "mbuf_pool_tx");
  pktmbuf_pool_tx = rte_pktmbuf_pool_create (
      s, PKTMBUF_POOL_ELEMENTS, MEMPOOL_CACHE_SIZE, 0,
      RTE_MBUF_DEFAULT_BUF_SIZE, rte_eth_dev_socket_id (portid));
  if (pktmbuf_pool_tx == NULL)
    {
      rte_exit (EXIT_FAILURE, "Cannot init TX mbuf pool on socket %d\n",
                rte_eth_dev_socket_id (portid));
    }

  // initialize the DPDK port
  uint16_t nb_rx_queue = nr_queues;
  uint16_t nb_tx_queue = nr_queues;

  if (init_DPDK_port (portid, nb_rx_queue, nb_tx_queue, pktmbuf_pool_rx) != 0)
    {
      rte_exit (EXIT_FAILURE, "Cannot init port %" PRIu8 "\n", 0);
    }
}

// Initialize the DPDK port
int
init_DPDK_port (uint16_t portid, uint16_t nb_rx_queue, uint16_t nb_tx_queue,
                struct rte_mempool *mbuf_pool)
{
  // configurable number of RX/TX ring descriptors
  uint16_t nb_rxd = 4096;
  uint16_t nb_txd = 4096;

  // get default port_conf
  struct rte_eth_conf port_conf = {
      .rxmode =
          {
              .mq_mode =
                  nb_rx_queue > 1 ? RTE_ETH_MQ_RX_RSS : RTE_ETH_MQ_RX_NONE,
              //.max_lro_pkt_size = RTE_ETHER_MAX_LEN,
              //.offloads =
              //    RTE_ETH_RX_OFFLOAD_IPV4_CKSUM |
              //    RTE_ETH_RX_OFFLOAD_UDP_CKSUM,
          },
      //.rx_adv_conf =
      //    {
      //        .rss_conf =
      //            {
      //                .rss_key = NULL,
      //                .rss_hf = RTE_ETH_RSS_NONFRAG_IPV4_UDP,
      //            },
      //    },
      .txmode =
          {
              .mq_mode = RTE_ETH_MQ_TX_NONE,
              //.offloads =
              // RTE_ETH_TX_OFFLOAD_UDP_CKSUM|RTE_ETH_TX_OFFLOAD_IPV4_CKSUM,
          },
  };

  // configure the NIC
  int retval
      = rte_eth_dev_configure (portid, nb_rx_queue, nb_tx_queue, &port_conf);
  if (retval != 0)
    {
      return retval;
    }

  // adjust and set up the number of RX/TX descriptors
  retval = rte_eth_dev_adjust_nb_rx_tx_desc (portid, &nb_rxd, &nb_txd);
  if (retval < 0)
    {
      return retval;
    }

  struct rte_eth_dev_info dev_info;
  rte_eth_dev_info_get (portid, &dev_info);

  struct rte_eth_rxconf *rxconf;
  rxconf = &dev_info.default_rxconf;
  // rxconf->rx_free_thresh = 128;

  // setup the RX queues
  for (int q = 0; q < nb_rx_queue; q++)
    {
      retval = rte_eth_rx_queue_setup (portid, q, nb_rxd,
                                       rte_eth_dev_socket_id (portid), rxconf,
                                       mbuf_pool);
      if (retval < 0)
        {
          return retval;
        }
    }

  struct rte_eth_txconf *txconf;
  txconf = &dev_info.default_txconf;
  // txconf->tx_rs_thresh = 64;
  // txconf->tx_free_thresh = 2;

  // setup the TX queues
  for (int q = 0; q < nb_tx_queue; q++)
    {
      retval = rte_eth_tx_queue_setup (portid, q, nb_txd,
                                       rte_eth_dev_socket_id (portid), txconf);
      if (retval < 0)
        {
          return retval;
        }
    }

  // disable flow control
  // struct rte_eth_fc_conf fc_conf;
  // retval = rte_eth_dev_flow_ctrl_get(portid, &fc_conf);
  // if (retval == 0) {
  //  fc_conf.mode = RTE_ETH_FC_NONE;
  //  rte_eth_dev_flow_ctrl_set(portid, &fc_conf);
  //} else {
  //  return retval;
  //}

  // start the Ethernet port
  retval = rte_eth_dev_start (portid);
  if (retval < 0)
    {
      return retval;
    }

  return 0;
}

// Print the DPDK stats
void
print_dpdk_stats (uint32_t portid)
{
  struct rte_eth_stats eth_stats;
  int retval = rte_eth_stats_get (portid, &eth_stats);
  if (retval != 0)
    {
      rte_exit (EXIT_FAILURE, "Unable to get stats from portid\n");
    }

  printf ("\n\nDPDK RX Stats:\n");
  printf ("ipackets: %lu\n", eth_stats.ipackets);
  printf ("ibytes: %lu\n", eth_stats.ibytes);
  printf ("ierror: %lu\n", eth_stats.ierrors);
  printf ("imissed: %lu\n", eth_stats.imissed);
  printf ("rxnombuf: %lu\n", eth_stats.rx_nombuf);

  printf ("\nDPDK TX Stats:\n");
  printf ("opackets: %lu\n", eth_stats.opackets);
  printf ("obytes: %lu\n", eth_stats.obytes);
  printf ("oerror: %lu\n", eth_stats.oerrors);

  struct rte_eth_xstat *xstats;
  struct rte_eth_xstat_name *xstats_names;
  static const char *stats_border = "_______";

  printf ("\n\nPORT STATISTICS:\n================\n");
  int len = rte_eth_xstats_get (portid, NULL, 0);
  if (len < 0)
    {
      rte_exit (EXIT_FAILURE, "rte_eth_xstats_get(%u) failed: %d", portid,
                len);
    }

  xstats = calloc (len, sizeof (*xstats));
  if (xstats == NULL)
    {
      rte_exit (EXIT_FAILURE, "Failed to calloc memory for xstats");
    }

  int ret = rte_eth_xstats_get (portid, xstats, len);
  if (ret < 0 || ret > len)
    {
      free (xstats);
      rte_exit (EXIT_FAILURE, "rte_eth_xstats_get(%u) len%i failed: %d",
                portid, len, ret);
    }

  xstats_names = calloc (len, sizeof (*xstats_names));
  if (xstats_names == NULL)
    {
      free (xstats);
      rte_exit (EXIT_FAILURE, "Failed to calloc memory for xstats_names");
    }

  ret = rte_eth_xstats_get_names (portid, xstats_names, len);
  if (ret < 0 || ret > len)
    {
      free (xstats);
      free (xstats_names);
      rte_exit (EXIT_FAILURE, "rte_eth_xstats_get_names(%u) len%i failed: %d",
                portid, len, ret);
    }

  for (int i = 0; i < len; i++)
    {
      if (xstats[i].value > 0)
        {
          printf ("Port %u: %s %s:\t\t%" PRIu64 "\n", portid, stats_border,
                  xstats_names[i].name, xstats[i].value);
        }
    }

  free (xstats);
  free (xstats_names);
}

// create DPDK rings for the RX threads
void
create_dpdk_rings ()
{
  char s[64];
  snprintf (s, sizeof (s), "ring_rx%u", 0);
  rx_ring = rte_ring_create (s, RING_ELEMENTS, rte_socket_id (),
                             RING_F_SP_ENQ | RING_F_SC_DEQ);

  if (rx_ring == NULL)
    {
      rte_exit (EXIT_FAILURE, "Cannot create the rings on socket %d\n",
                rte_socket_id ());
    }
}

// clear all DPDK structures allocated
void
clean_hugepages ()
{
  rte_ring_free (rx_ring);

  rte_free (control_blocks);
  rte_mempool_free (pktmbuf_pool_tx);
  rte_mempool_free (pktmbuf_pool_rx);
}

#include "util.h"

#include "resp.h"

int distribution;
char output_file[MAXSTRLEN];

// Sample the value using Exponential Distribution
double sample_exponential(double lambda) {
  double u = (double)rand() / RAND_MAX; // Uniform random number [0,1]
  return -log(1 - u) / lambda;
}

// Sample the value using Log-Normal Distribution
double sample_lognormal(double mu, double sigma) {
  double u1 = ((double)rand() / RAND_MAX); // Uniform random number [0,1]
  double u2 = ((double)rand() / RAND_MAX); // Uniform random number [0,1]

  double z = sqrt(-2.0 * log(u1)) * cos(2 * M_PI * u2);

  return exp(mu + sigma * z);
}

// Sample the value using Pareto Distribution
double sample_pareto(double alpha, double xm) {
  double u = (double)rand() / RAND_MAX; // Uniform random number [0,1]
  return xm / pow(1 - u, 1.0 / alpha);
}

// Convert string type into int type
static uint32_t process_int_arg(const char *arg) {
  char *end = NULL;

  return strtoul(arg, &end, 10);
}

// Allocate and create all nodes for incoming packets
void create_incoming_array() {
  incoming_array = rte_malloc(NULL, rate * duration * sizeof(node_t), 64);
  if (incoming_array == NULL) {
    rte_exit(EXIT_FAILURE, "Cannot alloc the incoming array.\n");
  }
}

// return value between 0 and 999
static uint32_t sample_uniform(void) { return rte_rand() % 1000; }

#define member_size(type, member) (sizeof(((type *)0)->member))

static void uint_to_str(unsigned int value, char *str) {
  char buffer[11]; // Enough for 32-bit unsigned int (max 10 digits + null
                   // terminator)
  int i = 0;

  if (value == 0) {
    str[i++] = '0';
  } else {
    while (value > 0) {
      buffer[i++] = '0' + (value % 10);
      value /= 10;
    }
  }

  // Reverse the string into str
  int j = 0;
  while (i > 0) {
    str[j++] = buffer[--i];
  }
  str[j] = '\0'; // Null-terminate
}

void create_request_types_array(void) {
  uint64_t nr_elements = rate * duration;

  request_types = rte_malloc(NULL, nr_elements * sizeof(request_type_t), 64);
  if (request_types == NULL)
    rte_exit(EXIT_FAILURE, "Cannot alloc the request_types array.\n");

  // only debug
  uint64_t types_count[TOTAL_RTYPES] = {0};

  for (uint64_t j = 0; j < nr_elements; j++) {
    uint32_t random = sample_uniform();
    uint32_t t = 0;
    for (; t < TOTAL_RTYPES; t++) {
      // printf("ratio %u\n", cfg_request_types[i].ratio);
      if (random < cfg_request_types[t].ratio)
        break;

      random -= cfg_request_types[t].ratio;
    }

    // request_types[j].dst_port = cfg_request_types[t].dst_port;

    set_type(request_types[j], t + 1);

#ifdef DB
    unsigned r = rte_rand() % 1000; // keys in server DB
    char buff[member_size(request_type_t, key)] = {0};
    snprintf(buff, sizeof buff, "k%u", r);
    memcpy(&request_types[j].key, buff, sizeof(buff));
#endif

#ifdef RESP
    // resp encode
    char buff_service_time[11];
    uint_to_str(cfg_request_types[t].service_time, buff_service_time);

    char *cmd[2];

    switch (t + 1) {
    case 1:
      cmd[0] = "SHORT";
      break;
    case 2:
      cmd[0] = "LONG";
      break;
    case 3:
      cmd[0] = "INVALID";
      break;
    default:
      rte_exit(EXIT_FAILURE, "Error request type");
    }

    cmd[1] = buff_service_time;
    int ret = resp_encode(request_types[j].resp_buff, 32, cmd, 2);
    if (ret == -1)
      rte_exit(EXIT_FAILURE, "Error to encode resp request\n");

    request_types[j].resp_buff[ret] = '\0';
    // if (t + 1 == 2)
    //  printf ("%s\n", request_types[j].resp_buff);

#endif

    // debug
    types_count[t]++;
  }

  // debug
  for (int i = 0; i < TOTAL_RTYPES; i++)
    printf("Type%u: requests: %lu (sv: %u ns)\n", i + 1, types_count[i],
           cfg_request_types[i].service_time);
}

// Allocate and create an array for all interarrival packets for rate
// specified.
void create_interarrival_array() {
  uint64_t nr_elements = rate * duration;

  interarrival_array = rte_malloc(NULL, nr_elements * sizeof(uint64_t), 64);
  if (interarrival_array == NULL) {
    rte_exit(EXIT_FAILURE, "Cannot alloc the interarrival_gap array.\n");
  }

  if (distribution == UNIFORM_VALUE) {
    // Uniform
    double mean = (1.0 / rate) * 1000000.0;
    for (uint64_t j = 0; j < nr_elements; j++) {
      interarrival_array[j] = mean * TICKS_PER_US;
    }
  } else if (distribution == EXPONENTIAL_VALUE) {
    // Exponential
    double lambda = 1.0 / (1000000.0 / rate);
    for (uint64_t j = 0; j < nr_elements; j++) {
      interarrival_array[j] = sample_exponential(lambda) * TICKS_PER_US;
    }
  } else if (distribution == LOGNORMAL_VALUE) {
    // Log-normal
    double mean = (1.0 / rate) * 1000000.0;
    double sigma = sqrt(2 * (log(mean) - log(mean / 2)));
    double u = log(mean) - (sigma * sigma) / 2;
    for (uint64_t j = 0; j < nr_elements; j++) {
      interarrival_array[j] = sample_lognormal(u, sigma) * TICKS_PER_US;
    }
  } else if (distribution == PARETO_VALUE) {
    // Pareto
    double mean = (1.0 / rate) * 1000000.0;
    double alpha = 1.0 + mean / (mean - 1.0);
    double xm = mean * (alpha - 1) / (alpha);
    for (uint64_t j = 0; j < nr_elements; j++) {
      interarrival_array[j] = sample_pareto(alpha, xm) * TICKS_PER_US;
    }
  } else {
    exit(-1);
  }
}

// Allocate and create an array for all flow indentier to send to the server
void create_flow_indexes_array() {
  uint64_t nr_elements = rate * duration;

  flow_indexes_array = rte_malloc(NULL, nr_elements * sizeof(uint16_t *), 64);
  if (flow_indexes_array == NULL)
    rte_exit(EXIT_FAILURE, "Cannot alloc the flow_indexes array.\n");

  for (uint64_t i = 0; i < nr_elements; i++) {
    flow_indexes_array[i] = i % nr_flows;
  }
}

// Clean up all allocate structures
void clean_heap() {
  rte_free(incoming_array);
  rte_free(flow_indexes_array);
  rte_free(interarrival_array);
}

// Usage message
static void usage(const char *prgname) {
  printf("%s [EAL options] -- \n"
         "  -d DISTRIBUTION: <uniform|exponential>\n"
         "  -r RATE: rate in pps\n"
         "  -f FLOWS: number of flows\n"
         "  -q QUEUES: number of queues\n"
         "  -s SIZE: frame size in bytes\n"
         "  -t TIME: time in seconds to send packets\n"
         "  -c FILENAME: name of the configuration file\n"
         "  -o FILENAME: name of the output file\n",
         prgname);
}

#define MIN_PKT_SIZE                                                           \
  (sizeof(struct rte_ether_hdr) + sizeof(struct rte_ipv4_hdr) +                \
   sizeof(struct rte_udp_hdr))

// Parse the argument given in the command line of the application
int app_parse_args(int argc, char **argv) {
  int opt, ret;
  char **argvopt;
  char *prgname = argv[0];

  argvopt = argv;
  while ((opt = getopt(argc, argvopt, "d:r:f:s:q:p:t:c:o:x:")) != EOF) {
    switch (opt) {
    // distribution
    case 'd':
      if (strcmp(optarg, "uniform") == 0) {
        // Uniform distribution
        distribution = UNIFORM_VALUE;
      } else if (strcmp(optarg, "exponential") == 0) {
        // Exponential distribution
        distribution = EXPONENTIAL_VALUE;
      } else if (strcmp(optarg, "lognormal") == 0) {
        // Lognormal distribution
        distribution = LOGNORMAL_VALUE;
      } else if (strcmp(optarg, "pareto") == 0) {
        // Pareto distribution
        distribution = PARETO_VALUE;
      } else {
        usage(prgname);
        rte_exit(EXIT_FAILURE, "Invalid arguments.\n");
      }
      break;

    // rate (pps)
    case 'r':
      rate = process_int_arg(optarg);
      break;

    // flows
    case 'f':
      nr_flows = process_int_arg(optarg);
      break;

    // frame size (bytes)
    case 's':
      frame_size = process_int_arg(optarg);
      unsigned min_frame_size =
          MIN_PKT_SIZE + PAYLOAD_TOTAL_ITEMS * sizeof(uint64_t);
      if (frame_size < min_frame_size)
        rte_exit(EXIT_FAILURE, "size not should be less than %u.\n",
                 min_frame_size);

      udp_payload_size = (frame_size - MIN_PKT_SIZE);
      break;

    // duration (s)
    case 't':
      duration = process_int_arg(optarg);
      break;

    // config file name
    case 'c':
      process_config_file(optarg);
      break;

    // output mode
    case 'o':
      strcpy(output_file, optarg);
      break;

    // set specific seed to random number generator
    case 'x':
      seed = process_int_arg(optarg);
      break;

    default:
      usage(prgname);
      rte_exit(EXIT_FAILURE, "Invalid arguments.\n");
    }
  }

  if (optind >= 0) {
    argv[optind - 1] = prgname;
  }

  ret = optind - 1;
  optind = 1;

  return ret;
}

// Wait for the duration parameter
void wait_timeout() {
  uint32_t remaining_in_s = 5;
  rte_delay_us_sleep((duration + remaining_in_s) * 1000000);

  // set quit flag for all internal cores
  quit_tx = 1;
  quit_rx = 1;
  quit_rx_ring = 1;
}

// Compare two double values (for qsort function)
int cmp_func(const void *a, const void *b) {
  double da = (*(double *)a);
  double db = (*(double *)b);

  return (da - db) > ((fabs(da) < fabs(db) ? fabs(db) : fabs(da)) * EPSILON);
}

static uint64_t get_delta_ns(uint64_t start, uint64_t end) {
  // assert(start <= end);
  double ticks_per_ns = TICKS_PER_US / (double)1000.0;
  return (end - start) / ticks_per_ns;
}

// Print stats into output file
void print_stats_output() {
  // open the file
  FILE *fp = fopen(output_file, "w");
  if (fp == NULL) {
    rte_exit(EXIT_FAILURE, "Cannot open the output file.\n");
  }

  uint64_t rps_offered = 0;
  uint64_t rps_reached = 0;
  uint64_t tot_tx = 0;
  uint64_t tot_rx = 0;
  uint64_t dropped = 0;

  for (uint32_t i = 0; i < 1; i++) {
    rps_offered += q_rps[i].rps_offered;
    rps_reached += q_rps[i].rps_reached;
    tot_tx += q_rps[i].tot_tx;
    tot_rx += q_rps[i].tot_rx;

    // drop the first 10% packets for warming up
    uint64_t j = 0.1 * incoming_idx;

    node_t *cur;
    for (; j < incoming_idx; j++) {
      cur = &incoming_array[j];

      uint64_t latency = get_delta_ns(cur->timestamp_tx, cur->timestamp_rx);
      double slowdown = latency / (double)cur->service_time;

      fprintf(fp, "%u\t%lu\t%.2lf\n", cur->type, latency, slowdown);
    }
  }

  // close the file
  fclose(fp);
  dropped = tot_tx - tot_rx;

  char buff[255];
  snprintf(buff, sizeof(buff), "%s_%s", output_file, "rate");
  fp = fopen(buff, "w");
  fprintf(
      fp,
      "offered\treached\ttot_tx\ttot_rx\tdropped\n%lu\t%lu\t%lu\t%lu\t%lu\n",
      rps_offered, rps_reached, tot_tx, tot_rx, dropped);
  fclose(fp);
}

#define ASIZE(x) (sizeof(x) / sizeof(x[0]))

// Process the config file
void process_config_file(char *cfg_file) {
  // open the file
  struct rte_cfgfile *file = rte_cfgfile_load(cfg_file, 0);
  if (file == NULL) {
    rte_exit(EXIT_FAILURE, "Cannot load configuration profile %s\n", cfg_file);
  }

  // load ethernet addresses
  char *entry;
  entry = (char *)rte_cfgfile_get_entry(file, "ethernet", "src");
  if (entry) {
    rte_ether_unformat_addr((const char *)entry, &src_eth_addr);
    rte_eth_dev_default_mac_addr_set(portid, &src_eth_addr);
  } else
    rte_eth_macaddr_get(portid, &src_eth_addr);

  entry = (char *)rte_cfgfile_get_entry(file, "ethernet", "dst");
  if (entry) {
    rte_ether_unformat_addr((const char *)entry, &dst_eth_addr);
  }

  // load ipv4 addresses
  entry = (char *)rte_cfgfile_get_entry(file, "ipv4", "src");
  if (entry) {
    uint8_t b3, b2, b1, b0;
    sscanf(entry, "%hhd.%hhd.%hhd.%hhd", &b3, &b2, &b1, &b0);
    src_ipv4_addr = IPV4_ADDR(b3, b2, b1, b0);
  }
  entry = (char *)rte_cfgfile_get_entry(file, "ipv4", "dst");
  if (entry) {
    uint8_t b3, b2, b1, b0;
    sscanf(entry, "%hhd.%hhd.%hhd.%hhd", &b3, &b2, &b1, &b0);
    dst_ipv4_addr = IPV4_ADDR(b3, b2, b1, b0);
  }

  // load UDP destination port
  entry = (char *)rte_cfgfile_get_entry(file, "udp", "dst");
  if (entry) {
    uint16_t port;
    sscanf(entry, "%hu", &port);
    dst_udp_port = port;
  }

  int i, ret;
  struct rte_cfgfile_entry entries[TOTAL_RTYPES];
  ret = rte_cfgfile_section_entries(file, "requests_service_time", entries,
                                    ASIZE(entries));
  for (i = 0; i < ret; i++)
    cfg_request_types[i].service_time = atoi(entries[i].value);

  ret = rte_cfgfile_section_entries(file, "requests_ratio", entries,
                                    ASIZE(entries));
  for (i = 0; i < ret; i++)
    cfg_request_types[i].ratio = atoi(entries[i].value);

  // ret = rte_cfgfile_section_entries (file, "requests_dst_ports", entries,
  //                                   ASIZE (entries));
  // for (i = 0; i < ret; i++)
  //  cfg_request_types[i].dst_port = atoi (entries[i].value);

  entry = (char *)rte_cfgfile_get_entry(file, "classification_time", "time");
  if (!entry)
    rte_exit(EXIT_FAILURE, "Error parse cfg file");

  sscanf(entry, "%lu", &classification_time);

  // close the file
  rte_cfgfile_close(file);
}

// Fill the data into packet payload properly
void fill_payload_pkt(struct rte_mbuf *pkt, enum payload_item item,
                      uint64_t value) {
  uint8_t *payload = (uint8_t *)rte_pktmbuf_mtod_offset(
      pkt, uint8_t *,
      sizeof(struct rte_ether_hdr) + sizeof(struct rte_ipv4_hdr) +
          sizeof(struct rte_udp_hdr));

  ((uint64_t *)payload)[item] = value;
}

void fill_payload_resp_request(struct rte_mbuf *pkt, enum payload_item item,
                               char *buff, size_t buff_size) {
  uint64_t *payload = rte_pktmbuf_mtod_offset(pkt, uint64_t *,
                                              sizeof(struct rte_ether_hdr) +
                                                  sizeof(struct rte_ipv4_hdr) +
                                                  sizeof(struct rte_udp_hdr));

  rte_memcpy(&payload[item], buff, buff_size);
}

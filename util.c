#include "util.h"

int distribution;
char output_file[MAXSTRLEN];

// Sample the value using Exponential Distribution
double sample(double lambda) {
		double u = ((double) rte_rand()) / ((uint64_t) -1);

	return -log(1 - u) / lambda;
}

// Convert string type into int type
static uint32_t process_int_arg(const char *arg) {
	char *end = NULL;

	return strtoul(arg, &end, 10);
}

// Allocate all nodes for incoming packets (+ 20%)
void allocate_incoming_nodes() {
	uint64_t rate_per_queue = rate/nr_queues;
	uint64_t nr_elements_per_queue = (2 * rate_per_queue * duration) * 1.2;

	incoming_array = (node_t**) malloc(nr_queues * sizeof(node_t*));
	if(incoming_array == NULL) {
		rte_exit(EXIT_FAILURE, "Cannot alloc the incoming array.\n");
	}

	for(uint64_t i = 0; i < nr_queues; i++) {
		incoming_array[i] = (node_t*) malloc(nr_elements_per_queue * sizeof(node_t));
		if(incoming_array[i] == NULL) {
			rte_exit(EXIT_FAILURE, "Cannot alloc the incoming array.\n");
		}
	}

	incoming_idx_array = (uint64_t*) malloc(nr_queues * sizeof(uint64_t));
	if(incoming_idx_array == NULL) {
		rte_exit(EXIT_FAILURE, "Cannot alloc the incoming_idx array.\n");
	}

	for(uint64_t i = 0; i < nr_queues; i++) {
		incoming_idx_array[i] = 0;
	}
}

// return value between 0 and 99
static uint32_t
sample_uniform(void)
{
  return rte_rand() % 1000;
}

void
create_request_types_array(void)
{
  uint64_t rate_per_queue = rate/nr_queues;
  uint64_t nr_elements_per_queue = 2 * rate_per_queue * duration;

  request_types = rte_malloc(NULL, nr_queues * sizeof(request_type_t *), 64);
  if(request_types == NULL)
    rte_exit(EXIT_FAILURE, "Cannot alloc the request_types array.\n");

  uint32_t debug_types[2] = {0};

  for (uint64_t i = 0; i < nr_queues; i++)
  {
    request_type_t *rtype = rte_malloc(NULL, nr_elements_per_queue * sizeof(*rtype), 64);
    if (!rtype)
      rte_exit(EXIT_FAILURE, "Cannot alloc rtype array.\n");

    request_types[i] = rtype;

    for (uint64_t j = 0; j < nr_elements_per_queue; j++)
    {
      uint32_t random = sample_uniform();
      uint32_t t = 0;
      for(; t < TOTAL_RTYPES; t++)
      {
        //printf("ratio %u\n", cfg_request_types[i].ratio);
        if (random < cfg_request_types[t].ratio)
          break;
        
        random -= cfg_request_types[t].ratio;
      }

      //printf("t %u\n", t);
      debug_types[t]++;
      rtype[j].type = t + 1; // psp server
      rtype[j].service_time = cfg_request_types[t].service_time;
    }
  }

  printf("shorts: %u longs: %u\n", debug_types[0], debug_types[1]);
}

// Allocate and create an array for all interarrival packets for rate specified.
void create_interarrival_array() {
	uint64_t rate_per_queue = rate/nr_queues;
	double lambda;
	if(distribution == UNIFORM_VALUE) {
		lambda = (1.0/rate_per_queue) * 1000000.0;
	} else if(distribution == EXPONENTIAL_VALUE) {
		lambda = 1.0/(1000000.0/rate_per_queue);
	} else {
		rte_exit(EXIT_FAILURE, "Cannot define the interarrival distribution.\n");
	}

	uint64_t nr_elements_per_queue = 2 * rate_per_queue * duration;

	interarrival_array = (uint64_t**) malloc(nr_queues * sizeof(uint64_t*));
	if(interarrival_array == NULL) {
		rte_exit(EXIT_FAILURE, "Cannot alloc the interarrival_gap array.\n");
	}

	for(uint64_t i = 0; i < nr_queues; i++) {
		interarrival_array[i] = (uint64_t*) malloc(nr_elements_per_queue * sizeof(uint64_t));
		if(interarrival_array[i] == NULL) {
			rte_exit(EXIT_FAILURE, "Cannot alloc the interarrival_gap array.\n");
		}
		
		uint64_t *interarrival_gap = interarrival_array[i];
		if(distribution == UNIFORM_VALUE) {
			for(uint64_t j = 0; j < nr_elements_per_queue; j++) {
				interarrival_gap[j] = lambda * TICKS_PER_US;
			}
		} else {
			for(uint64_t j = 0; j < nr_elements_per_queue; j++) {
				interarrival_gap[j] = sample(lambda) * TICKS_PER_US;
			}
		}
	} 
}

// Allocate and create an array for all flow indentier to send to the server
void create_flow_indexes_array() {
	//uint32_t nbits = (uint32_t) log2(nr_queues);
	uint64_t rate_per_queue = rate/nr_queues;
	uint64_t nr_elements_per_queue = rate_per_queue * duration * 2;

	flow_indexes_array = (uint16_t**) malloc(nr_queues * sizeof(uint16_t*));
	if(flow_indexes_array == NULL) {
		rte_exit(EXIT_FAILURE, "Cannot alloc the flow_indexes array.\n");
	}

	for(uint64_t i = 0; i < nr_queues; i++) {
		flow_indexes_array[i] = (uint16_t*) malloc(nr_elements_per_queue * sizeof(uint16_t));
		if(flow_indexes_array[i] == NULL) {
			rte_exit(EXIT_FAILURE, "Cannot alloc the flow_indexes array.\n");
		}
		uint16_t *flow_indexes = flow_indexes_array[i];
		for(int j = 0; j < nr_elements_per_queue; j++) {
			//flow_indexes[j] = ((rte_rand() << nbits) | i) % nr_flows;
			flow_indexes[j] = j % nr_flows;
		}
	}
}

// Clean up all allocate structures
void clean_heap() {
	free(incoming_array);
	free(incoming_idx_array);
	free(flow_indexes_array);
	free(interarrival_array);
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
		prgname
	);
}

#define MIN_PKT_SIZE ( sizeof(struct rte_ether_hdr) + \
                       sizeof(struct rte_ipv4_hdr) + \
                       sizeof(struct rte_udp_hdr) )

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
			if(strcmp(optarg, "uniform") == 0) {
				// Uniform distribution 
				distribution = UNIFORM_VALUE;
			} else if(strcmp(optarg, "exponential") == 0) {
				// Exponential distribution
				distribution = EXPONENTIAL_VALUE;
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
            int min_frame_size = MIN_PKT_SIZE + PAYLOAD_TOTAL_ITEMS * sizeof(uint64_t);
            if (frame_size < min_frame_size) 
              rte_exit(EXIT_FAILURE, "size not should be less than %u.\n", min_frame_size);

			udp_payload_size = (frame_size - MIN_PKT_SIZE);
			break;

		// queues
		case 'q':
			nr_queues = process_int_arg(optarg);
			min_lcores = 3 * nr_queues + 1;
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

	if(optind >= 0) {
		argv[optind-1] = prgname;
	}

	if(nr_flows < nr_queues) {
		rte_exit(EXIT_FAILURE, "The number of flows should be bigger than the number of queues.\n");
	}

	ret = optind-1;
	optind = 1;

	return ret;
}

// Wait for the duration parameter
void wait_timeout() {
	uint64_t t0 = rte_rdtsc();
	while((rte_rdtsc() - t0) < (2 * duration * 1000000 * TICKS_PER_US)) { }

	// wait for remaining
	//t0 = rte_rdtsc_precise();
	//while((rte_rdtsc() - t0) < (10 * 1000000 * TICKS_PER_US)) { }

	// set quit flag for all internal cores
	quit_rx = 1;
	quit_tx = 1;
	quit_rx_ring = 1;
}

// Compare two double values (for qsort function)
int cmp_func(const void * a, const void * b) {
	double da = (*(double*)a);
	double db = (*(double*)b);

	return (da - db) > ( (fabs(da) < fabs(db) ? fabs(db) : fabs(da)) * EPSILON);
}
    

static uint64_t
get_delta_ns(uint64_t start, uint64_t end)
{
  //assert(start <= end);
  double ticks_per_ns = TICKS_PER_US / (double)1000.0;
  return ( end - start ) / ticks_per_ns;
}

const char *title = "ID\tTYPE\tRTT\tRX/APP\tAPP\tAPP/TX\tWID_RX\tWID_TX\tPREEMPTED";

// Print stats into output file
void print_stats_output() {
	// open the file
	FILE *fp = fopen(output_file, "w");
	if(fp == NULL) {
		rte_exit(EXIT_FAILURE, "Cannot open the output file.\n");
	}

	uint64_t rps_offered = 0;
	uint64_t rps_reached = 0;

    //fprintf(fp, "%s\n", title);

	for(uint32_t i = 0; i < nr_queues; i++) {
		// get the pointers
		node_t *incoming = incoming_array[i];
		uint32_t incoming_idx = incoming_idx_array[i];

		rps_offered += q_rps[i].rps_offered;
		rps_reached += q_rps[i].rps_reached;

		// drop the first 50% packets for warming up
		uint64_t j = 0.5 * incoming_idx;

		// print the RTT latency in (ns)
		node_t *cur;
		//for(; j < incoming_idx; j++) {
		for(; j < incoming_idx; j++) {
			cur = &incoming[j];

			//fprintf(fp, "%u\t%lu\t%lu\t%lu\t%lu\t%lu\t%lu\t%lu\n",
			fprintf(fp, "%u\t%lu\n",
				//cur->flow_id,
                cur->type,
                get_delta_ns(cur->timestamp_tx, cur->timestamp_rx) // RTT
                
                //get_delta_ns(cur->rx_time, cur->app_recv_time), // delay afp -> app
                //get_delta_ns(cur->app_recv_time, cur->app_send_time), // delay app
                //get_delta_ns(cur->app_send_time, cur->tx_time), // delay app -> tx
                //cur->worker_rx, // worker id rx
                //cur->worker_tx, // worker id tx
                //cur->interrupt_count // long count preempt
			);
		}
	}

	// close the file
	fclose(fp);

	char buff[64];
	snprintf(buff, sizeof(buff), "%s_%s", output_file, "rate");
	fp = fopen(buff, "w");

	fprintf(fp, "offered\treached\n%lu\t%lu\n", rps_offered, rps_reached);
}

// Process the config file
void process_config_file(char *cfg_file) {
	// open the file
	struct rte_cfgfile *file = rte_cfgfile_load(cfg_file, 0);
	if(file == NULL) {
		rte_exit(EXIT_FAILURE, "Cannot load configuration profile %s\n", cfg_file);
	}

	// load ethernet addresses
	char *entry = (char*) rte_cfgfile_get_entry(file, "ethernet", "src");
	if(entry) {
		rte_ether_unformat_addr((const char*) entry, &src_eth_addr);
	}
	entry = (char*) rte_cfgfile_get_entry(file, "ethernet", "dst");
	if(entry) {
		rte_ether_unformat_addr((const char*) entry, &dst_eth_addr);
	}

	// load ipv4 addresses
	entry = (char*) rte_cfgfile_get_entry(file, "ipv4", "src");
	if(entry) {
		uint8_t b3, b2, b1, b0;
		sscanf(entry, "%hhd.%hhd.%hhd.%hhd", &b3, &b2, &b1, &b0);
		src_ipv4_addr = IPV4_ADDR(b3, b2, b1, b0);
	}
	entry = (char*) rte_cfgfile_get_entry(file, "ipv4", "dst");
	if(entry) {
		uint8_t b3, b2, b1, b0;
		sscanf(entry, "%hhd.%hhd.%hhd.%hhd", &b3, &b2, &b1, &b0);
		dst_ipv4_addr = IPV4_ADDR(b3, b2, b1, b0);
	}

	// load UDP destination port
	entry = (char*) rte_cfgfile_get_entry(file, "udp", "dst");
	if(entry) {
		uint16_t port;
		sscanf(entry, "%hu", &port);
		dst_udp_port = port;
	}

	// local server info
	entry = (char*) rte_cfgfile_get_entry(file, "server", "nr_servers");
	if(entry) {
		uint16_t n;
		sscanf(entry, "%hu", &n);
		nr_servers = n;
	}

    int i, ret;
    struct rte_cfgfile_entry entrys[TOTAL_RTYPES];
    ret = rte_cfgfile_section_entries(file, "requests_service_time", entrys, 2);
    assert(ret == 2);
    for( i = 0; i < ret; i++)
      cfg_request_types[i].service_time = atoi(entrys[i].value);
    
    ret = rte_cfgfile_section_entries(file, "requests_ratio", entrys, 2);
    assert( ret == 2 );
    for( i = 0; i < ret; i++)
      cfg_request_types[i].ratio = atoi(entrys[i].value);

    entry = (char *)rte_cfgfile_get_entry(file, "classification_time", "time");
    if (!entry)
      rte_exit(EXIT_FAILURE, "Error parse cfg file");

    sscanf(entry, "%lu", &classification_time);

	// close the file
	rte_cfgfile_close(file);
}

// Fill the data into packet payload properly
inline void fill_payload_pkt(struct rte_mbuf *pkt, enum payload_item item, uint64_t value) {
	uint8_t *payload = (uint8_t*) rte_pktmbuf_mtod_offset(pkt, uint8_t*, sizeof(struct rte_ether_hdr) + sizeof(struct rte_ipv4_hdr) + sizeof(struct rte_udp_hdr));

	((uint64_t*) payload)[item] = value;
}

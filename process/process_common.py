
import os
import glob
import math
import pandas as pd
#import polars as pl

#default
percentile = 99.9

def process_get_and_set_percentile(p: str) -> float:
  PERCENTILES = {'p999': 99.9, 'p99': 99.0, 'p90': 90.0, 'p50': 50.0}
  global percentile
  percentile = PERCENTILES[p]
  return percentile

def process_get_policy_name(policy):
  return policy.rstrip('/').split('/')[-1]

def process_get_metadata_name(wk, percentil):
  file = f'{wk}_{percentil}_meta.dat'
  return file

def interval_confidence( data: list ):
  lenght = len(data)
  if lenght == 0:
    return 0, 0

  Z = 1.96 # nivel de confiança 95%
  avg = sum(data) / lenght

  sum_ = 0
  for i in range(len(data)):
    sum_ += math.pow( data[i] - avg, 2 )

  desvio = math.sqrt( sum_ / len(data) )
  margin_error = Z * ( desvio / math.sqrt(lenght ) ) # intervalo de confiança

  avg = round(avg, 4)
  margin_error = round(margin_error, 4)
  return avg, margin_error

def get_latency(rate, slowdown=False):
  shorts = []
  longs = []
  alls = []
  p = {
    'shorts': shorts,
    'longs': longs,
    'all': alls,
  }

  for t in p.keys():
    if slowdown == False:
      files = glob.glob(f'{rate}/test[0-9]*{t}_{percentile}_result')
    else:
      files = glob.glob(f'{rate}/test[0-9]*{t}_{percentile}_result_slowdown')

    for file in files:
      with open(file, 'r') as f:
        v = float(f.read())
        p[t].append(v)


  return interval_confidence(shorts), \
    interval_confidence(longs), \
    interval_confidence(alls)

def get_rps(rate):
  files = glob.glob(f'{rate}/test[0-9]_rate')
  rps = []
  for file in files:
    with open(file, 'r') as f:
      next(f) # skip first line
      data = f.read()
      #r = int(data.split()[1]) # get reached RPS
      r = int(data.split()[0]) # get offered RPS
      rps.append(r)

  if len(rps) == 0:
    return 0

  return sum(rps)/len(rps)


def get_drop(rate):
  files = glob.glob(f'{rate}/test[0-9]_rate')
  #drops = []
  tot_tx = []
  tot_rx = []
  for file in files:
    with open(file, 'r') as f:
      next(f) # skip header line
      data = f.read()
      #print(data)
      tot_tx.append(int(data.split()[2]))
      tot_rx.append( int(data.split()[3]))

      #r = int(data.split()[-1]) # get drop
      #drops.append(r)

  #return sum(tot_tx) - sum(tot_rx);
  drop_percent = (1 - (sum(tot_rx) / sum(tot_tx))) * 100
  return round(drop_percent, 4)

  #return sum(drops)


def load_in_file_name(f):
  return float(f.split('_')[-1])

def process_get_latencys(pol, slowdown=False):
  x = []

  s_y = []
  l_y = []
  a_y = []

  s_err = []
  l_err = []
  a_err = []

  drops = []

  rates = os.listdir(pol)
  rates = sorted(rates, key=load_in_file_name)

  # get latency to each load
  for rate in rates:
    #tr = int(rate) / 1e6 # Load

    folder = os.path.join(pol, rate)
    print('Reading \'{}\''.format(folder))

    rps = get_rps(folder) / 1e6

    d = get_drop(folder)
    drops.append(d)

    #if d:
    #  print(f'Dropped {drop} pkts in rate {rps} MRPS: Stoping')
    #  break

    ((s, serr), (l, lerr), (a, aerr)) = get_latency(folder, slowdown)

    x.append(rps)

    s_y.append(s)
    s_err.append(serr)

    l_y.append(l)
    l_err.append(lerr)

    a_y.append(a)
    a_err.append(aerr)

  return x,\
    s_y, s_err, \
    l_y, l_err, \
    a_y, a_err, \
    drops
# Function to read the 'test' file in a given rate folder
def read_test_file(test_file: str) -> pd.DataFrame:
    return pd.read_csv(test_file, 
                       sep='\t', 
                       header=None, 
                       names=['type', 'latency', 'slowdown'])

# Function to calculate tail statistics for a given DataFrame
def calculate_per_type_latency(df: pd.DataFrame, percentile: float) -> pd.DataFrame:
    return df.groupby('type', as_index=False)['latency'].quantile(percentile / 100)

def calculate_per_type_slowdown(df: pd.DataFrame, percentile: float) -> pd.DataFrame:
    return df.groupby('type', as_index=False)['slowdown'].quantile(percentile / 100)

# Function to calculate the overall 99th percentile
def calculate_overall_latency(df: pd.DataFrame, percentile: float) -> float:
    return df['latency'].quantile(percentile / 100)

def calculate_overall_slowdown(df: pd.DataFrame, percentile: float) -> float:
    return df['slowdown'].quantile(percentile / 100)

# Process a file with requests latencies
def process_test(rate_folder_path: str, test: str, percentile: float) -> None:
    print(f'Processing {test}')

    # Read the data from the 'test' file
    df = read_test_file(test)

    # Save the overall latency
    overall_percentile = calculate_overall_latency(df, percentile)

    overall_result_filename = f"{test}_all_{percentile}_result"
    overall_result_path = os.path.join(rate_folder_path, overall_result_filename)
    overall_result_df = pd.DataFrame({'latency': [overall_percentile]})
    overall_result_df[['latency']].to_csv(overall_result_path, index=False, header=False)

    # Save slowdown
    overall_slowdown = calculate_overall_slowdown(df, percentile)

    overall_result_filename = f"{test}_all_{percentile}_result_slowdown"
    overall_result_path = os.path.join(rate_folder_path, overall_result_filename)
    overall_result_df = pd.DataFrame({'slowdown': [overall_slowdown]})
    overall_result_df[['slowdown']].to_csv(overall_result_path, index=False, header=False)

    per_type_latency = calculate_per_type_latency(df, percentile)
    per_type_slowdown = calculate_per_type_slowdown(df, percentile)

    TYPES = {1: 'shorts', 2: 'longs'}
    # Save latency by request type
    for _, row in per_type_latency.iterrows():
        Type = int(row['type'])
        latency_value = row['latency']

        result_filename = f"{test}_{TYPES[Type]}_{percentile}_result"
        result_path = os.path.join(rate_folder_path, result_filename)
        pd.DataFrame({'latency': [latency_value]}).to_csv(result_path, index=False, header=False)

    # Save slowdown by request type
    for _, row in per_type_slowdown.iterrows():
        Type = int(row['type'])
        slowdown_value = row['slowdown']

        result_filename = f"{test}_{TYPES[Type]}_{percentile}_result_slowdown"
        result_path = os.path.join(rate_folder_path, result_filename)
        pd.DataFrame({'slowdown': [slowdown_value]}).to_csv(result_path, index=False, header=False)

def process_policy(base_folder: str, force: bool = False) -> None:
  rate_folders = [f for f in os.listdir(base_folder) if os.path.isdir(os.path.join(base_folder, f))]
  rate_folders = sorted(rate_folders, key=lambda x: int(x.split('_')[-1]))

  for rate_folder in rate_folders:

    rate_folder_path = os.path.join(base_folder, rate_folder)
    tests = glob.glob(f'{rate_folder_path}/test[0-9]')

    for test in tests:
      r = glob.glob(f'{test}_*_{percentile}_result')
      if len(r) > 0 and force == False:
        print(f'{test} already processed... skiping...')
        continue

      process_test(rate_folder_path, test, percentile)



import os
import glob
import math

#try:
#import pandas as pd
#except ImportError:
import polars as pd

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

class latencys:
  def __init__(self, percentile):
    self.percentile = percentile
    self.type1_latencys = []
    self.type2_latencys = []
    self.type3_latencys = []
    self.type4_latencys = []
    self.alls_latencys = []

    self.type1_errors = []
    self.type2_errors = []
    self.type3_errors = []
    self.type4_errors = []
    self.alls_errors = []

    # x axie
    self.x = []
    self.drop = []

    self.type_names = [ 'type1', 'type2', 'type3', 'type4', 'all' ]
    self.type_names_err = [ 'type1err', 'type2err', 'type3err', 'type4err', 'allerr' ]
    self.type_latencys = [self.type1_latencys,
                          self.type2_latencys,
                          self.type3_latencys,
                          self.type4_latencys,
                          self.alls_latencys]

    self.type_errors = [self.type1_errors,
                        self.type2_errors,
                        self.type3_errors,
                        self.type4_errors,
                        self.alls_errors]


    self.interrupts_saved = []
    self.cpu_avg = []
    self.cpu_max = []
    self.cpu_min = []

  def process_cpu_usage(self, rate_folder: str):
    try:
       with open(f'{rate_folder}/afp.txt') as f:
         for line in f:
           if line.startswith('CPU:'):
             self.cpu_avg.append(line.split()[1])
             self.cpu_min.append(line.split()[2])
             self.cpu_max.append(line.split()[3])
             break
    except:
      pass


  def process_interupts_saving(self, rate_folder: str):
    interrupts_targed = 0
    interrupts_fired = 0
    interrupts_saved = 0

    try:
      with open(f'{rate_folder}/afp.txt') as f:
        for line in f:
          if 'Interrupts targed:' in line:
            interrupts_targed = int(line.split()[2])
          elif 'Interrupts fired:' in line:
            interrupts_fired = int(line.split()[2])

      if interrupts_targed != 0:
        interrupts_saved = round(1 - (interrupts_fired / interrupts_targed), 4)

      self.interrupts_saved.append(interrupts_saved)
    except:
      pass

  def update(self, rate_folder, rps, drop, slowdown):
    self.x.append(rps)
    self.drop.append(drop)

    for idx, type_name in enumerate(self.type_names):
      tn = type_name
      if slowdown == False:
        files = glob.glob(f'{rate_folder}/test[0-9]*{tn}_{self.percentile}_result')
      else:
        files = glob.glob(f'{rate_folder}/test[0-9]*{tn}_{self.percentile}_result_slowdown')

      temp = []
      for file in files:
        with open(file, 'r') as f:
          v = float(f.read())
          temp.append(v)

      if sum(temp) == 0:
        continue

      latency, error = interval_confidence(temp)
      self.type_latencys[idx].append(latency)
      self.type_errors[idx].append(error)

  def get_dict(self):
    dict_ = {'x': self.x, 'drop': self.drop,
             'interrupts_saved': self.interrupts_saved,
             'cpu_avg': self.cpu_avg,
             'cpu_min': self.cpu_min,
             'cpu_max': self.cpu_max}
    dict_latencys = dict(zip(self.type_names, self.type_latencys))
    dict_errors = dict(zip(self.type_names_err, self.type_errors))
    # merge dicts
    return {**dict_, **dict_latencys, **dict_errors}

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
  tot_tx = []
  tot_rx = []
  for file in files:
    with open(file, 'r') as f:
      next(f) # skip header line
      data = f.read()
      tot_tx.append(int(data.split()[2]))
      tot_rx.append( int(data.split()[3]))

  if sum(tot_rx) == 0:
    return 100

  drop_percent = (1 - (sum(tot_rx) / sum(tot_tx))) * 100
  return round(drop_percent, 4)

#return sum(drops)


def load_in_file_name(f):
  return float(f.split('_')[-1])

# return all information as dict from a policy test processing
# rate, drop, latency or slowdown, error
def process_get_policy_data(pol, slowdown=False):
  rates = os.listdir(pol)
  rates = sorted(rates, key=load_in_file_name)

  latencys_data = latencys(percentile)

  # get latency to each load
  for rate in rates:
    folder = os.path.join(pol, rate)
    print('Reading \'{}\''.format(folder))

    rps = get_rps(folder)
    if rps == 0:
      print('Skipping ', rps)
      continue

    drop = get_drop(folder)
    latencys_data.update(folder, rps, drop, slowdown)

    latencys_data.process_interupts_saving(folder)
    latencys_data.process_cpu_usage(folder)

  return latencys_data.get_dict()

# Function to read the 'test' file in a given rate folder
def read_test_file(test_file: str) -> pd.DataFrame:
  return pd.read_csv(test_file,
                     separator='\t',
                     has_header=False,
                     new_columns=['type', 'latency', 'slowdown'])

# Function to calculate tail statistics for a given DataFrame
def calculate_per_type_latency(df: pd.DataFrame, percentile: float) -> pd.DataFrame:
  #return df.groupby('type', as_index=False)['latency'].quantile(percentile / 100)
  return df.group_by('type').agg(pd.col('latency').quantile(float(percentile/100)))

def calculate_per_type_slowdown(df: pd.DataFrame, percentile: float) -> pd.DataFrame:
  #return df.groupby('type', as_index=False)['slowdown'].quantile(percentile / 100)
  return df.group_by('type').agg(pd.col('slowdown').quantile(float(percentile/100)))

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
  overall_result_df[['latency']].write_csv(overall_result_path, include_header=False)

  # Save slowdown
  overall_slowdown = calculate_overall_slowdown(df, percentile)

  overall_result_filename = f"{test}_all_{percentile}_result_slowdown"
  overall_result_path = os.path.join(rate_folder_path, overall_result_filename)
  overall_result_df = pd.DataFrame({'slowdown': [overall_slowdown]})
  overall_result_df[['slowdown']].write_csv(overall_result_path, include_header=False)

  per_type_latency = calculate_per_type_latency(df, percentile)
  per_type_slowdown = calculate_per_type_slowdown(df, percentile)

  TYPES = {1: 'type1', 2: 'type2', 3: 'type3', 4: 'type4'}
  # Save latency by request type
  for Type in per_type_latency['type'].to_list():
    # Get the 99th percentile value for the current group
    group_df = per_type_latency.filter(pd.col('type') == Type)
    group_df_slowdown = per_type_slowdown.filter(pd.col('type') == Type)

    result_filename = f"{test}_{TYPES[Type]}_{percentile}_result"
    result_path = os.path.join(rate_folder_path, result_filename)
    group_df.select('latency').write_csv(result_path, include_header=False)

    result_filename = f"{test}_{TYPES[Type]}_{percentile}_result_slowdown"
    result_path = os.path.join(rate_folder_path, result_filename)
    group_df_slowdown.select('slowdown').write_csv(result_path, include_header=False)




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


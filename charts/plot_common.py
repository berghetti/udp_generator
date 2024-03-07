#!/bin/python3

import os
import glob
import math
import numpy as np
from threading import Thread, Lock

def interval_confidence( data ):
  Z = 1.96 # nivel de confiança 95%
  avg = sum(data) / len(data)

  sum_ = 0
  for i in range(len(data)):
    sum_ += math.pow( data[i] - avg, 2 )

  desvio = math.sqrt( sum_ / len(data) )
  margin_error = Z * ( desvio / math.sqrt(len(data) ) ) # intervalo de confiança

  avg = round(avg, 4)
  margin_error = round(margin_error, 4)
  return avg, margin_error

percentile = 99.9

def process_test(test):
  SHORT=1
  LONG=2

  s = []
  l = []
  a = []
  print(f'Reading {test}')
  with open(test) as f:

    for line in f:
      data = line.split()
      typo = int(data[0])
      latency = int(data[1])

      latency /= 1000 #us

      a.append(latency) # all

      if typo == SHORT:
        s.append(latency)
      elif typo == LONG:
        l.append(latency)
      else:
        exit('Unknow request type')

  if len(a) == 0:
    print(f'Error fo read {file}')
    return

  global percentile
  s_percentile = np.percentile(s, percentile) if len(s) > 0 else 0
  l_percentile = np.percentile(l, percentile) if len(l) > 0 else 0
  a_percentile = np.percentile(a, percentile)

  p = {
    'shorts': s_percentile,
    'longs': l_percentile,
    'all': a_percentile,
  }

  for t in 'shorts', 'longs', 'all':
    with open(f'{test}_{t}_{percentile}_result', 'w') as f:
      f.write(f'{p[t]}')

  print(f'Finished {test}')

def process_rate(rate):
    print(f'Reading {rate}')

    tests = glob.glob(f'{rate}/test[0-9]')
    threads = []
    for test in tests:
      r = glob.glob(f'{test}_*_{percentile}_result')
      if len(r) > 0:
        print(f'{test} already processed... skiping...')
        continue

      thread = Thread(target=process_test, args=(test,))
      thread.start()
      threads.append(thread)

    for thread in threads:
      thread.join()


def process_policy(pol):
  print(f'Processing: {pol}')

  rates = os.listdir(pol)
  rates = sorted(rates, key=load_in_file_name)

  threads = []
  for rate in rates:
    thread = Thread(target=process_rate, args=(os.path.join(pol, rate),) )
    thread.start()
    threads.append(thread)

  for thread in threads:
    thread.join()


def get_latency(rate):
  shorts = []
  longs = []
  alls = []
  p = {
    'shorts': shorts,
    'longs': longs,
    'all': alls,
  }

  for t in 'shorts', 'longs', 'all':
    files = glob.glob(f'{rate}/test[0-9]*{t}_{percentile}_result')
    for file in files:
      with open(file, 'r') as f:
        v = float(f.read())
        p[t].append(v)


  print(shorts, longs, alls)
  return interval_confidence(shorts), \
      interval_confidence(longs), \
       interval_confidence(alls)

def load_in_file_name(f):
  return float(f.split('_')[-1])

def get_latencys(pol):
  x = []

  s_y = []
  l_y = []
  a_y = []

  s_err = []
  l_err = []
  a_err = []

  rates = os.listdir(pol)
  rates = sorted(rates, key=load_in_file_name)

  # get latency to each load
  for rate in rates:
    tr = int(rate) / 1e6 # Load

    folder = os.path.join(pol, rate)

    print('Reading \'{}\''.format(folder))

    ((s, serr), (l, lerr), (a, aerr)) = get_latency(folder)
    print(s, l, a)

    x.append(tr)

    s_y.append(s)
    s_err.append(serr)

    l_y.append(l)
    l_err.append(lerr)

    a_y.append(a)
    a_err.append(aerr)

  return x,\
      s_y, s_err, \
      l_y, l_err, \
      a_y, a_err


def get_policy_name(policy):
  return policy.rstrip('/').split('/')[-1]


def get_styles(name):
  styles = {
    'rss-cl0' : {
    'color': 'red',
    'ls': '--',
    'm': '*',
    },
    'afp-cl0' : {
    'color': 'blue',
    'ls': '-',
    'm': '*',
    },
    'afp-cl50': {
    'color': 'blue',
    'ls': '--',
    'm': 'v',
    },
    'afp-cl100': {
    'color': 'blue',
    'ls': '-.',
    'm': '<',
    },
    'afp-ws': {
    'color': 'blue',
	'ls': ':',
    'm': '1',
    },
    'psp-cl0': {
    'color': 'orange',
    'ls': '-',
    'm': '3',
    },
    'psp-cl50': {
    'color': 'orange',
    'ls': '--',
    'm': '4',
    },
    'psp-cl100': {
    'color': 'orange',
    'ls': '-.',
    'm': 'd',
    },
  }

  return list(styles[name].values())

def get_metadata_name(wk, percentil):
  file = f'{wk}_{percentil}_meta.dat'
  return file

def get_and_set_percentile(p):
  PERCENTILES = {'p999': 99.9, 'p99': 99.0, 'p90': 90.0, 'p50': 50.0}
  global percentile
  percentile = PERCENTILES[p]
  return PERCENTILES[p]


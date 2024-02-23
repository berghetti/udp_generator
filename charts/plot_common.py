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

lock = Lock()
shorts = []
longs = []
alls = []

percentile = 99.9

def get_latency_thread(file, cpu):
  mask = {cpu}
  os.sched_setaffinity(os.getpid(), mask)
  SHORT=1
  LONG=2

  s = []
  l = []
  a = []
  with open(file, buffering=4096) as f:
    #next(f) # skip header

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

  global percentile
  s_percentile = np.percentile(s, percentile) if len(s) > 0 else -100
  l_percentile = np.percentile(l, percentile) if len(l) > 0 else -100
  a_percentile = np.percentile(a, percentile) if len(a) > 0 else -100

  global shorts, longs, alls
  with lock:
    shorts.append( s_percentile )
    longs.append( l_percentile )
    alls.append( a_percentile )

def get_latency(folder):
  global shorts, longs, alls
  shorts = []
  longs = []
  alls = []

  #files = os.listdir(folder)
  files = glob.glob(f'{folder}/test*')
  threads = []
  for i, file in enumerate(files):
    thread = Thread(target=get_latency_thread, args=(os.path.join(folder, file), i  + 1) )
    thread.start()
    threads.append(thread)

  for thread in threads:
    thread.join()

  print(shorts, longs, alls)
  return interval_confidence(shorts), \
          interval_confidence(longs), \
          interval_confidence(alls)

def load_in_file_name(f):
  return float(f.split('_')[-1])

def get_latencys(folder_tests, p):
  global percentile
  percentile = p

  x = []

  s_y = []
  l_y = []
  a_y = []

  s_err = []
  l_err = []
  a_err = []

  folders = os.listdir(folder_tests)
  folders = sorted(folders, key=load_in_file_name)

  # get latency to each load
  for folder in folders:
    tr = int(folder) / 1e6 # Load

    folder = os.path.join(folder_tests, folder)

    print('Reading \'{}\''.format(folder))

    ((s, serr), (l, lerr), (a, aerr))  = get_latency(folder)
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
  return policy.split('/')[-1]


def get_styles(name):
  styles = {
      'afp' : {
        'color': 'blue',
        'ls': '-',
        'm': '*',
        },
      'afp-ws': {
        'color': 'red',
        'ls': '--',
        'm': '+',
        },
      'psp-cl0': {
        'color': 'orange',
        'ls': '-.',
        'm': '2',
        },
  }

  return list(styles[name].values())

#!/bin/python3

import json
import sys
from plot_common import *

def get_policy(data, name):
  for pol in data:
    n = list(pol.keys())[0]
    if n == name:
      return pol

def update(policy, rate, wk, percent):
  file = get_metadata_name(wk, percent)
  with open(file, 'r') as f:
      data = json.load(f)

  global percentile
  percentile = get_percentile(percent)

  ((s, serr), (l, lerr), (a, aerr)) = get_latency(f'{policy}/{rate}')

  name = get_policy_name(policy)
  p = get_policy(data, name)

  index = p[name]['x'].index( int(rate) / 1e6 )

  p[name]['s'][index] = s
  p[name]['serr'][index] = serr

  p[name]['l'][index] = l
  p[name]['lerr'][index] = lerr

  p[name]['a'][index] = a
  p[name]['aerr'][index] = aerr

  with open(file, 'w') as f:
    json.dump(data, f)


if __name__ == '__main__':

  wk = sys.argv[1]
  percentil = sys.argv[2]
  policy = sys.argv[3]
  rate = sys.argv[4]

  update(policy, rate, wk, percentil)

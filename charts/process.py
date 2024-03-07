#!/bin/python3

import os
import sys
import json

from plot_common import *
import charts_templates

def write_metadata(policys, file):

  data = []
  for policy in policys:
    name = get_policy_name(policy)

    x, s, serr, l, lerr, a, aerr = get_latencys(policy)
    d = {
        name : {
          'x' : x,
          's': s,
          'serr': serr,
          'l': l,
          'lerr': lerr,
          'a': a,
          'aerr': aerr
          }
        }

    data.append(d)
  with open(file, 'w') as f:
    json.dump(data, f)

def read_metadata(file, name):

  with open(file, 'r') as f:
    data = json.load(f)

  for pol in data:
    n = list(pol.keys())[0]
    if n == name:
      return pol

def process(policys, prefix, percentil):
  p = get_and_set_percentile(percentil)
  file = get_metadata_name(prefix, percentil)

  print('Processing policys')
  for policy in policys:
    process_policy(policy)

  print(f'\nWriting metadata {file}')
  write_metadata(policys, file)


if __name__ == '__main__':

  prefix = sys.argv[1]

  percentil = sys.argv[2]

  process(sys.argv[3:], prefix, percentil)


#!/bin/python3

# process policys and create metadata file with latencys to each policy and request type

import os
import sys
import json

from plot_common import *
from process_common import process_get_policy_name, process_get_metadata_name, process_get_and_set_percentile, process_policy, process_get_latencys

import charts_templates

def write_metadata(policys, file):

  data = []
  for policy in policys:
    name = process_get_policy_name(policy)

    x, s, serr, l, lerr, a, aerr = process_get_latencys(policy)
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

def process(policys, prefix, percentil):
  p = process_get_and_set_percentile(percentil)

  # calc latency for each policy
  for policy in policys:
    process_policy(policy)

  # write metadata file with policys and latencys.
  # This file is used to chart plot after.
  file = process_get_metadata_name(prefix, percentil)
  print(f'\nWriting metadata {file}')
  write_metadata(policys, file)


if __name__ == '__main__':

  prefix = sys.argv[1]

  percentil = sys.argv[2]

  process(sys.argv[3:], prefix, percentil)


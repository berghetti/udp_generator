#!/usr/bin/env python3.8

# process policys and create metadata file with latencys to each policy and request type

import os
import sys
import json5 as json

from process_common import process_get_policy_name, process_get_metadata_name, process_get_and_set_percentile, process_policy, process_get_policy_data

def remove_if_present(name, data):
  for i, pol in enumerate(data):
    if name == list(pol.keys())[0]:
      del data[i]

def write_metadata(policys, file, concat=True):

  latencys = []
  slowdowns = []
  if (concat):
    try:
      f = open(file, 'r')
      f2 = open(f'{file}.slowdown', 'r')
    except:
      pass
    else:
      with f:
       latencys = json.load(f)
       slowdowns = json.load(f2)

  for policy in policys:
    name = process_get_policy_name(policy)

    #update data if already present in file
    remove_if_present(name, latencys)
    remove_if_present(name, slowdowns)

    data = process_get_policy_data(policy, slowdown=False)
    pol = { name : data }
    latencys.append(pol)

    data = process_get_policy_data(policy, slowdown=True)
    pol = { name : data }
    slowdowns.append(pol)

  with open(file, 'w') as f:
    json.dump(latencys, f)

  with open(f'{file}.slowdown', 'w') as f:
    json.dump(slowdowns, f)

def process(policys, prefix, percentil):
  p = process_get_and_set_percentile(percentil)

  # calc latency for each policy
  for policy in policys:
    process_policy(policy, force=True)

  # write metadata file with policys and latencys.
  # This file is used to chart plot after.
  file = process_get_metadata_name(prefix, percentil)
  print(f'\nWriting metadata {file}')
  write_metadata(policys, file)


if __name__ == '__main__':

  # only a identifier to this test
  prefix = sys.argv[1]

  percentil = sys.argv[2]

  process(sys.argv[3:], prefix, percentil)


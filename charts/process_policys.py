#!/bin/python3

# process policys and create metadata file with latencys to each policy and request type

import os
import sys
import json

from process_common import process_get_policy_name, process_get_metadata_name, process_get_and_set_percentile, process_policy, process_get_latencys

def remove_if_present(name, data):
  for i, pol in enumerate(data):
    if name == list(pol.keys())[0]:
      del data[i]

def write_metadata(policys, file, concat=True):

  data = []
  if (concat):
    with open(file, 'r') as f:
      data = json.load(f)


  for policy in policys:
    name = process_get_policy_name(policy)

    #update data if already present in file
    remove_if_present(name, data)

    x, s, serr, l, lerr, a, aerr, drop = process_get_latencys(policy)
    d = {
        name : {
          'x' : x,
          's': s,
          'serr': serr,
          'l': l,
          'lerr': lerr,
          'a': a,
          'aerr': aerr,
          'drop': drop
          }
        }

    data.append(d)
  with open(file, 'w') as f:
    json.dump(data, f)

def process(policys, prefix, percentil):
  p = process_get_and_set_percentile(percentil)

  # calc latency for each policy
  for policy in policys:
    process_policy(policy, force=False)

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


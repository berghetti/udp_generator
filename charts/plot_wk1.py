#!/bin/python3

import os
import sys
import json

import charts
from plot_common import get_latencys, get_policy_name, get_styles
import charts_templates

PERCENTILES = {'p999': 99.9, 'p99': 99.0, 'p90': 90.0, 'p50': 50.0}

def exist(name, data):
  for pol in data:
    for key, value in pol.items():
      if key == name:
        return True

  return False

def write_metadata(policys, file, p, force=False):

  try:
    with open(file, 'r') as f:
      data = json.load(f)
  except:
    data = []

  for policy in policys:
    name = get_policy_name(policy)

    if not exist(name, data):
      print('here')
      x, s, serr, l, lerr, a, aerr = get_latencys(policy, p)
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


def read_metadata(file):

  with open(file, 'r') as f:
    data = json.load(f)

  return data

def plot_charts(policys, pname, percentil):

  p = PERCENTILES[percentil]
  file = f'{percentil}_meta.dat'

  config = charts_templates.get_config_template()

  write_metadata(policys, file, p)

  dataset_shorts = []
  dataset_longs = []
  dataset_alls = []

  data = read_metadata(file)
  for policy in data:
    name = list(policy.keys())[0]
    x, s, serr, l, lerr, a, aerr = policy[name].values()
    #print(x, s, serr, l, lerr, a, aerr)

    color, ls, m = get_styles(name)

    dataset_shorts.append(charts_templates.entry_dataset(x, s, serr, name, m, ls, color))
    dataset_longs.append(charts_templates.entry_dataset(x, l, lerr, name, m, ls, color))
    dataset_alls.append(charts_templates.entry_dataset(x, a, aerr, name, m, ls, color))


  config['datasets'] = dataset_shorts
  config['ylim'] = [0, 300]
  config['save'] = f'imgs/{pname}_{percentil}_shorts.pdf'
  charts.line(config)

  config['datasets'] = dataset_longs
  config['ylim'] = [0, 1000]
  config['set_ticks']['ymajor'] = 100
  config['save'] = f'imgs/{pname}_{percentil}_longs.pdf'
  charts.line(config)

  config['datasets'] = dataset_alls
  config['ylim'] = [0, 1000]
  config['set_ticks']['ymajor'] = 100
  config['save'] = f'imgs/{pname}_{percentil}_all.pdf'
  charts.line(config)


if __name__ == '__main__':

  name = sys.argv[1]

  percentil = sys.argv[2]

  plot_charts(sys.argv[3:], name, percentil)


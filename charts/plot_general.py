#!/bin/python3

import os
import sys
import json

import charts
from plot_common import *
import charts_templates

def get_pol_data(metadata, name):

  with open(metadata, 'r') as f:
    data = json.load(f)

  for pol in data:
    n = list(pol.keys())[0]
    if n == name:
      return pol

  return None

def plot_from_meta(meta_file):

  workload_name = meta_file.split('_')[0]
  percentil = meta_file.split('_')[1]

  data = []
  with open(meta_file, 'r') as f:
    data = json.load(f)

  dataset_shorts = []
  dataset_longs = []
  dataset_alls = []

  for policy in data:
    name = list(policy.keys())[0]

    print(name)
    x = policy[name]['x']
    s = policy[name]['s']
    serr = policy[name]['serr']
    l = policy[name]['l']
    lerr = policy[name]['lerr']
    a = policy[name]['a']
    aerr = policy[name]['aerr']

    color, ls, m = get_styles(name)

    dataset_shorts.append(
      charts_templates.entry_dataset(x, s, serr, name, m, ls, color))

    dataset_longs.append(
      charts_templates.entry_dataset(x, l, lerr, name, m, ls, color))

    dataset_alls.append(
      charts_templates.entry_dataset(x, a, aerr, name, m, ls, color))

  config = charts_templates.get_config_template()

  config['datasets'] = dataset_shorts
  config['ylim'] = [0, 300]
  config['set_ticks']['ymajor'] = 50
  config['save'] = f'imgs/{workload_name}_{percentil}_shorts.pdf'
  charts.line(config)

  config['datasets'] = dataset_longs
  config['ylim'] = [0, 3500]
  config['set_ticks']['ymajor'] = 500
  config['save'] = f'imgs/{workload_name}_{percentil}_longs.pdf'
  charts.line(config)

  config['datasets'] = dataset_alls
  config['ylim'] = [0, 1000]
  config['set_ticks']['ymajor'] = 100
  config['save'] = f'imgs/{workload_name}_{percentil}_all.pdf'
  charts.line(config)

if __name__ == '__main__':
  plot_from_meta(sys.argv[1])


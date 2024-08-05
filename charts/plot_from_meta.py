#!/bin/python3

import os
import sys
import json

import charts
from plot_common import *
import charts_templates

workload_name = ''
percentil = ''

def plot_shorts(dataset):
  config = charts_templates.get_config_template()

  config['datasets'] = dataset
  config['ylim'] = [0, 300]
  config['set_ticks']['ymajor'] = 25
  config['save'] = f'imgs/{workload_name}_{percentil}_shorts.pdf'
  charts.line(config)

def plot_longs(dataset):
  config = charts_templates.get_config_template()
  config['datasets'] = dataset
  config['ylim'] = [0, 3500]
  config['set_ticks']['ymajor'] = 500
  config['save'] = f'imgs/{workload_name}_{percentil}_longs.pdf'
  charts.line(config)

def plot_alls(dataset):
  config = charts_templates.get_config_template()
  config['datasets'] = dataset
  config['ylim'] = [0, 1000]
  config['set_ticks']['ymajor'] = 100
  config['save'] = f'imgs/{workload_name}_{percentil}_all.pdf'
  charts.line(config)

def plot_drop(dataset):
  config = charts_templates.get_config_template()
  config['datasets'] = dataset
  config['ylabel'] = 'Drops'
  config['ylim'] = [0, 500]
  config['set_ticks']['ymajor'] = 100
  config['save'] = f'imgs/{workload_name}_drops.pdf'
  charts.line(config)

def plot_from_meta(meta_file):

  global workload_name, percentil
  workload_name = meta_file.split('_')[0]
  percentil = meta_file.split('_')[1]

  data = []
  with open(meta_file, 'r') as f:
    data = json.load(f)

  dataset_shorts = []
  dataset_longs = []
  dataset_alls = []
  drops = []

  for policy in data:
    name = list(policy.keys())[0]

    print(name)
    x = policy[name]['x']
    s = [value / 1000 for value in policy[name]['s'] ]
    serr = [value / 1000 for value in policy[name]['serr'] ]
    l = [value / 1000 for value in policy[name]['l'] ]
    lerr = [value / 1000 for value in policy[name]['lerr'] ]
    a = [value / 1000 for value in policy[name]['a'] ]
    aerr = [value / 1000 for value in policy[name]['aerr'] ]

    drop = policy[name]['drop']

    color, ls, m = get_styles(name)

    dataset_shorts.append(
      charts_templates.entry_dataset(x, s, serr, name, m, ls, color))

    dataset_longs.append(
      charts_templates.entry_dataset(x, l, lerr, name, m, ls, color))

    dataset_alls.append(
      charts_templates.entry_dataset(x, a, aerr, name, m, ls, color))

    drops.append(
      charts_templates.entry_dataset(x, drop, [0], name, m, ls, color))


  plot_shorts(dataset_shorts)
  plot_longs(dataset_longs)
  plot_alls(dataset_alls)
  plot_drop(drops)


if __name__ == '__main__':
  plot_from_meta(sys.argv[1])


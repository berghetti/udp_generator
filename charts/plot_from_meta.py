#!/bin/python3

import os
import sys
import json

import charts
import charts_templates

workload_name = ''
percentil = ''

def get_styles(name):
  if "afp" in name:
    return 'blue', '--', '*'

  if "psp" in name:
    return 'orange', '-', '>'

  if "rss" in name:
    return 'red', '--', '<'

  if "cfcfs" in name:
    return 'green', '-.', '<'


def plot_shorts(dataset):
  line = charts.line(dataset)
  line.update_config({
    'ylim': [0, 300],
    'set_ticks': {
      'xmajor': 1,
      'xminor': 0,
      'ymajor': 25,
      'yminor': 0,
    },
    'save': f'imgs/{workload_name}_{percentil}_shorts.pdf'
  })
  line.run()

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
  #plot_longs(dataset_longs)
  #plot_alls(dataset_alls)
  #plot_drop(drops)


if __name__ == '__main__':
  plot_from_meta(sys.argv[1])


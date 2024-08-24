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
  line = charts.line(dataset)
  line.update_config({
    'ylim': [0, 2000],
    'set_ticks': {
      'xmajor': 1,
      'xminor': 0,
      'ymajor': 500,
      'yminor': 250,
    },
    'save': f'imgs/{workload_name}_{percentil}_longs.pdf'
  })
  line.run()

def plot_alls(dataset):
  line = charts.line(dataset)
  line.update_config({
    'ylim': [0, 1000],
    'set_ticks': {
      'xmajor': 1,
      'xminor': 0,
      'ymajor': 100,
      'yminor': 50,
    },
    'save': f'imgs/{workload_name}_{percentil}_alls.pdf'
  })
  line.run()

def plot_drop(dataset):
  line = charts.line(dataset)
  line.update_config({
    'ylim': [0, 500],
    'ylabel': 'Packets Dropped',
    'set_ticks': {
      'xmajor': 1,
      'xminor': 0,
      'ymajor': 100,
      'yminor': 50,
    },
    'save': f'imgs/{workload_name}_{percentil}_drops.pdf'
  })
  line.run()

def get_datasets_from_meta(meta_file):

  global workload_name, percentil
  workload_name = meta_file.split('_')[1]
  percentil = meta_file.split('_')[-2]

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

  return dataset_shorts, dataset_longs, dataset_alls, drops

def create_multax_dataset(files):
  d_s = {}
  d_l = {}
  d_a = {}

  for file in files:
    percentil = str(file.split('_')[-2])

    if percentil == 'p999':
      percentil = 'Percentil 99.9% ($\mu$s)'
    elif percentil == 'p50':
      percentil = 'Median ($\mu$s)'
    else:
      continue

    if percentil not in d_s:
      d_s[percentil] = []
    if percentil not in d_l:
      d_l[percentil] = []
    if percentil not in d_a:
      d_a[percentil] = []

    ds, dl, da, _ = get_datasets_from_meta(file)

    d_s[percentil] += ds
    d_l[percentil] += dl
    d_a[percentil] += da

  return d_s, d_l, d_a

def plot_from_files(files):
  ds, dl, da = create_multax_dataset(files)

  chart = charts.multrows_line(ds)
  chart.update_config({
    'ylim': [0, 300],
    'set_ticks': {
      'xmajor': 1,
      'xminor': 0,
      'ymajor': 25,
      'yminor': 0,
    },
    'save': f'imgs/{workload_name}_{percentil}_shorts.pdf'
  })
  chart.run()

if __name__ == '__main__':
  plot_from_files(sys.argv[1:])


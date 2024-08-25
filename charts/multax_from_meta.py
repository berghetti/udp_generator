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
    return 'blue', '--', 'o'

  if "psp" in name:
    return 'orange', ':', '^'

  if "rss" in name:
    return 'red', '--', 'x'

  if "cfcfs" in name:
    return 'green', '-.', 's'

def get_index_first_non_zero(array: list):
  return next((i for i, x in enumerate(array) if x != 0), None)

def get_datasets_from_meta(meta_file, discard_drop=True):

  global workload_name, percentil
  workload_name = "_".join(meta_file.split('_')[:-2])
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
    drop = policy[name]['drop']

    if discard_drop:
      idx_drop_start = get_index_first_non_zero(drop)
    else:
      idx_drop_start = None

    x = policy[name]['x'][:idx_drop_start]
    x = [value * 1000 for value in x] #scale x
    s = [value / 1000 for value in policy[name]['s'] ][:idx_drop_start]
    serr = [value / 1000 for value in policy[name]['serr'] ][:idx_drop_start]
    l = [value / 1000 for value in policy[name]['l'] ][:idx_drop_start]
    lerr = [value / 1000 for value in policy[name]['lerr'] ][:idx_drop_start]
    a = [value / 1000 for value in policy[name]['a'] ][:idx_drop_start]
    aerr = [value / 1000 for value in policy[name]['aerr'] ][:idx_drop_start]
    drop = drop[:idx_drop_start]

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
      percentil = 'p99.9% ($\mu$s)'
    elif percentil == 'p99':
      percentil = 'p99% ($\mu$s)'
    elif percentil == 'p50':
      percentil = 'median ($\mu$s)'
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

def plot_shorts(dataset):
  chart = charts.multrows_line(dataset)
  chart.update_config({
    'ylim': [0, 300],
    'xlim': [0, 89],
    'ylabel': '',
    'set_ticks': {
      'xmajor': 10,
      'xminor': 5,
      'ymajor': 50,
      'yminor': 25,
    },
  'title':{
      'label': f'{workload_name} get',
      'loc': 'center'
  },
    'save': f'imgs/{workload_name}_shorts.pdf'
  })
  chart.run()

def plot_longs(dataset):
  chart = charts.multrows_line(dataset)
  chart.update_config({
    'ylim': [0, 2000],
    'xlim': [0, 89],
    'ylabel': '',
    'set_ticks': {
      'xmajor': 10,
      'xminor': 5,
      'ymajor': 500,
      'yminor': 250,
    },
  'title':{
      'label': f'{workload_name} scan',
      'loc': 'center'
  },
    'save': f'imgs/{workload_name}_longs.pdf'
  })
  chart.run()

def plot_alls(dataset):
  chart = charts.multrows_line(dataset)
  chart.update_config({
    'ylim': [0, 500],
    'xlim': [0, 89],
    'ylabel': '',
    'set_ticks': {
      'xmajor': 10,
      'xminor': 5,
      'ymajor': 100,
      'yminor': 0,
    },
  'title':{
      'label': f'{workload_name} all',
      'loc': 'center'
  },
    'save': f'imgs/{workload_name}_all.pdf'
  })
  chart.run()

def plot_from_files(files):
  ds, dl, da = create_multax_dataset(files)

  plot_shorts(ds)
  plot_longs(dl)
  plot_alls(da)


if __name__ == '__main__':
  plot_from_files(sys.argv[1:])


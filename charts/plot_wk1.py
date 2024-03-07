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

def plot_charts(policys, pname, percentil):
  p = get_and_set_percentile(percentil)
  file = get_metadata_name(pname, percentil)

  config = charts_templates.get_config_template()
  config['ylabel'] = f'Lat. p{p} ($\mu$s)'

  dataset_shorts = []
  dataset_longs = []
  dataset_alls = []

  for policy in policys:
    name = get_policy_name(policy)
    pol = get_pol_data(file, name)
    
    if pol == None:
        print(f'Name {name} not found in metada file')
        continue

    dict_values = list(pol.values())[0]
    
    x, s, serr, l, lerr, a, aerr = dict_values.values()
    print(name)
    print(x, s, serr, l, lerr, a, aerr)

    color, ls, m = get_styles(name)

    dataset_shorts.append(charts_templates.entry_dataset(x, s, serr, name, m, ls, color))
    dataset_longs.append(charts_templates.entry_dataset(x, l, lerr, name, m, ls, color))
    dataset_alls.append(charts_templates.entry_dataset(x, a, aerr, name, m, ls, color))


  config['datasets'] = dataset_shorts
  config['ylim'] = [0, 300]
  config['set_ticks']['ymajor'] = 50
  config['save'] = f'imgs/{pname}_{percentil}_shorts.pdf'
  charts.line(config)

  config['datasets'] = dataset_longs
  config['ylim'] = [0, 3500]
  config['set_ticks']['ymajor'] = 500
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


#!/bin/python3

import os
import sys
import json

if __name__ == '__main__':
  data = []
  with open(sys.argv[1], 'r') as f:
    data = json.load(f)

  for pol in data:
    name = list(pol.keys())[0]
    x = pol[name]['x']
    s = pol[name]['s']
    serr = pol[name]['serr']
    l = pol[name]['l']
    lerr = pol[name]['lerr']
    a = pol[name]['a']
    drop = pol[name]['drop']

    print(name)
    print(f'  x: {x}')
    print(f'  shorts: {s}')
    print(f'  shorts err: {serr}')
    print(f'  longs: {l}')
    print(f'  longs err: {lerr}')
    print(f'  alls: {a}')
    print(f'  drop: {drop}\n')


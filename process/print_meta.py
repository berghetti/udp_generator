#!/usr/bin/env python3.8

import os
import sys
import json5 as json

if __name__ == '__main__':
  pols = []
  with open(sys.argv[1], 'r') as f:
    pols = json.load(f)

  skip = ['type1err','type2err','type3err','type4err']

  for pol in pols:
    name = list(pol.keys())[0]
    print(name)
    for attr in pol[name].keys():
      if str(attr) not in skip:
        print(f'  {attr}: {pol[name][attr]}')
    print()

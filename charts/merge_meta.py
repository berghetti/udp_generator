#!/bin/python3

import os
import sys
import json5 as json

if __name__ == '__main__':
  data = []
  with open(sys.argv[1], 'r') as f:
    data = json.load(f)
  
  data2 = []
  with open(sys.argv[2], 'r') as f:
    data2 = json.load(f)

  with open(sys.argv[3], 'w') as f:
    json.dump(data + data2, f)


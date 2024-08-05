#!/bin/python3

def get_styles(name):
  if "afp" in name:
    return 'blue', '--', '*'

  if "psp" in name:
    return 'orange', '-', '>'

  if "rss" in name:
    return 'red', '--', '<'
  #styles = {
  #  'rss-cl0' : {
  #    'color': 'red',
  #    'ls': '--',
  #    'm': '*',
  #  },
  #  'afp-cl0' : {
  #    'color': 'blue',
  #    'ls': '-',
  #    'm': '*',
  #  },
  #  'afp-cl50': {
  #    'color': 'blue',
  #    'ls': '--',
  #    'm': 'v',
  #  },
  #  'afp-cl100': {
  #    'color': 'blue',
  #    'ls': '-.',
  #    'm': '<',
  #  },
  #  'afp-cl0-ws': {
  #    'color': 'blue',
  #    'ls': ':',
  #    'm': '1',
  #  },
  #  'psp-cl0': {
  #    'color': 'orange',
  #    'ls': '-',
  #    'm': '3',
  #  },
  #  'psp-cl50': {
  #    'color': 'orange',
  #    'ls': '--',
  #    'm': '4',
  #  },
  #  'psp-cl100': {
  #    'color': 'orange',
  #    'ls': '-.',
  #    'm': 'd',
  #  },
  #}

  #return list(styles[name].values())



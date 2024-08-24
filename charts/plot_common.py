#!/bin/python3

def get_styles(name):
  if "afp" in name:
    return 'blue', '--', '*'

  if "psp" in name:
    return 'orange', '-', '>'

  if "rss" in name:
    return 'red', '--', '<'



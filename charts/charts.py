#!/bin/python3

import matplotlib.pyplot as plt
from matplotlib.ticker import (MultipleLocator, AutoMinorLocator)
from matplotlib.ticker import FuncFormatter

import charts_templates

DEFAULT_CONFIG = {
  #'mult_datasets': rows,
  #'datasets': datasets,
  'xlabel': 'Throughput (Mreqs/s)',
  'ylabel': '99.9 lat. ($\mu$s)',

  'font': {
    'font.size':20,
    'axes.labelsize': 20,
    'axes.titlesize': 20,
    'xtick.labelsize': 20,
    'ytick.labelsize': 20,
  },

  'grid': {
    'visible' : True,
    'which': 'major',
    'style' : {
      'color': '#ccc',
      'linestyle': '--',
      'linewidth': 0.2
    },
  },

  'set_ticks': {
    'xmajor': 1,
    'xminor': 0,
    'ymajor': 50,
    'yminor': 0,
  },

  'legend': {
    #'loc': 'upper center',
    'loc': 'upper left',
    #'loc': 'best',
    'bbox_to_anchor': (0, 1.15, 1, 0.2),
    'title_fontsize' : 12,
    'fontsize': 18,
    'ncol': 4,
    'mode': 'expand',
    'frameon': False,
  },

  #'title':{
  #    #'label': '{} requests'.format(TYPE).capitalize(),
  #    'loc': 'center'
  #},

  'ylim': [0, 100],
  'xlim': [0, 100],  # max(overhead) + 10],
  'save': 'default_save_name',
  'save': '',
  'show': 'n',
}

class chart:
  def __init__(self, config, multrows=False):
    self.config = config
    self.multrows = multrows

  def update_config(self, new_config: dict):
    self.config.update(new_config)

  def run(self):
    # should be first
    if self.config['font']:
      self.font(self.config['font'])
    #  #del config['font']

    if not self.multrows:
      #self.fig, self.ax = plt.subplots(figsize=(9.0, 4.1), dpi=300) # fig 1
      self.fig, self.ax = plt.subplots(figsize=(9.0, 6.0), dpi=300)
      self.config['datasets'] = self.config.pop('datasets')
    else:
      len_rows = len(self.config['mult_datasets'])
      #self.fig, self.ax = plt.subplots(len_rows, 1, figsize=(9.0, 6.0), dpi=300, sharex=True, sharey=True)
      self.fig, self.ax = plt.subplots(len_rows, 1, figsize=(8.0, 8.0), dpi=300, sharex=True, sharey=False)
      # hack subscriptable ax
      if len_rows == 1:
        self.ax = [self.ax]

      self.config['mult_datasets'] = self.config.pop('mult_datasets')

    #the order matters, leave the dataset second to last and show last
    #self.config['rows'] = self.config.pop('rows')
    if self.config['legend']:
      self.config['legend'] = self.config.pop('legend')

    if 'show' in self.config:
      self.config['show'] = self.config.pop('show')

    if 'save' in self.config:
      self.config['save'] = self.config.pop('save')

    # magic, call all functions in config dict
    for func, value in self.config.items():
      if not value:
        continue
      # print(func)
      try:
        f = getattr(self, func)
        f(value)
      except Exception as err:
        print('Error {}: {}'.format(func, err))
        pass

  def font(self, v):
    plt.rcParams.update(v)
    plt.rcParams['axes.formatter.use_locale'] = True

  def datasets(self, v):
    pass

  def mult_datasets(self, v):
    pass

  def title(self, v):
    self.ax.set_title(**v)

  def set_axisbelow(self, v):
    self.ax.set_axisbelow(v)

  def set_ticks(self, v):
    if v['xmajor']:
      self.ax.xaxis.set_major_locator(MultipleLocator(v['xmajor']))

    if v['ymajor']:
      self.ax.yaxis.set_major_locator(MultipleLocator(v['ymajor']))

    if v['xminor']:
      self.ax.xaxis.set_minor_locator(MultipleLocator(v['xminor']))

    if v['yminor']:
      self.ax.yaxis.set_minor_locator(MultipleLocator(v['yminor']))

  def xlabel(self, v):
    self.ax.set_xlabel(v)

  def ylabel(self, v):
    self.ax.set_ylabel(v)

  def xlim(self, v):
    self.ax.set_xlim(self.config['xlim'])

  def ylim(self, v):
    self.ax.set_ylim(self.config['ylim'])

  def grid(self, v):
    if v['visible']:
      self.ax.grid(v['visible'], v['which'], **v['style'])

  def legend(self, v):
    plt.legend(**v)

  def ticklabel_format(self, v):
    self.ax.ticklabel_format(**v)

  def save(self, v):
    self.fig.savefig(self.config['save'], bbox_inches='tight')

  def show(self, v):
    if v == 'y' or v == 'Y':
      plt.tight_layout()
      plt.show()

class line(chart):
  def __init__(self, dataset):
    config = DEFAULT_CONFIG.copy()
    config['datasets'] = dataset
    super().__init__(config)

  def datasets(self, v):
    for dataset in v:
      self.ax.plot(dataset['x'],
                   dataset['y'],
                   **dataset['style'])

      if dataset['errorbar']:
        self.ax.errorbar(**dataset['errorbar'])

# class plot a chart with multple ax on one column
# each key represet a ax to plot. each key is a list of dicts like class line
class multrows_line(chart):
  def __init__(self, dataset):
    config = DEFAULT_CONFIG.copy()
    config['mult_datasets'] = dataset
    self.num_rows = len(dataset)
    super().__init__(config, multrows=True)

  def mult_datasets(self, v):
    #print(v)
    for i, key in enumerate(v):
      datasets = v[key]
      self.ax[i].set_ylabel(key)
      for dataset in datasets:
        #print(dataset)
        #text = self.ax[i].set_title(str(arrival_dist).capitalize(), x=0.5, y=0.5, color='gray')
        #text = self.ax[i].set_title(str(key).capitalize(), x=0.01, y=0.75, color='gray', loc='left')
        #text.set_alpha(0.9)
        self.ax[i].plot(dataset['x'],
                        dataset['y'],
                        **dataset['style'])

        if dataset['errorbar']:
          self.ax[i].errorbar(**dataset['errorbar'])

  def xlim(self, v):
    for i in range(self.num_rows):
      self.ax[i].set_xlim(self.config['xlim'])

  def ylim(self, v):
    for i in range(self.num_rows):
      self.ax[i].set_ylim(self.config['ylim'])

  def set_ticks(self, v):
    for i in range(self.num_rows):
      if v['xmajor']:
        self.ax[i].xaxis.set_major_locator(MultipleLocator(v['xmajor']))

      if v['ymajor']:
        self.ax[i].yaxis.set_major_locator(MultipleLocator(v['ymajor']))

      if v['xminor']:
        self.ax[i].xaxis.set_minor_locator(MultipleLocator(v['xminor']))

      if v['yminor']:
        self.ax[i].yaxis.set_minor_locator(MultipleLocator(v['yminor']))

  def grid(self, v):
    if v['visible']:
      for i in range(self.num_rows):
        self.ax[i].grid(v['visible'], v['which'], **v['style'])

  def xlabel(self, v):
    #self.fig.supxlabel(v)
    plt.xlabel(v)

  def ylabel(self, v):
    self.fig.supylabel(v)
    #plt.ylabel(v, loc='center')
    #self.fig.text(0.02, 0.5, v, ha='center', va='center', rotation='vertical')
    #self.fig.text(0.01, 0.5, v, ha='center', va='center', rotation='vertical')

  def ticklabel_format(self, v):
    #for i in range(self.num_rows):
    self.ax[0].ticklabel_format(**v)

  def legend(self, v):
    self.ax[0].legend(**v)

  def title(self, v):
    self.fig.suptitle(v['label'])


class bar(chart):
  def __init__(self, config):
    super().__init__(config)
    self.bar_width = 0.35

  def bar_w(self, v):
    self.bar_width = v['bar_width']

  def bar_xticks(self, v):
    self.ax.set_xticks(v)

  def bar_xticklabels(self, v):
    self.ax.set_xticklabels(v)

  def bar_yticks_major(self, v):
    self.ax.set_yticks(v, minor=False)

  def bar_yticks_minor(self, v):
    self.ax.set_yticks(v, minor=True)

  def datasets(self, v):
    self.group_size = len(v[0])
    self.num_groups = len(v)

    x = []
    for i in range(self.num_groups):
      group = v[i]['bars']
      x.append(int(v[i]['name']) - 1)
      for j in range(self.group_size):
        y = group[j]['y']
        print('y ' + str(y))
        self.ax.bar(
          # bar position
          i + j * self.bar_width - 0.5 * ((self.group_size - 1) * self.bar_width),
          y, # bar height
          width=self.bar_width,
          #yerr=group[j]['group_config']['yerr'],
          **group[j]['group_config'],
        )


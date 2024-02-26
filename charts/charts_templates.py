
def get_config_template():
  return {
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
		'visible' : False,
		'which': 'major',
		'style' : {
		  #'color': '#ccc',
		  'linestyle': '-',
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
		'loc': 'best',
		#'bbox_to_anchor': (0.5, 1.45),
		'title_fontsize' : 12,
		'fontsize': 18,
		#'ncol': 3,
		#'mode': 'expand',
		'frameon': False,
		},

	  #'title':{
	  #    #'label': '{} requests'.format(TYPE).capitalize(),
	  #    'label': 'Curtas',
	  #    'loc': 'center'
	  #},

	  #'ylim': [0, 80],
	  'xlim': [0, 5.99],  # max(overhead) + 10],
	  #'save': 'imgs/{}.pdf'.format(TYPE),
	  'save': '',
	  'show': 'n',
  }

def entry_dataset(x, y, yerr, label, m=None, ls=None, color=None):
  config = {
	  'x': x,
	  'y': y,
	  'style': {
		'label': label,
		'color': color,
	    'linestyle': ls,
		'marker': m,
		'linewidth': 1.0,
		'markersize': 4,
		#'markerfacecolor': mc,
		#'markeredgecolor': mc
		},
	  'errorbar': {
		'x': x,
		'y': y,
		'yerr': yerr,
		'ecolor': 'black',
		'color': color,
		'linestyle': ls,
		'marker': m,
		'elinewidth': 1,
		#'barsabove': True,
		'linewidth': 1.0,
		'markersize': 4,
		'capsize': 3, # upper and bottom in error bar
		#'markerfacecolor': mc,
		#'markeredgecolor': mc
		},
	  }

  return config



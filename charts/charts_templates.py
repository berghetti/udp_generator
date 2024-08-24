
def get_config_template():
	pass

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



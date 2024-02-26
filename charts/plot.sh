#!/bin/bash

#./plot_wk1.py 'wk1' p999 /media/data/tests/exponential/0.5_100/*
#./plot_wk1.py 'wk1' p99 /media/data/tests/exponential/0.5_100/{afp-cl50,psp-cl50}
#./plot_wk1.py 'wk1' p99 /media/data/tests/exponential/0.5_100/{afp-cl100,psp-cl100}
#./plot_wk1.py 'wk1' p99 /media/data/tests/exponential/0.5_100/{afp,psp-cl0}
#./plot_wk1.py 'wk1' p50 /media/data/tests/exponential/0.5_100/{afp,afp-cl50,psp-cl0,psp-cl50}

./plot_wk1.py 'wk1' p999 /media/data/tests/exponential/0.5_100/{afp-cl0,afp-cl50,psp-cl0,psp-cl50,rss-cl0}
./plot_wk1.py 'wk1' p99 /media/data/tests/exponential/0.5_100/{afp-cl0,afp-cl50,psp-cl0,psp-cl50,rss-cl0}
./plot_wk1.py 'wk1' p50 /media/data/tests/exponential/0.5_100/{afp-cl0,afp-cl50,psp-cl0,psp-cl50,rss-cl0}


#update
#./update_meta.py 'wk1' p999 /media/data/tests/exponential/0.5_100/afp 2000000

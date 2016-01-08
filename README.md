#contrastive-symmetry

Code to replicate the results in Dunbar and Dupoux (submitted). The analysis
is done in an Rmarkdown file, which in turn depends on the size,
sum of number of minimal pairs (sum_fnpairs), and sum of differences
(sum_fbalance) statistics being pre-calculated. These are not included
in the repository and need to be computed.

The random comparison inventories and the extra geometries, on the
other hand, are included (under data/). The code is there to
re-generate them, but is only briefly documented below.

##Requirements

###R packages

* ggplot2
* pryr
* plyr
* dplyr
* doParallel
* parallel
* xtable

###Python modules

* joblib
* numpy
* pandas

For sampling extra geometries:

* python-igraph (from http://igraph.org/python)

##Requirements

How to replicate our analysis:

* To generate the specifications and the statistics, do 'make'

This will take some time. If you want to speed
it up, and you have more than 4 cores at your disposal, you can increase
the number of cores Python uses (by default, 4: change NJOBS_PYTHON in
the header of the Makefile). Alternatively, since the main culprits
are the uniform inventories (they have a lot of possible specifications)
if you are only interested in Study 1, uncomment the STUDY\_1\_ONLY
flag in the Makefile, and then, in analysis/file_locations.R,
comment out the first line and uncomment the second version of
INVENTORY_TYPE, just below, that only has Natural and Control. The
Rmarkdown will still try and create the figure from Study 2 and will
crash there, so just comment out the code in this chunk.

* To generate the analysis, run knitr on analysis.Rmd

This will also take some time, (compiling the statistics, constructing
the AUC bootstraps), but not hours unless you are on a very slow machine.
After the first time it runs, the results will be cached, so should
be almost instant unless you need to re-run either
of these two steps (in which case you should
just delete the relevant cache files from analysis_cache).

How to generate random control inventories size-matched and segment
frequency-matched to one of the sets of inventories (e.g., whole):

* python src/contrastive-symmetry/random_inventories.py --binary-segment
data/SET/nat/all.csv
  
How to generate uniform random inventories size-matched 
to one of the sets of inventories:

* python src/contrastive-symmetry/random_inventories.py --matrix
data/SET/nat/all.csv

How to generate random inventories size-matched and feature frequency-weighted
to one of the sets of inventories:

* python src/contrastive-symmetry/random_inventories.py --feature
data/SET/nat/all.csv

How to generate extra geometries of dimension k, size n:

* python src/contrastive-symmetry/sample_geometries.py --use-spectrum N K
OUTPUT_FILE

This will print a large sample of the geometries of dimension k and
size n that are distinct in their distance matrices. It will is
not guaranteed to a good sample in any way.
Still, for large values of k (beyond about 8) this will run
basically forever. You can reduce the values of
--max-tries and --max-samples if you want the thing to finish, but
you will lose inventories (and in fact you should probably increase these
values) at larger values of k.

This list is going to be way larger than you need, because
size, nfeat, sum\_fnpairs, and sum\_fbalance are far from complete in
terms of defining a whole distance matrix. So you can use the script
scripts/unique_geometries.sh to reduce the list substantially.

How to print basic typological statistics (inventory size, feature probability
of +, segment probability):

* python src/contrastive-symmetry/basic_stats.py size data/SET/TYPE/all.csv
* python src/contrastive-symmetry/basic_stats.py feature data/SET/TYPE/all.csv
* python src/contrastive-symmetry/basic_stats.py segment data/SET/TYPE/all.csv

##Files

* **README.md** - this file 

* **Makefile** - generate inventory specifications and statistics

* **analysis.Rmd** - analysis document containing the plots and tables for the
paper
* **analysis/** - R code for the analysis

* **src/R/** - basic R code
* **src/contrastive-symmetry** - Python code for calculating fnpairs and
fbalance statistics, for generating inventory specifications, and for
generating random inventories and extra geometries (although these last
are already included in the repository)
* **scripts/** - Scripts for compiling fnpairs/balance into
sum\_fnpairs/sum\_fbalance



#contrastive-symmetry

Compute economy, balance, and minimal pairs for naturally occurring 
inventories, as described in Dunbar and Dupoux (in preparation, draft
included under docs/).

##Directory structure

**analysis/** R markdown files to generate the analysis and all the
plots in the paper

**stats/** pre-computed raw statistics, computed from data/ and specs/

* *\*\_minfeat* minimum number of contrastive features by inventory
* *\*\_pair_counts* number of minimal pairs by feature by specification by
inventory
* *\*\_pair_counts_med* number of minimal pairs by feature by inventory,
median over all specifications
* *\*\_size* size of inventory
* *\*\_tbalance* number of plus, minus, and absolute value of difference by feature
by inventory

**data/** inventory tables

**specs/** pre-computed minimal feature subsets by inventory

**src/analysis** R code for doing analysis

**src/contrastive-symmetry** Python code for generating specs and stats

##To generate random inventories

**FIXME DOCS**

##To generate specs/ (minimal feature subsets)

- mkdir -p TMP
- python src/contrastive-symmetry/subset.py \-\-binary \-\-max-frontier-expansion-cost=30000 \-\-jobs=[NJOBS] data/[INVENTORY].csv TMP/s\_[INVENTORY]
- bash compile\_stats.sh TMP/s\_[INVENTORY] > specs/[INVENTORY]\_specs.csv

##To generate \_size files

- Rscript \-\-vanilla size.R data/[INVENTORY].csv stats/[INVENTORY]\_size.csv

##To generate \_minfeat files

- Ensure specs is appropriately populated (see above)
- Rscript \-\-vanilla minfeat.R specs/[INVENTORY]\_specs.csv stats/[INVENTORY]\_minfeat.csv

##To generate \_tbalance files

- Ensure specs is appropriately populated (see above)
- mkdir -p TMP
- python src/contrastive-symmetry/balance.py \-\-jobs=[NJOBS] \-\-max-dim=0 data/[INVENTORY].csv specs/[INVENTORY]\_specs.csv TMP/b\_[INVENTORY]
- bash compile\_stats.sh TMP/b\_[INVENTORY] > stats/[INVENTORY]\_tbalance.csv
- cut -d , -f 1-5 stats/[INVENTORY]\_tbalance.csv | sed -e "1s/,balance/,tbalance/;1s/\_count//g" > tmp\_file; mv tmp\_file stats/[INVENTORY]\_tbalance.csv

##To generate \_pair\_counts files

- Ensure specs is appropriately populated (see above)
- mkdir -p TMP
- python src/contrastive-symmetry/pair\_counts.py \-\-jobs=[NJOBS] data/[INVENTORY].csv specs/[INVENTORY\_SPECS].csv TMP/p\_[INVENTORY]
- bash compile\_stats.sh TMP/p\_[INVENTORY] > stats/[INVENTORY]\_pair\_counts.csv

##To generate \_pair\_counts\_med files

- Ensure \_pair\_counts files are generated
- Rscript \-\-vanilla collapse_pair_counts.R stats/[INVENTORY]_pair_counts.csv  stats/[INVENTORY]_pair_counts_med.csv


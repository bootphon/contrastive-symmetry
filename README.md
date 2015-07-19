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

##To generate \_size files

**FIXME DOCS**

##To generate specs/ (minimal feature subsets)

**FIXME DOCS**
- bash compile\_stats.sh TMP/s\_[INVENTORY] > specs/[INVENTORY]\_specs.csv

##To generate \_minfeat files

- Ensure specs is appropriately populated (see above)
- Rscript minfeat.R specs/[INVENTORY]\_specs.csv stats/[INVENTORY]\_minfeat.csv

##To generate \_tbalance files

- Ensure specs is appropriately populated (see above)
- mkdir -p TMP
- python src/contrastive-symmetry/balance.py --jobs=[NJOBS] --max-dim=0 data/[INVENTORY].csv specs/[INVENTORY]\_specs.csv TMP/b\_[INVENTORY]
- bash compile\_stats.sh TMP/b\_[INVENTORY] > stats/[INVENTORY]\_tbalance.csv
- cut -d , -f 1-5 stats/[INVENTORY]\_tbalance.csv | sed -e "1s/,balance/,tbalance/;1s/\_count//g" > tmp\_file; mv tmp\_file stats/[INVENTORY]\_tbalance.csv

##To generate \_pair\_counts files

- Ensure specs is appropriately populated (see above)
- mkdir -p TMP
- python src/contrastive-symmetry/pair\_counts.py --jobs=[NJOBS] data/[INVENTORY].csv specs/[INVENTORY\_SPECS].csv TMP/p\_[INVENTORY]
- bash compile\_stats.sh TMP/p\_[INVENTORY] > stats/[INVENTORY]\_pair\_counts.csv

##To generate \_pair\_counts\_med files

- Ensure \_pair\_counts files are generated
- Rscript collapse_pair_counts.R stats/[INVENTORY]_pair_counts.csv 
stats/[INVENTORY]_pair_counts_med.csv


To generate random baseline inventories
---------------------------------------

python src/contrastive-symmetry/generate\_random.py --all --outdir=data
  --initial-seed=1 --jobs=100 data/inv.csv data/stop.csv data/vowel.csv
  data/cons.csv 

  * use --matrix, --feature, --segment, or some combination, instead of
  --all to generate only uniform matrix baseline, independent data-matched
  feature baseline, and independent data-matched segment baseline
  * replace inventory source file(s) with whatever files you want to base
  the stats on; baselines will be generated for all of them
  * random seed changes for each inventory, but within each (source file x
  baseline type) pair goes through the same fixed sequence, starting at
  initial-seed, if initial-seed is specified; otherwise the seed is never
  set
  
To compute contrastive specification statistics
-----------------------------------------------

python src/contrastive-symmetry/contrast\_stats.py --outdir=contrast\_stats 
  --permutation-seed=1 --jobs=100 data/\*.csv

  * replace inventory source file(s) with whatever files you want to base
  the stats on
  * default number of permutations is 100; random with a seed that can be
  fixed (as here, set to 1) or variable
  
To generate a document summarizing the analysis, including all figures from the slides
-------------------------------------

  * knit the file analysis/analysis.Rmd using analysis/ as the working directory
 
FILES
-----

  * **docs/ijn\_102914.pdf:** Slides 10/29/2014
  * **docs/paris8\_020415.pdf:** Slides 02/04/2015
  * **docs/paris3\_021315.pdf:** Slides 10/29/2015
  * **docs/dgfs\_leipzig\_030515\_021315.pdf:** Slides (DGfS) 03/05/2015
  
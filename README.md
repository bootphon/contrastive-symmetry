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

**scripts/** for generating statistics

**data/** inventory tables

**specs/** pre-computed minimal feature subsets by inventory

**src/analysis** R code for doing analysis

**src/contrastive-symmetry** Python code for generating specs and stats

##To generate random inventories

**FIXME DOCS**

##To generate specs and all stats 

bash scripts/do\_all\_stats.sh

##To just generate specs/ (minimal feature subsets)

bash scripts/specs.sh [INVENTORY]

(where data/[INVENTORY].csv is a file containing the inventories to be analyzed)

##To just generate \_size files

bash scripts/size.sh [INVENTORY]

##To just generate \_minfeat files

bash scripts/minfeat.sh [INVENTORY]

##To just generate \_tbalance files

bash scripts/tbalance.sh [INVENTORY]

##To just generate \_pair\_counts and \_pair\_counts\_med files

bash scripts/pair_counts.sh [INVENTORY]

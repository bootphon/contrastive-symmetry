contrastive-symmetry
====================

Study of contrastive symmetry, feature economy, and feature correlation in
naturally occurring inventories. This work is not yet published but three
relevant sets of slides are included (documenting different stages in our
understanding of the research)

To (re-)generate random baseline inventories
============================================

python src/contrastive-symmetry/generate\_random.py --all --outdir=data \
  --initial-seed=1 --jobs=100 data/inv.csv data/stop.csv data/vowel.csv \
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
===============================================

python src/contrastive-symmetry/contrast\_stats.py --outdir=contrast\_stats \
  --permutation-seed=1 --jobs=100 data/\*.csv

  * replace inventory source file(s) with whatever files you want to base
  the stats on
  * default number of permutations is 100; random with a seed that can be
  fixed (as here, set to 1) or variable
  

FILES
=====

  * **docs/ijn\_102914.pdf:** Slides 10/29/2014
  * **docs/paris8\_020415.pdf:** Slides 02/04/2015
  * **docs/paris3\_021315.pdf:** Slides 10/29/2015
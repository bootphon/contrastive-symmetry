contrastive-symmetry
====================

Study of contrastive symmetry, feature economy, and feature correlation in
naturally occurring inventories. This work is not yet published but four
relevant sets of slides are included (documenting different stages in our
understanding of the research).

The current latest set of slides is from DGfS Leipzig (March 2015). The
current state of our understanding is that feature economy is a real effect
in natural inventories, as shown by two different measures evaluated
on PBase with the features from the Halle and Clements phonology workbook.
Earlier analyses suggested, confusingly, that one, but not another, of
these measures was showing a tendency for economy. Some cleanups to
the statistical analysis shows that this is wrong, and that there is a
general tendency toward feature economy in natural inventories by two
different measures.


One caveat with the current code is that it can sometimes fail to generate
statistics for certain inventories due to particularities of how certain
features are marked as zero in the Halle and Clements feature system. This is
why certain figures reveal that the random segment baseline does not have the
same number of inventories as the actual database. This represents a bug in
the logic, but we are fairly confident that the effect on the results is
minor. It will be fixed in later versions.


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
  
#contrastive-symmetry

New Readme. Keeping a list of all the files we need here so that we can
start fresh.

##Files

* **README.md** - this file 

* **Makefile** - generate inventory specifications and statistics

* **analysis.Rmd** - analysis document containing the plots and tables for the
paper
* **analysis/file_locations.R** - supplement to analysis.Rmd listing filenames
* **analysis/plot_constant.R** - supplement to analysis.Rmd setting up
constants used for plotting
* **analysis/read_input.R** - supplement to analysis.Rmd reading input

* **src/R/util.R** - functions for working with the output of dlply
* **src/R/read.R** - functions for reading the statistics files
* **src/R/plot.R** - functions for plotting
* **src/R/auc.R** - functions for computing AUC


##Required packages

###R packages

* plyr
* ggplot2
* dplyr
* pryr
* magrittr ??
* cowplot ??
* foreach ??
* doParallel

###Python modules

* joblib
* numpy
* pandas


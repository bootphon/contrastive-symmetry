#contrastive-symmetry

All the inventory statistics reported in [Dunbar and Dupoux 2016, "Geometric constraints on human speech sound inventories"](http://journal.frontiersin.org/article/10.3389/fpsyg.2016.01061/full), with a minor correction (see below). Also contains code to rerun a near-replication from the same data.

What's here:

* **summary.feather:** median Econ, Loc, and Glob for all the natural and random inventories reported in the paper; the sample is corrected slightly: due to a minor error which did not affect the results qualitatively, the sample of random inventories used in the paper was incorrect, and has been re-done here. All numbers in Table 1 are within 0.02 of those reported in the paper, with the exception of Loc values for Whole inventories, which are off by slightly more.
* **paper_stats.R:** a script that reads **summary.feather** and outputs Table 1 and Figure 6 from the paper

* **inventories.feather.gz:** inventories from P-Base, plus all the sets of random inventories, encoded in the binary feature system described in the paper (ungzip to use: **feather** can't read gzipped files)
* **geoms.feather.gz:** extra geometries as described in the paper (ungzip to use: **feather** can't read gzipped files)
* **create_statistics.R:** a script which re-generates **summary.feather** on the basis of **inventory.feather** and **geoms.feather**; this will take a very long time (days) - don't run this on your laptop; it won't be an exact replication, because (unfortunately) a bug in an earlier version of the code that subsamples contrastive specifications meant that it never used the random seed - however, the specifications used in the paper are still available (see below). The results of one replication were qualitatively the same in terms of relative comparisons between groups, with some instability in Loc and Glob in the Random Feature inventories, presumably due to the fact that the set of possible specifications for those is enormous, and we are really profoundly undersampling them.
* **summary_rerun.feather:** The example re-run we obtained by running **create_statistics.R**

Large files that can't be put in to a git repository that contain the intermediate steps (contrastive specifications, $N_{mp}$, $N_{im}$) - you can download these (and ungzip them) to re-run just the last step of the statistics (calculation of Econ, Loc, and Glob), skipping over these steps:

* **[specs.feather.gz](http://ewan.website/specs.feather.gz)**: all contrastive specifications
* **[nmpairs.feather.gz](http://ewan.website/nmpairs.feather.gz)**: $N_{mp}$
* **[nimbalance.feather.gz](http://ewan.website/nimbalance.feather.gz)**: $N_{im}$

What's missing (but which will appear here in the near future):

* Code for generating the extra geometries in **geoms.feather**
* Analysis of the Mackie/Mielke/deBoer inventories mentioned in the paper
* Code for generating the random control inventories

##Requirements

* dplyr
* tidyr
* purrr
* doParallel
* ggplot2 
* feather
* rocauc

To install:

     library(devtools)
     install_github("ewan/rocauc", subdir="rocauc")
  



##Additional requirements if you are re-generating the statistics

* readr
* inventrry

To install:

     library(devtools)
     install_github("ewan/inventrry", subdir="inventrry")

The **inventrry** package requires Python, and uses the **PythonInR** package, which might require a bit of non-trivial setup before you can get it to run, if you are not using the default Python installation on your system. See the [README for the **inventrry** package](https://github.com/ewan/inventrry) for details. After that setup is done, you will want to uncomment the line in `create_statistics.R` which sets the PYTHONHOME environment variable before trying to load **inventrry**.




#contrastive-symmetry

All the inventory statistics reported in [Dunbar and Dupoux 2016, "Geometric constraints on human speech sound inventories"](http://journal.frontiersin.org/article/10.3389/fpsyg.2016.01061/full).

What's here:

* **summary.feather:** median Econ, Loc, and Glob for all the natural and random inventories reported in the paper
* **inventories.feather.gz:** inventories from P-Base, plus all the sets of random inventories, encoded in the binary feature system described in the paper (ungzip to use: **feather** can't read gzipped files)
* **geoms.feather.gz:** extra geometries as described in the paper (ungzip to use: **feather** can't read gzipped files)
* **create_statistics.R:** a script which re-runs all the statistics; this will take a very long time (days) - don't run this on your laptop; it won't be an exact replication, because (unfortunately) a bug in an earlier version of the code that subsamples contrastive specifications meant that it never used the random seed - however, the specifications used in the paper are still available (see below)

Large files that can't be put in to a git repository that contain the intermediate steps (contrastive specifications, $N_{mp}$, $N_{im}$ - you can download these (and ungzip them) to re-run just the last step of the statistics (calculation of Econ, Loc, and Glob), skipping over these steps:

* **[http://ewan.website/specs.feather.gz](specs.feather.gz)**: all contrastive specifications
* **[http://ewan.website/nmpairs.feather.gz](nmpairs.feather.gz)**: $N_{mp}$
* **[http://ewan.website/nimbalance.feather.gz](nimbalance.feather.gz)**: $N_{im}$

What's missing (but which will appear here in the near future):

* Comparisons using AUC as reported in the paper
* Plots generated in the paper
* Code for generating the extra geometries in **geoms.feather**
* Analysis of the Mackie/Mielke/deBoer inventories mentioned in the paper
* Code for generating the random control inventories

##Requirements

* feather

##Requirements if you are re-generating the statistics

* inventrry
 

     library(devtools)
     install_github("ewan/inventrry", subdir="inventrry")

The **inventrry** package requires Python, and uses the **PythonInR** package, which might require a bit of non-trivial setup before you can get it to run, if you are not using the default Python installation on your system. See the [README for the **inventrry** package](https://github.com/ewan/inventrry) for details. After that setup is done, you will want to uncomment the line in `create_statistics.R` which sets the PYTHONHOME environment variable before trying to load **inventrry**.

* readr
* dplyr
* tidyr
* purrr
* foreach
* doParallel



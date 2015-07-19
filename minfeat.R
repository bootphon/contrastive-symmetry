#!/usr/bin/Rscript --vanilla

library(plyr)

args <- commandArgs(TRUE)
input <- args[1]
output <- args[2]
d_specs <- read.csv(input)
d_min <- ddply(d_specs, .(language), summarize, minfeat=min(num_features))
write.csv(d_min, file=output, row.names=F)

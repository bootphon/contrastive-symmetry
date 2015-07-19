#!/usr/bin/Rscript --vanilla

library(plyr)

args <- commandArgs(TRUE)
input <- args[1]
output <- args[2]
d_full <- read.csv(input)
d_collapsed <- ddply(d_full, .(language, feature), summarize, pair_count=median(pair_count))
write.csv(d_collapsed, file=output, row.names=F)

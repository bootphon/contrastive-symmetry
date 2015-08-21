#!/usr/bin/Rscript --vanilla

library(plyr)

args <- commandArgs(TRUE)
input <- args[1]
output <- args[2]
d <- read.csv(input)
result <- ddply(d, .(language), summarize, size=length(language))
write.csv(result, file=output, row.names=F)

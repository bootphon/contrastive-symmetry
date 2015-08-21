#!/usr/bin/Rscript --vanilla

library(plyr)

subsample <- function(x_from, stat_from, stat_to) {
  t_dist <- table(stat_to)
  t_support <- names(t_dist)
  f_dist <- table(stat_from)[t_support]
  pivot <- which.min(f_dist)
  sample_ratio <- f_dist[pivot]/t_dist[pivot]
  new_dist <- round(t_dist*sample_ratio)
  if (sum(new_dist>f_dist) > 0) {
    stop("asked for sample too large: can't handle this")
  }
  sf_s <- as.character(stat_from)
  result <- unlist(sapply(t_support, function(s)
                   sample(x_from[stat_from==s], new_dist[s])))
  names(result) <- NULL
  return(result)
}

args <- commandArgs(TRUE)
input_1 <- args[1]
input_2 <- args[2]
nsamples <- as.numeric(args[3])
output <- args[4]

d1_r <- read.csv(input_1)
d2 <- read.csv(input_2)

segs_d2 <- unique(as.character(d2$label))
segs_ok <- merge(d1_r, ddply(d1_r, .(language), summarize,
                 segs_ok=(as.logical(prod(label %in% segs_d2)))))
d1 <- segs_ok[segs_ok$segs_ok,-ncol(segs_ok)]

d1_size <- ddply(d1, .(language), summarize, size=length(language))
d2_size <- ddply(d2, .(language), summarize, size=length(language))

result <- ldply(1:nsamples, function(i) data.frame(sample_id=paste0("S",i), language= subsample(as.character(d1_size$language), d1_size$size, d2_size$size)))

write.csv(result, file=output, row.names=F)

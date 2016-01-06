norm_rank <- function(x, rev=F) {
  if (rev) {
    r <- findInterval(-x, sort(unique(-x)))
  } else {
    r <- findInterval(x, sort(unique(x)))
  }
  if (length(r) == 1) {
    return(0.5)
  }
  return((r-min(r))/(max(r)-min(r)))
}

sum_fnpairs_spec$nfeat <-
  sapply(strsplit(as.character(sum_fnpairs_spec$spec_id), ':'), length)
sum_fnpairs_spec <- merge(size, sum_fnpairs_spec)
sum_fbalance_spec$nfeat <- 
  sapply(strsplit(as.character(sum_fbalance_spec$spec_id), ':'), length)
sum_fbalance_spec <- merge(size, sum_fbalance_spec)


attested_geometries <- merge(sum_fnpairs_spec, sum_fbalance_spec)[,c("size",
                                     "nfeat", "sum_fnpairs", "sum_fbalance")]
possible_geometries <- unique(rbind(attested_geometries, extra_geometries))

loc_vals <- ddply(unique(possible_geometries[,c('size','nfeat','sum_fnpairs')]),
                  .(size, nfeat),
                  function(d) data.frame(sum_fnpairs=d$sum_fnpairs,
                                         loc=norm_rank(d$sum_fnpairs))) 
glob_vals <- ddply(possible_geometries, .(size, nfeat, sum_fnpairs),
                   function(d) data.frame(sum_fbalance=d$sum_fbalance,
                                         glob=norm_rank(d$sum_fbalance, rev=T))) 

loc_spec <- merge(sum_fnpairs_spec, loc_vals)
loc_glob_spec <- merge(merge(sum_fbalance_spec, loc_spec), glob_vals)

inv_stats <- ddply(loc_glob_spec,
                  .(segment_type, inventory_type, language),
                  summarize, size=size[1], minfeat=min(nfeat),
                  Econ=(size[1]/(2^min(nfeat))), Loc=median(loc),
                  Glob=median(glob))


isym_stat_columns <- c("sb", "nseg", "ncfeat", "sb_by_nseg", 
                       "sb_by_ncfeat", "nseg_by_ncfeat",
                       "language", "order")

read_isym <- function(fn) {
  result <- read.csv(fn)
  result$sb_by_nseg <- with(result, sb/nseg)
  result$sb_by_ncfeat <- with(result, sb/ncfeat)
  result$nseg_by_ncfeat <- with(result, nseg/ncfeat)  
  return(result)
}
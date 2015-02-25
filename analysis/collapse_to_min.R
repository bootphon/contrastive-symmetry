library(plyr)

isym_min_stat_columns <- c("min_ncfeat", "nseg_by_min_ncfeat",
                           "sb_by_min_ncfeat", "language")

collapse_ncfeat_to_min <- function(d) {
#  return(ddply(d, .(language, nseg, sb, inv_type),
#               .fun=function(dv) data.frame(min_ncfeat=min(dv$ncfeat),
#                                            nseg_by_min_ncfeat=dv$nseg[1]/
#                                              min(dv$ncfeat),
#                                            sb_by_min_ncfeat=min(dv$sb[dv$ncfeat==min(dv$ncfeat)])/
#                                              min(dv$ncfeat)
#                                            )))
  return(ddply(d, .(language), summarize,
              min_ncfeat=min(ncfeat),
              nseg_by_min_ncfeat=nseg[1]/min(ncfeat),
              sb_by_min_ncfeat=min(sb[ncfeat==min(ncfeat)])/min(ncfeat)))
}

ranked_stats <- function(d, var,stat, stat_name, only_first=F) {
  var_cols <- grep(paste0("^", var), names(d))
#  stat_result <- apply(d[,var2_cols]*d[,var_cols]/d[,"ncfeat"], 2, stat, na.rm=T)
  stat_result <- apply(d[,var_cols], 2, stat, na.rm=T)
  stat_result <- stat_result[!is.na(stat_result) & is.finite(stat_result)]
  var_col_names <- names(stat_result)
  dec_order <- order(stat_result, decreasing=T)
  stat_result_sorted <- stat_result[dec_order]
  feature_names <- substr(var_col_names, nchar(var)+1, nchar(var_col_names))
  result <- data.frame(feat=feature_names[dec_order],
                       rank=(1:length(stat_result_sorted)))
  result[[paste0(stat_name, "_", var)]] <- stat_result_sorted
  return(result)
}

compile_feature_stats <- function(d, var) {
  var_cols <- grep(paste0("^", var), names(d))
  stat_result <- apply(d[,var_cols], 2, stat, na.rm=T)
  stat_result <- stat_result[!is.na(stat_result) & is.finite(stat_result)]
  var_col_names <- names(stat_result)
  dec_order <- order(stat_result, decreasing=T)
  stat_result_sorted <- stat_result[dec_order]
  feature_names <- substr(var_col_names, nchar(var)+1, nchar(var_col_names))
  result <- data.frame(feat=feature_names[dec_order],
                       rank=(1:length(stat_result_sorted)))
  result[[paste0(stat_name, "_", var)]] <- stat_result_sorted
  return(result)
}


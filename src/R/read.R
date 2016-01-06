
raw_undetailed_stats_cols <- c("nseg", "sb", "ncfeat")
raw_id_cols <- c("language", "order")
inventory_id_cols <- c("language", "label")

FEATURE_MAP <- c("+"=1, "-"=-1, "0"=0)

feature_to_numeric <- function(x) {
  result <- apply(x, MARGIN=c(1,2), FUN=function(z) FEATURE_MAP[z] %>% unname)
  return(result)
}

convert_features <- function(d) {
  feature_cols <- -which(names(d) %in% inventory_id_cols)
  features_converted <- d[,feature_cols] %>% as.matrix %>%
                                             feature_to_numeric %>%
                                             as.data.frame
  result <- cbind(d[,inventory_id_cols], features_converted)
  return(result)
}

read_feature_table <- function(filename) {
  result <- filename %>% read.csv %>% convert_features
  return(result)
}

read_from_filename_table <- function(filename_table, read_fn=read.csv) {
  registerDoParallel()
  result <- dlply(filename_table,
                  .(segment_type, inventory_type),
                  .fun=function(d) read_fn(as.character(d$filename)),
                  .parallel=TRUE)
  return(result)
}

undetail <- function(detailed_cstats) {
  return(detailed_cstats[,c(raw_id_cols,raw_undetailed_stats_cols)])
}


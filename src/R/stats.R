spec_id <- function(v, feature_names) {
  return(paste(feature_names[v], collapse=":"))
}

minfeat <- function(specs) {
  feature_names <- names(specs)[!names(specs)%in%c("language", "num_features")]
  features <- as.matrix(specs[,feature_names])
  minfeat <- with(specs, min(num_features))
  minfeat_i <- with(specs, (1:length(num_features))[num_features == minfeat])
  minfeat_val <- specs$num_features[minfeat_i]
  spec_ids <- apply(features[minfeat_i,,drop=F], 1, spec_id, feature_names)
  result <- data.frame(minfeat=minfeat_val,
                       spec_id=spec_ids)
  return(result)
}

size <- function(inv) {
  return(data.frame(size=nrow(inv)))
}

bootstrap <- function(d, N, FUN) {
  unlist(mclapply(1:N,
                  function(i) FUN(d[sample(1:nrow(d), nrow(d), replace=T),])))
}
combine_dlist <- function(dlist) {
  vardf <- attr(dlist, "split_labels")
  with_splitvars <- lapply(1:nrow(vardf),
                          FUN=function(i) cbind(dlist[[i]], vardf[i,],
                                                row.names=NULL))
  result <- do.call("rbind", with_splitvars)
  return(result)
}

apply_dlist <- function(dlist, fun, ...) {
  result <- llply(dlist, .fun=fun, ...)
  attributes(result) <- attributes(dlist)
  return(result)
}

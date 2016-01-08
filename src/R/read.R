read_from_filename_table <- function(filename_table, read_fn=read.csv) {
  registerDoParallel()
  result <- dlply(filename_table,
                  .(segment_type, inventory_type),
                  .fun=function(d) read_fn(as.character(d$filename)),
                  .parallel=TRUE)
  return(result)
}



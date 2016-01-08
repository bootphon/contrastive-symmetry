INVENTORY_TYPE <- c(Natural="nat",Control="ctrl",Weighted="wtd",Uniform="unif")
#INVENTORY_TYPE <- c(Natural="nat",Control="ctrl")
SEGMENT_TYPE <- c(Whole="whole", Consonant="cons", Stop="stop", Vowel="vowel")

SIZE_FILENAME_TABLE <- ldply(names(SEGMENT_TYPE),
                             function(st)
                             ldply(names(INVENTORY_TYPE),
                                   function (it)
                                   data.frame(filename=paste0("stats/size/",
                                              SEGMENT_TYPE[st], "/",
                                              INVENTORY_TYPE[it], "/all.csv"),
                                              segment_type=st,
                                              inventory_type=it)
                                              ))

SUM_FNPAIRS_FILENAME_TABLE <- ldply(names(SEGMENT_TYPE),
                             function(st)
                             ldply(names(INVENTORY_TYPE),
                                   function (it)
                                   data.frame(filename=paste0("stats/sum_fnpairs/",
                                              SEGMENT_TYPE[st], "/",
                                              INVENTORY_TYPE[it], "/all.csv"),
                                              segment_type=st,
                                              inventory_type=it)
                                              ))

SUM_FBALANCE_FILENAME_TABLE <- ldply(names(SEGMENT_TYPE),
                             function(st)
                             ldply(names(INVENTORY_TYPE),
                                   function (it)
                                   data.frame(filename=paste0("stats/sum_fbalance/",
                                              SEGMENT_TYPE[st], "/",
                                              INVENTORY_TYPE[it], "/all.csv"),
                                              segment_type=st,
                                              inventory_type=it)
                                              ))

EXTRA_GEOMETRIES <- "data/geometries/unique.csv"

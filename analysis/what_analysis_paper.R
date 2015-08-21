MINFEAT_FILENAME_TABLE <- data.frame(
  filename=c("../stats/inv_rs_minfeat.csv",
             "../stats/inv_rm_minfeat.csv",
             "../stats/inv_rf_minfeat.csv",
             "../stats/inv_rb_minfeat.csv",
             "../stats/inv_bin_minfeat.csv",
             "../stats/cons_rs_minfeat.csv",
             "../stats/cons_rm_minfeat.csv",
             "../stats/cons_rf_minfeat.csv",
             "../stats/cons_rb_minfeat.csv",
             "../stats/cons_bin_minfeat.csv",
             "../stats/stop_rs_minfeat.csv",
             "../stats/stop_rm_minfeat.csv",
             "../stats/stop_rf_minfeat.csv",
             "../stats/stop_rb_minfeat.csv",
             "../stats/stop_bin_minfeat.csv",             
             "../stats/vowel_rs_minfeat.csv",
             "../stats/vowel_rm_minfeat.csv",
             "../stats/vowel_rf_minfeat.csv",
             "../stats/vowel_rb_minfeat.csv",
             "../stats/vowel_bin_minfeat.csv"
#             , "../stats/deboer_vowels_minfeat.csv"             
             ),
  segment_type=c("Whole", "Whole", "Whole", "Whole", "Whole",
             "Consonant", "Consonant", "Consonant", "Consonant",  "Consonant", 
             "Stop", "Stop", "Stop", "Stop", "Stop",
             "Vowel", "Vowel", "Vowel", "Vowel", "Vowel"
#             , "de Boer Vowel"
             ),
  inventory_type=c("Random Segment","Random Matrix","Random Feature",
                   "Random Beta-binomial", "Natural",
                   "Random Segment","Random Matrix","Random Feature",
                   "Random Beta-binomial", "Natural", 
                   "Random Segment","Random Matrix","Random Feature",
                   "Random Beta-binomial", 
                   "Natural", 
                   "Random Segment","Random Matrix","Random Feature",
                   "Random Beta-binomial", "Natural"
#                   , "Model"
                   )
)


ISIZE_FILENAME_TABLE <- data.frame(
  filename=c(
             "../stats/inv_rs_size.csv",
             "../stats/inv_rm_size.csv",
             "../stats/inv_rf_size.csv",
             "../stats/inv_rb_size.csv",
             "../stats/inv_bin_size.csv",
             "../stats/cons_rs_size.csv",
             "../stats/cons_rm_size.csv",
             "../stats/cons_rf_size.csv",
             "../stats/cons_rb_size.csv",
             "../stats/cons_bin_size.csv",             
             "../stats/stop_rs_size.csv",
             "../stats/stop_rm_size.csv",
             "../stats/stop_rf_size.csv",
             "../stats/stop_rb_size.csv",
             "../stats/stop_bin_size.csv",             
             "../stats/vowel_rs_size.csv",
             "../stats/vowel_rm_size.csv",
             "../stats/vowel_rf_size.csv",
             "../stats/vowel_rb_size.csv",
             "../stats/vowel_bin_size.csv"
#             , "../stats/deboer_vowels_size.csv"
  ),
segment_type=c("Whole", "Whole", "Whole", "Whole", "Whole",
               "Consonant", "Consonant", "Consonant", "Consonant",  "Consonant", 
               "Stop", "Stop", "Stop", "Stop", "Stop",
               "Vowel", "Vowel", "Vowel", "Vowel", "Vowel"
               #             , "de Boer Vowel"
),
inventory_type=c("Random Segment","Random Matrix","Random Feature",
                 "Random Beta-binomial", "Natural",
                 "Random Segment","Random Matrix","Random Feature",
                 "Random Beta-binomial", "Natural", 
                 "Random Segment","Random Matrix","Random Feature",
                 "Random Beta-binomial", 
                 "Natural", 
                 "Random Segment","Random Matrix","Random Feature",
                 "Random Beta-binomial", "Natural"
                 #                   , "Model"
)
)


TBALANCE_FILENAME_TABLE <- data.frame(
  filename=c(
             "../stats/inv_rs_tbalance.csv",
             "../stats/inv_rm_tbalance.csv",
             "../stats/inv_rf_tbalance.csv",
             "../stats/inv_rb_tbalance.csv",
             "../stats/inv_bin_tbalance.csv",
             "../stats/cons_rs_tbalance.csv",
             "../stats/cons_rm_tbalance.csv",
             "../stats/cons_rf_tbalance.csv",
             "../stats/cons_rb_tbalance.csv",
             "../stats/cons_bin_tbalance.csv",             
             "../stats/stop_rs_tbalance.csv",
             "../stats/stop_rm_tbalance.csv",
             "../stats/stop_rf_tbalance.csv",
             "../stats/stop_rb_tbalance.csv",
             "../stats/stop_bin_tbalance.csv",             
             "../stats/vowel_rs_tbalance.csv",
             "../stats/vowel_rm_tbalance.csv",
             "../stats/vowel_rf_tbalance.csv",
             "../stats/vowel_rb_tbalance.csv",
             "../stats/vowel_bin_tbalance.csv"
#             ,"../stats/deboer_vowels_tbalance.csv"
             ),
segment_type=c("Whole", "Whole", "Whole", "Whole", "Whole",
               "Consonant", "Consonant", "Consonant", "Consonant",  "Consonant", 
               "Stop", "Stop", "Stop", "Stop", "Stop",
               "Vowel", "Vowel", "Vowel", "Vowel", "Vowel"
               #             , "de Boer Vowel"
),
inventory_type=c("Random Segment","Random Matrix","Random Feature",
                 "Random Beta-binomial", "Natural",
                 "Random Segment","Random Matrix","Random Feature",
                 "Random Beta-binomial", "Natural", 
                 "Random Segment","Random Matrix","Random Feature",
                 "Random Beta-binomial", 
                 "Natural", 
                 "Random Segment","Random Matrix","Random Feature",
                 "Random Beta-binomial", "Natural"
                 #                   , "Model"
)
)


PCOUNT_FILENAME_TABLE <- data.frame(
  filename=c("../stats/inv_rs_pair_counts_med.csv",
             "../stats/inv_rm_pair_counts_med.csv",
             "../stats/inv_rf_pair_counts_med.csv",
             "../stats/inv_rb_pair_counts_med.csv",
             "../stats/inv_bin_pair_counts_med.csv",
             "../stats/cons_rs_pair_counts_med.csv",
             "../stats/cons_rm_pair_counts_med.csv",
             "../stats/cons_rf_pair_counts_med.csv",
             "../stats/cons_rb_pair_counts_med.csv",
             "../stats/cons_bin_pair_counts_med.csv",             
             "../stats/stop_rs_pair_counts_med.csv",
             "../stats/stop_rm_pair_counts_med.csv",
             "../stats/stop_rf_pair_counts_med.csv",
             "../stats/stop_rb_pair_counts_med.csv",
             "../stats/stop_bin_pair_counts_med.csv",             
             "../stats/vowel_rs_pair_counts_med.csv",
             "../stats/vowel_rm_pair_counts_med.csv",
             "../stats/vowel_rf_pair_counts_med.csv",
             "../stats/vowel_rb_pair_counts_med.csv",
             "../stats/vowel_bin_pair_counts_med.csv"
#             , "../stats/deboer_vowels_pair_counts_med.csv"
  ),
segment_type=c("Whole", "Whole", "Whole", "Whole", "Whole",
               "Consonant", "Consonant", "Consonant", "Consonant",  "Consonant", 
               "Stop", "Stop", "Stop", "Stop", "Stop",
               "Vowel", "Vowel", "Vowel", "Vowel", "Vowel"
               #             , "de Boer Vowel"
),
inventory_type=c("Random Segment","Random Matrix","Random Feature",
                 "Random Beta-binomial", "Natural",
                 "Random Segment","Random Matrix","Random Feature",
                 "Random Beta-binomial", "Natural", 
                 "Random Segment","Random Matrix","Random Feature",
                 "Random Beta-binomial", 
                 "Natural", 
                 "Random Segment","Random Matrix","Random Feature",
                 "Random Beta-binomial", "Natural"
                 #                   , "Model"
)
)

#SPECIAL_DEBOER_COMPARISON_FILENAME <- c("../data/deboer_control_languages.csv")
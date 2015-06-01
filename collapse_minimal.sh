#!/bin/bash

cd results
for f in cons_random_feature cons_random_matrix cons_random_segment cons inv stop vowel inv_random_feature inv_random_matrix inv_random_segment stop_random_feature stop_random_segment stop_random_matrix vowel_random_feature vowel_random_matrix vowel_random_segment
do
  cat $f\_subminimal/*.csv | sed -e '2,$ s/^language.*//;/^$/d' > $f\_minimal.csv
done
cd ..

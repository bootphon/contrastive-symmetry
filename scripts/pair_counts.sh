#!/bin/bash

mkdir -p TMP
python src/contrastive-symmetry/pair_counts.py --jobs=4 data/$1\.csv \
  specs/$1\_specs.csv TMP/p_$1
bash scripts/compile_stats.sh TMP/p_$1 > stats/$1\_pair_counts.csv
Rscript --vanilla scripts/collapse_pair_counts.R stats/$1\_pair_counts.csv \
  stats/$1\_pair_counts_med.csv



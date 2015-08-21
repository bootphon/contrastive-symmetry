#!/bin/bash

mkdir -p TMP
python src/contrastive-symmetry/balance.py --jobs=4 --max-dim=0 data/$1\.csv \
  specs/$1\_specs.csv TMP/b_$1
bash scripts/compile_stats.sh TMP/b_$1 > stats/$1\_tbalance.csv
cut -d , -f 1-5 stats/$1\_tbalance.csv | \
  sed -e "1s/,balance/,tbalance/;1s/\_count//g" > tmp_file
mv tmp_file stats/$1\_tbalance.csv


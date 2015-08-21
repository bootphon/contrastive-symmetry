#!/bin/bash

mkdir -p TMP
python src/contrastive-symmetry/subset.py --binary --max-frontier-expansion-cost=30000 --jobs=4 data/$1\.csv TMP/s_$1
bash scripts/compile_stats.sh TMP/s_$1 > specs/$1\_specs.csv


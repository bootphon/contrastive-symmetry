#!/bin/bash

bash scripts/specs.sh $1
bash scripts/size.sh $1
bash scripts/minfeat.sh $1
bash scripts/tbalance.sh $1
bash scripts/pair_counts.sh $1

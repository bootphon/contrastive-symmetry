#!/bin/bash

python feature_stats.py data/inventories_hc.csv data/inventory_feature_stats.csv
python generate_random.py --featprobs_fn=data/inventory_feature_stats.csv \
  --initial-seed=1 --jobs=100 data/inventory_size_stats.csv tmp \
  data/random_match_inv_mielke_hc_feat.csv
python contrast_stats.py --permutation-seed=1 --jobs=100 \
  data/random_match_inv_mielke_hc_feat.csv tmp \
  results/random_match_inv_mielke_hc_feat_stats_100.csv

python feature_stats.py data/nonvowels_hc.csv data/nonvowel_feature_stats.csv
python generate_random.py --featprobs_fn=data/nonvowel_feature_stats.csv \
  --initial-seed=1 --jobs=100 data/nonvowel_size_stats.csv tmp \
  data/random_match_nonvowel_mielke_hc_feat.csv
python contrast_stats.py --permutation-seed=1 --jobs=100 \
  data/random_match_nonvowel_mielke_hc_feat.csv tmp \
  results/random_match_nonvowel_mielke_hc_feat_stats_100.csv

python feature_stats.py data/vowels_hc.csv data/vowel_feature_stats.csv
python generate_random.py --featprobs_fn=data/vowel_feature_stats.csv \
  --initial-seed=1 --jobs=100 data/vowel_size_stats.csv tmp \
  data/random_match_vowel_mielke_hc_feat.csv
python contrast_stats.py --permutation-seed=1 --jobs=100 \
  data/random_match_vowel_mielke_hc_feat.csv tmp \
  results/random_match_vowel_mielke_hc_feat_stats_100.csv

python feature_stats.py data/stops_hc.csv data/stops_feature_stats.csv
python generate_random.py --featprobs_fn=data/stops_feature_stats.csv \
  --initial-seed=1 --jobs=100 data/stops_size_stats.csv tmp \
  data/random_match_stops_mielke_hc_feat.csv
python contrast_stats.py --permutation-seed=1 --jobs=100 \
  data/random_match_stops_mielke_hc_feat.csv tmp \
  results/random_match_stops_mielke_hc_feat_stats_100.csv


python size_stats.py data/inventories_hc.csv data/inventory_size_stats.csv
python generate_random.py --nfeat=23 --initial-seed=1 --jobs=100 \
  data/inventory_size_stats.csv tmp data/random_match_inv_mielke_hc.csv
python contrast_stats.py --permutation-seed=1 --jobs=100 \
  data/random_match_inv_mielke_hc.csv tmp \
  results/random_match_inv_mielke_hc_stats_100.csv

python size_stats.py data/nonvowels_hc.csv data/nonvowel_size_stats.csv
python generate_random.py --nfeat=23 --initial-seed=1 --jobs=16 \
  data/nonvowel_size_stats.csv tmp data/random_match_nonvowel_mielke_hc.csv
python contrast_stats.py --permutation-seed=1 --jobs=32 \
  data/random_match_nonvowel_mielke_hc.csv tmp \
  results/random_match_nonvowel_mielke_hc_stats_100.csv

python size_stats.py data/vowels_hc.csv data/vowel_size_stats.csv
python generate_random.py --nfeat=23 --initial-seed=1 --jobs=16 \
  data/vowel_size_stats.csv tmp data/random_match_vowel_mielke_hc.csv
python contrast_stats.py --permutation-seed=1 --jobs=100 \
  data/random_match_vowel_mielke_hc.csv tmp \
  results/random_match_vowel_mielke_hc_stats_100.csv

python size_stats.py data/stops_hc.csv data/stops_size_stats.csv
python generate_random.py --nfeat=23 --initial-seed=1 --jobs=16 \
  data/stops_size_stats.csv tmp data/random_match_stop_mielke_hc.csv
python contrast_stats.py --permutation-seed=1 --jobs=100 \
  data/random_match_stop_mielke_hc.csv tmp \
  results/random_match_stop_mielke_hc_stats_100.csv



python segment_stats.py data/inventories_hc.csv data/inventory_segment_stats.csv
python generate_random.py --segfreqs_fn=data/inventory_segment_stats.csv \
 --initial-seed=1 --jobs=100 data/inventory_size_stats.csv tmp \
 data/random_match_inv_mielke_hc_prop.csv
python contrast_stats.py --permutation-seed=1 --jobs=100 \
  data/random_match_inv_mielke_hc_prop.csv tmp \
  results/random_match_inv_mielke_hc_prop_stats_100.csv

python segment_stats.py data/nonvowels_hc.csv data/nonvowel_segment_stats.csv
python generate_random.py --segfreqs_fn=data/nonvowel_segment_stats.csv \
 --initial-seed=1 --jobs=16 data/nonvowel_size_stats.csv tmp \
 data/random_match_nonvowel_mielke_hc_prop.csv
python contrast_stats.py --permutation-seed=1 --jobs=32 \
  data/random_match_nonvowel_mielke_hc_prop.csv tmp \
  results/random_match_nonvowel_mielke_hc_prop_stats_100.csv

python segment_stats.py data/vowels_hc.csv data/vowel_segment_stats.csv
python generate_random.py --segfreqs_fn=data/vowel_segment_stats.csv \
 --initial-seed=1 --jobs=16 data/vowel_size_stats.csv tmp \
 data/random_match_vowel_mielke_hc_prop.csv
python contrast_stats.py --permutation-seed=1 --jobs=32 \
  data/random_match_vowel_mielke_hc_prop.csv tmp \
  results/random_match_vowel_mielke_hc_prop_stats_100.csv

python segment_stats.py data/stops_hc.csv data/stops_segment_stats.csv
python generate_random.py --segfreqs_fn=data/stops_segment_stats.csv \
 --initial-seed=1 --jobs=16 data/stops_size_stats.csv tmp \
 data/random_match_stop_mielke_hc_prop.csv
python contrast_stats.py --permutation-seed=1 --jobs=100 \
  data/random_match_stop_mielke_hc_prop.csv tmp \
  results/random_match_stop_mielke_hc_prop_stats_100.csv


python contrast_stats.py --permutation-seed=1 --jobs=32 \
  data/inventories_hc.csv tmp \
  results/inv_stats_hc_100.csv

python contrast_stats.py --permutation-seed=1 --jobs=32 \
  data/stops_hc.csv tmp \
  results/stop_stats_hc_100.csv

python contrast_stats.py --permutation-seed=1 --jobs=32 \
  data/nonvowels_hc.csv tmp \
  results/nonvowel_stats_hc_100.csv

python contrast_stats.py --permutation-seed=1 --jobs=32 \
  data/vowels_hc.csv tmp \
  results/nonvowel_stats_hc_100.csv



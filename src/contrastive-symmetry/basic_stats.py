'''
Created on 2015-02-26

@author: emd
'''
import argparse
import sys
import numpy as np
import pandas as pd
from inventory_io import read_inventories, default_feature_value_npf
from inventory_util import write_freq_table, add_all_to_counts, add_to_counts,\
    write_value_freq_table, add_all_to_value_table

__version__ = '1.0'

def read_sizes(fn):
    raw_table = pd.read_csv(fn, dtype=np.str)
    sizes = raw_table.ix[:, 0].values.astype(int)
    freqs = raw_table.ix[:, 1].values.astype(int)
    return sizes, freqs


def read_segment_freqs(fn, feature_value_npf=default_feature_value_npf):
    raw_table = pd.read_csv(fn, dtype=np.str)
    ncol = raw_table.shape[1]
    segment_names = raw_table.ix[:, 0].values.astype(str)
    segments_raw = raw_table.ix[:, 1:(ncol - 1)]
    freqs = raw_table.ix[:, ncol - 1].values.astype(int)
    i_segments_raw = segments_raw.iterrows()
    first_segment_raw = i_segments_raw.next()[1]
    features = first_segment_raw.keys().tolist()
    segments = [feature_value_npf(first_segment_raw.values)]
    segments += [feature_value_npf(t[1].values) for t in i_segments_raw]
    return segments, segment_names, features, freqs


def read_feature_probs(fn, feature_value_npf=default_feature_value_npf):
    raw_table = pd.read_csv(fn, dtype=np.str)
    features = raw_table.ix[:, 0].values.astype(str).tolist()
    feature_probs = raw_table.ix[:, 1].values.astype(float)
    nfeat = len(features)
    nsegs = pow(2, nfeat)
    segment_names = ['s' + str(i + 1) for i in range(nsegs)]
    return segment_names, features, feature_probs



def create_parser():
    """Return command-line parser."""
    parser = argparse.ArgumentParser()
    parser.add_argument('--version', action='version',
                        version='%(prog)s ' + __version__)
    parser.add_argument('--skipcols', type=int, default=2,
                        help='number of columns to skip before assuming '
                        'the rest is features')
    parser.add_argument('--language-colindex', type=int, default=0,
                        help='index of column containing language name')
    parser.add_argument('--seg-colindex', type=int, default=1,
                        help='index of column containing segment label')
    parser.add_argument('stat', help='stat table to generate [size: '
                        'inventory sizes; feature: feature "+" probabilities; '
                        'segment: segment frequencies]',
                        choices=['size', 'feature', 'segment'])
    parser.add_argument('inventories_location',
                        help='csv containing all inventories')
    parser.add_argument('output_file',
                        help='output file (default: stdout)', nargs='?',
                        default=None)
    return parser


def parse_args(arguments):
    """Parse command-line options."""
    parser = create_parser()
    args = parser.parse_args(arguments)
    return args


def size_table(inventories):
    size_counts = {}
    for inventory in inventories:
        size = inventory["Feature_Table"].shape[0]
        add_to_counts(size_counts, size)
    return size_counts


def feature_table(inventories, features):
    feature_pos_counts = np.zeros((len(features),))
    feature_filled_counts = np.zeros((len(features),))
    for inventory in inventories:
        feature_pos_counts += (inventory["Feature_Table"] == 1).sum(axis=0)
        feature_filled_counts += (inventory["Feature_Table"] != 0).sum(axis=0)
    feature_filled_counts[feature_filled_counts==0] = 1
    feature_probs = feature_pos_counts/feature_filled_counts
    feature_probs_table = dict(zip(features, feature_probs))
    return feature_probs_table


def segment_value_table(inventories):
    segment_values = {}
    segment_counts = {}
    for inventory in inventories:
        add_all_to_value_table(segment_values, inventory["Segment_Names"],
                               inventory["Feature_Table"])
        add_all_to_counts(segment_counts, inventory["Segment_Names"])
    return segment_values, segment_counts


if __name__ == '__main__':
    args = parse_args(sys.argv[1:])

    inventories, features = read_inventories(args.inventories_location,
                                             args.skipcols,
                                             args.language_colindex,
                                             args.seg_colindex)
    
    if args.stat == 'size':
        table = size_table(inventories)
        write_freq_table(args.output_file, table, 'size')
    elif args.stat == 'feature':
        table = feature_table(inventories, features)
        write_freq_table(args.output_file, table, 'feature',
                         freq_col_name='prob', sort=False)
    elif args.stat == 'segment':
        values, table = segment_value_table(inventories)
        write_value_freq_table(args.output_file, values, table, features)

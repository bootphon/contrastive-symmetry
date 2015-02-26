'''
Created on 2015-02-26

@author: emd
'''
import argparse
import sys
import numpy as np
from inventory_io import read_inventories
from util import write_freq_table, add_all_to_counts, add_to_counts
from segment_stats import write_value_freq_table, add_all_to_value_table

__version__ = '0.0.1'


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
                         freq_col_name='prob', sorted=False)
    elif args.stat == 'segment':
        values, table = segment_value_table(inventories)
        write_value_freq_table(args.output_file, values, table, features)

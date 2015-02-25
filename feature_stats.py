'''
Created on 2015-02-12

@author: emd
'''
import sys
from inventory_io import read_inventories
import numpy as np
import argparse
from util import write_freq_table

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


if __name__ == '__main__':
    args = parse_args(sys.argv[1:])

    inventories, features = read_inventories(args.inventories_location,
                                             args.skipcols,
                                             args.language_colindex,
                                             args.seg_colindex)
    feature_pos_counts = np.zeros((len(features),))
    feature_filled_counts = np.zeros((len(features),))
    for inventory in inventories:
        feature_pos_counts += (inventory["Feature_Table"] == 1).sum(axis=0)
        feature_filled_counts += (inventory["Feature_Table"] != 0).sum(axis=0)
    feature_filled_counts[feature_filled_counts==0] = 1
    feature_probs = feature_pos_counts/feature_filled_counts
    feature_probs_table = dict(zip(features, feature_probs))
    write_freq_table(args.output_file, feature_probs_table, 'feature',
                     freq_col_name='prob', sorted=False)
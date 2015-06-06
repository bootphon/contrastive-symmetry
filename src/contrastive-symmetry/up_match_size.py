'''
Created on 2015-06-04

@author: emd
'''
import argparse
import sys
from inventory_io import read_inventories, write_inventory
from stats import size_table
import os
from generate_random import inventory_colnames

__version__ = '0.0.1'

def write_inventories(out_fn, inventories, features):
    out_dir = os.path.dirname(out_fn)
    if out_dir != '' and not os.path.isdir(out_dir):
        os.makedirs(out_dir)
    hf_out = open(out_fn, 'w')
    hf_out.write(','.join(inventory_colnames(features)) + '\n')
    hf_out.close()
    for i in inventories:
        i["segment_names"] = i["Segment_Names"]
        i["segments"] = i["Feature_Table"]
        write_inventory(i, out_fn, append=True)

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
    parser.add_argument('--jobs', type=int, default=1,
                        help='number of parallel jobs; '
                        'match CPU count if value is less than 1')
    parser.add_argument('to_match',
                        help='inventories to match sizes of')
    parser.add_argument('to_shore_up',
                        help='inventories to shore up to size')
    parser.add_argument('output',
                        help='output file')
    return parser


def parse_args(arguments):
    """Parse command-line options."""
    parser = create_parser()
    args = parser.parse_args(arguments)
    return args


if __name__ == '__main__':
    args = parse_args(sys.argv[1:])

    inventories_to_match, features = read_inventories(args.to_match,
                                                      args.skipcols,
                                                      args.language_colindex,
                                                      args.seg_colindex)
    inventories_to_shore_up, _ = read_inventories(args.to_shore_up,
                                             args.skipcols,
                                             args.language_colindex,
                                             args.seg_colindex)
    sizes_to_match = size_table(inventories_to_match)
    sizes_to_shore_up = size_table(inventories_to_shore_up)
    print sizes_to_match
    print sizes_to_shore_up
    all_ = []
    for size in sizes_to_match:
        if size not in sizes_to_shore_up:
            sizes_to_shore_up[size] = 0
        all_of_that_size = [inv for inv in inventories_to_shore_up if
                            inv["Feature_Table"].shape[0] == size]
        if sizes_to_match[size] <= sizes_to_shore_up[size]:
            bolsterers = []
        else:
            origs = [inv for inv in inventories_to_match if
                     inv["Feature_Table"].shape[0] == size]
            still_need = sizes_to_match[size] - sizes_to_shore_up[size]
            bolsterers = origs[0:still_need]
        all_ += all_of_that_size[0:sizes_to_match[size]] + bolsterers
        write_inventories(args.output, all_, features)

    
'''
Created on 2015-02-09

@author: emd
'''
import sys
from inventory_io import read_inventories, default_value_feature_npf
import argparse
from util import add_all_to_counts

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


def write_value_freq_table(output_file, values, table, features,
                           value_feature_npf=default_value_feature_npf):
    if output_file is None:
        hf_out = sys.stdout
    else:
        hf_out = open(output_file, 'w')
    hf_out.write(','.join(['label'] + features.tolist() + ['freq']) + '\n')
    sorted_segments = sorted(table, key=lambda k: table[k], reverse=True)
    for segment in sorted_segments:
        hf_out.write(
            ','.join([segment] + value_feature_npf(values[segment]).tolist() +
                     [str(table[segment])]) + '\n')
    hf_out.close()



def add_all_to_value_table(table, items, values):
    for i, item in enumerate(items):
        if item not in table:
            table[item] = values[i]

if __name__ == '__main__':
    args = parse_args(sys.argv[1:])

    inventories, features = read_inventories(args.inventories_location,
                                             args.skipcols,
                                             args.language_colindex,
                                             args.seg_colindex)
    segment_counts = {}
    segment_values = {}
    for inventory in inventories:
        add_all_to_counts(segment_counts, inventory["Segment_Names"])
        add_all_to_value_table(segment_values, inventory["Segment_Names"],
                               inventory["Feature_Table"])

    write_value_freq_table(args.output_file, segment_values, segment_counts,
                             features)

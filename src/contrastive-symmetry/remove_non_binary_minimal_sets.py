'''
Created on 2015-06-03

@author: emd
'''
import argparse
import sys
from inventory_io import read_inventories, read_feature_sets

__version__ = '0.0.1'

def spec_id(feature_set, feature_names):
    feat_name_strings = [feature_names[c] for c in feature_set]
    return "'" + ":".join(feat_name_strings) + "'"


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
    parser.add_argument('inventories_location',
                        help='csv containing all inventories')
    parser.add_argument('minimal_location',
                        help='csv containing all minimal feature sets')
    parser.add_argument('output_file',
                        help='output file')
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
    minimal_sets = read_feature_sets(args.minimal_location,
                                     inventories, binary_only=True)
    with open(args.output_file, "w") as hf:
        col_names = ["language", "num_features"] + features + ["spec_id"]
        hf.write(','.join(col_names) + '\n')
        hf.flush()
        for language in minimal_sets:
            feature_sets = minimal_sets[language]
            for fs in feature_sets:
                prefix = [language, str(len(fs))]
                feature_spec = ["T" if index in fs else "F" for index
                                in range(len(features))]
                hf.write(','.join(prefix + feature_spec +
                                  [spec_id(fs, features)]) + '\n')
        hf.write('\n')

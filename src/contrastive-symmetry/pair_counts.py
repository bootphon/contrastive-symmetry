'''
Created on 2015-06-03

@author: emd
'''
import sys
from inventory_io import read_inventories, read_feature_sets
import argparse
import os
from joblib.parallel import delayed, Parallel
from partition import to_row_partition
from util import get_cols_except

__version__ = '0.0.1'

def minimal_count(table, features, on):
    if table.shape[0] == 2 and len(features) == 1:
        return 1
    full_rank = table.shape[0]
    table_reduced = get_cols_except(table, features, on)
    reduced_partition = to_row_partition(table_reduced)
    return full_rank - len(reduced_partition)

def output_filename(inventory):
    return inventory["Language_Name"] + ".csv"

def spec_id(feature_set, feature_names):
    feat_name_strings = [feature_names[c] for c in feature_set]
    return "'" + ":".join(feat_name_strings) + "'"

def count_and_write(inventory, minimal_sets, output_nf, feature_names):
    with open(output_nf, "w") as hf:
        col_names = ("language", "feature", "pair_count", "spec_id")
        hf.write(','.join(col_names) + '\n')
        hf.flush()
        inventory_table = inventory["Feature_Table"]
        for minimal_set in minimal_sets:
            for feature_num in minimal_set:
                minimal_count_val = minimal_count(inventory_table, minimal_set,
                                                  feature_num)
                to_print = (inventory["Language_Name"],
                            feature_names[feature_num],
                            str(minimal_count_val),
                            spec_id(minimal_set, feature_names))
                hf.write(','.join(to_print) + '\n')
                hf.flush()
        hf.write('\n')

def write_pair_counts_parallel(inventories, minimal_sets, features,
                           out_dir, n_jobs):
    if not os.path.isdir(out_dir):
        os.makedirs(out_dir)
    output_nfs = [os.path.join(out_dir, output_filename(inv)) for
                  inv in inventories]
    Parallel(n_jobs=n_jobs)(delayed(count_and_write)(inventories[i],
                            minimal_sets[inventories[i]["Language_Name"]],
                            output_nfs[i], features) for i in 
                            range(len(inventories)))


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
    parser.add_argument('output_dir',
                        help='output directory')
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
    inventories = [inv for inv in inventories if inv["Language_Name"] in
                   minimal_sets]
    write_pair_counts_parallel(inventories, minimal_sets, features, 
                               args.output_dir, args.jobs)
    
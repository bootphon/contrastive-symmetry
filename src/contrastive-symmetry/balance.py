'''
Created on 2015-05-21

@author: emd
'''
import argparse
import sys
from inventory_io import read_inventories, default_value_feature_dict,\
    read_feature_sets
from feature_lattice import FeatureLattice
from util import binary_counts
import os
from joblib.parallel import delayed, Parallel


__version__ = '0.0.1'

def balance(n_minus, n_plus):
    if n_minus == 0 or n_plus == 0:
        return 0
    else:
        return abs(n_minus - n_plus)

class BalanceIterator(object):

    def __init__(self, inventory, minimal_subsets):
        self.inventory_table = inventory["Feature_Table"]
        self.tree = FeatureLattice(minimal_subsets, self.inventory_table)
        self.advance_node()

    def __iter__(self):
        return self
    
    def advance_node(self):
        node = self.tree.next()
        self.subspace_features, self.current_feature, self.depth = node
        partition = self.tree.get_partition(self.subspace_features)
        self.subspace_iterator = partition.__iter__()
        self.subspace = self.subspace_iterator.next()

    def advance_subspace_within_node(self):
        try:
            self.subspace = self.subspace_iterator.next()
        except StopIteration:
            raise

    def next(self):
        try:
            self.advance_subspace_within_node()
        except:
            try:
                self.advance_node()
            except:
                raise StopIteration()
        vec = self.inventory_table[self.subspace, self.current_feature]
        side_1, side_2 = binary_counts(vec)
        return (self.current_feature, self.tree.depth - 1,
                self.subspace_features, self.subspace, side_1, side_2,
                balance(side_1, side_2))


def output_filename(inventory):
    return inventory["Language_Name"] + ".csv"

def subspace_id(columns, row, table, feature_names):
    vec = table[row,:]
    feat_val_strings = [feature_names[c] + "=" + 
                        default_value_feature_dict[vec[c]] for
                        c in columns]
    return "'" + ":".join(feat_val_strings) + "'"

def compile_and_write(inventory, minimal_sets, output_nf, feature_names):
    with open(output_nf, "w") as hf:
        col_names = ("language", "feature", "minus_count", "plus_count",
                     "balance", "subspace_dim", "subspace_id")
        hf.write(','.join(col_names) + '\n')
        hf.flush()
        for balance_stat_tuple in BalanceIterator(inventory, minimal_sets):
            (feature_num, depth, subspace_features, subspace_rows,
             minus_count, plus_count, balance_) = balance_stat_tuple
            to_print = (inventory["Language_Name"], feature_names[feature_num],
                        str(minus_count), str(plus_count), str(balance_),
                        str(depth), subspace_id(subspace_features,
                                                subspace_rows[0],
                                                inventory["Feature_Table"],
                                                feature_names))
            hf.write(','.join(to_print) + '\n')
        hf.write('\n')


def write_balance_parallel(inventories, minimal_sets, features, out_dir,
                           n_jobs):
    if not os.path.isdir(out_dir):
        os.makedirs(out_dir)
    output_nfs = [os.path.join(out_dir, output_filename(inv)) for
                  inv in inventories]
    Parallel(n_jobs=n_jobs)(delayed(compile_and_write)(inventories[i],
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
    if not len(minimal_sets) == len(inventories):
        raise
    write_balance_parallel(inventories, minimal_sets, features,
                           args.output_dir, args.jobs)
    

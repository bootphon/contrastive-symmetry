'''
Created on 2015-05-21

@author: emd
'''
import argparse
import sys
from inventory_io import read_inventories, default_value_feature_dict,\
    read_feature_sets
from feature_lattice import FeatureLattice
from util import binary_counts, spec_id
import os
from joblib.parallel import delayed, Parallel


__version__ = '0.0.1'

def balance(n_minus, n_plus):
    if n_minus == 0 or n_plus == 0:
        return 0
    else:
        return abs(n_minus - n_plus)

class BalanceIterator(object):
    '''
    Return all tree balance statistics, given a set of possible
    specifications (minimal_subsets).     

    The iterator returns tuples (for the purposes of the
    top level feature balance statistic we actually use as of
    January 2 2016, DIMENSION and FEATURE SUBSET can be ignored,
    and SET OF SEGMENTS is trivial):
    
        (FEATURE, DIMENSION, FEATURE SUBSET, SET OF SEGMENTS,
         NUM MINUS, NUM PLUS, BALANCE, SOURCE SPECIFICATIONS)
    
    FEATURE: a feature
    DIMENSION: number of other features specified (tree depth - 1)
               (for top level balance, always 0)
    FEATURE SUBSET: other features specified
               (for top level balance, always {})
    SET OF SEGMENTS: a set of segments that all have the same specification
               for FEATURE SUBSET
               (for top level balance, always the whole inventory)
    NUM MINUS: number of segments in SET OF SEGMENTS with the "negative"
               value of FEATURE (-1 if the two values are -1/+1, 0 if the
               two values are 0 and anything else)
    NUM PLUS: number of segments in SET OF SEGMENTS with the "positive"
               value of FEATURE (-1 if the two values are -1/+1, the
               non-zero value if the two values are 0 and anything else)
    BALANCE: absolute value of NUM MINUS - NUM PLUS, unless one of the
               values is zero, in which case 0
               (for top level balance, we never get to the special
               case if we only have minimal specifications in
               minimal_subsets)
    SOURCE SPECIFICATIONS: all specifications which contain FEATURE
               SUBSET|{FEATURE}
    
    If you think of a contrastive hierarchy, each non-leaf node in the tree
    will correspond to some subset of features specified in some
    particular way, and the tree balance statistic for that node is
    the absolute value of the difference in size (number of leaf nodes) of 
    each of the children, where each child corresponds to another
    feature that we could add to the specification.
    
    One tree balance statistic will be taken from one of the possible
    non-leaf nodes in one of the possible contrastive hierarchies
    (corresponding to one of the orderings of one of the 
    sets of features that can specify the inventory). A given FEATURE
    SUBSET could (and generally will) appear in many different contrastive
    hirarchies, depending on the value of FEATURE; each different value of
    FEATURE corresponds to one possible expansion at the next level
    of the contrastive hierarchy.
    
    It's not the case that adding a particular feature to every node in
    a contrastive hierarchy will always be contrastive (yield a 
    split that we can interpret as two child nodes). It could
    be that some feature in the specifying set is not contrastive for
    some portion of the inventory, but that feature still needs to
    be in the specifiying set because it is contrastive for some other
    part of the inventory. (We can, but don't need really to,
    imagine that in this case there is a non-branching node in the
    tree.) We declare the score to be zero in this case. This
    never comes up for the top-level balance with minimal specifying
    sets. 
    '''
    def __init__(self, inventory, minimal_subsets, max_dim=None):
        self.inventory_table = inventory["Feature_Table"]
        self.tree = FeatureLattice(minimal_subsets, self.inventory_table,
                                   max_dim+1)
        self.initialized = False

    def __iter__(self):
        return self
    
    def curr_source_specs(self):
        num_specs = [self.tree.feature_sets[s] for s in self.source_specs]
        return num_specs
    
    def advance_node(self):
        node = self.tree.next()
        self.subspace_features, self.current_feature, \
            self.source_specs, self.depth = node
        partition = self.tree.get_partition(self.subspace_features)
        self.subspace_iterator = partition.__iter__()
        self.subspace = self.subspace_iterator.next()

    def advance_subspace_within_node(self):
        try:
            self.subspace = self.subspace_iterator.next()
        except StopIteration:
            raise

    def next(self):
        if not self.initialized:
            try:
                self.advance_node()
                self.initialized = True
            except:
                raise StopIteration()
        else:
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
                balance(side_1, side_2), self.curr_source_specs())


def output_filename(inventory):
    return inventory["Language_Name"] + ".csv"

def subspace_id(columns, row, table, feature_names):
    vec = table[row,:]
    feat_val_strings = [feature_names[c] + "=" + 
                        default_value_feature_dict[vec[c]] for
                        c in columns]
    return "'" + ":".join(feat_val_strings) + "'"

def compile_and_write(inventory, minimal_sets, max_dim, output_nf,
                      feature_names):
    with open(output_nf, "w") as hf:
        col_names = ("language", "feature", "minus_count", "plus_count",
                     "balance", "subspace_dim", "subspace_id", "spec_id")
        hf.write(','.join(col_names) + '\n')
        hf.flush()
        for balance_stat_tuple in BalanceIterator(inventory, minimal_sets,
                                                  max_dim):
            (feature_num, depth, subspace_features, subspace_rows,
             minus_count, plus_count, balance_, specs) = balance_stat_tuple
            for s in specs:
                to_print = (inventory["Language_Name"],
                            feature_names[feature_num],
                            str(minus_count), str(plus_count), str(balance_),
                            str(depth), subspace_id(subspace_features,
                                                    subspace_rows[0],
                                                    inventory["Feature_Table"],
                                                    feature_names),
                            spec_id(s, feature_names))
                hf.write(','.join(to_print) + '\n')
                hf.flush()
        hf.write('\n')


def write_balance_parallel(inventories, minimal_sets, features, max_dim,
                           out_dir, n_jobs):
    if not os.path.isdir(out_dir):
        os.makedirs(out_dir)
    output_nfs = [os.path.join(out_dir, output_filename(inv)) for
                  inv in inventories]
    Parallel(n_jobs=n_jobs)(delayed(compile_and_write)(inventories[i],
                            minimal_sets[inventories[i]["Language_Name"]],
                            max_dim, output_nfs[i], features) for i in 
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
    parser.add_argument('--max-dim', type=int, default=None,
                        help='maximum dimension of restricting subset to'
                        'report on')
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
    write_balance_parallel(inventories, minimal_sets, features, args.max_dim,
                           args.output_dir, args.jobs)
    

'''
Created on 2015-05-18

@author: emd
'''
import argparse
import sys
from inventory_io import read_inventories
from util import has_one, get_all
from lattice import expand, expand_without_collapsing, collapse_expansions
from inventory_util import to_row_partition, is_full_rank
from joblib.parallel import Parallel, delayed
import os
import math


__version__ = '0.0.1'


class MinimalSubsetsFromBottom(object):

    """An iterator over all the subsets of the feature set
    that specify an inventory which are minimal, meaning 
    that no subset can be used to specify the inventory.

    Starting from the bottom (empty set) of the lattice of
    subsets of the feature set, expands nodes in the lattice to find minimal
    sets, skipping over nodes that are known to be useless.
    Nodes are useless if (i) they contain a superset of a known
    minimal set or if (ii) they contain a redundant feature, i.e., a feature
    which is never potentially contrastive given the other features in the
    set.
    """

    def __init__(self, inventory):
        """
        Args:
            inventory: an inventory, as returned by
             inventory_io.read_inventories (a container with item
             "Feature_Table", a numpy array with segments as rows and feature
             values as columns)
        """
        self.frontier = [set()]
        self.found_on_frontier = []
        self.found = []
        self.inventory_table = inventory["Feature_Table"]
        self.feature_nums = range(self.inventory_table.shape[1])
        self.partition_cache = {}

    def __iter__(self):
        return self

    def cached_partition(self, subset):
        """Get a partition from the cache or create it and cache it.
        """
        t = tuple(subset)
        if not self.partition_cache.has_key(t):
            spec = self.inventory_table[:, t]
            self.partition_cache[t] = to_row_partition(spec)
        return self.partition_cache[t]

    def cached_partition_expansion(self, partition, subset, new_feature=None):
        """Get a partition from the cache or create it by expanding
        an existing partition and cache it. If partition is in fact
        empty (not really a partition, is it) then the new partition
        is created de novo. Can get a speedup if you can specify which
        single new feature index you need to check.
        """
        if len(partition) == 0:
            return self.cached_partition(subset)
        t = tuple(subset)
        if not self.partition_cache.has_key(t):
            if new_feature is None:
                spec = self.inventory_table[:, t]
            else:
                spec = self.inventory_table[:, (new_feature,)]
            new_partition = []
            for row_set in partition:
                subpartition_r = to_row_partition(spec[row_set, :])
                subpartition = [get_all(row_set, sr) for sr in subpartition_r]
                new_partition += subpartition
            self.partition_cache[t] = new_partition
        return self.partition_cache[t]

    def is_spec(self, subset):
        """Check whether subset allows a specification of the inventory.
        """
        rank = len(self.cached_partition(subset))
        return rank == self.inventory_table.shape[0]

    def is_rank_more_than_one(self, subset):
        """Check whether subset is of rank strictly more than one.
        """
        partition = self.cached_partition(subset)
        rank = len(partition)
        return rank > 1

    def is_rank_increase(self, subset1, subset2):
        """Check whether subset2 is a rank increase with respect to 
        subset1, i.e., whether the rank of the inventory table
        with respect to subset1 increases when the feature(s) in
        subset2 are added.
        Presupposes that subset2 is a superset of subset1, and
        raises a ValueError if this is not the case.
        """
        if not subset2.issuperset(subset1):
            raise ValueError()
        new_features = subset2 - subset1
        if len(new_features) == 1:
            new_feature = new_features.pop()
        else:
            new_feature = None
        partition_1 = self.cached_partition(subset1)
        partition_2 = self.cached_partition_expansion(partition_1, subset2,
                                                      new_feature)
        rank1 = len(partition_1)
        rank2 = len(partition_2)
        if rank2 > rank1:
            return True
        return False

    def is_good_expansion(self, current, proposal):
        """Check a proposed expansion (proposal) of a feature set (current)
        to see whether it is good. proposal is not good if either, (i), it's a
        superset of a known minimal set, (ii), it is extensionally
        equivalent to current with respect to the subset of the
        inventory that it can specify, or (iii), it can only specify one
        phoneme (rank 1).
        """
        if not self.is_rank_increase(current, proposal):
            return False
        if not self.is_rank_more_than_one(proposal):
            return False
        if has_one(self.found, proposal.issuperset):
            return False
        return proposal

    def is_expandable(self, current):
        """Check a node to see whether it should be expanded at all.
        It shouldn't if it's a known minimal set.
        """
        if current in self.found:
            return False
        return True

    def node_to_expansions(self, set_of_features, is_good_expansion=None):
        """Expand a feature set by providing a version with each of
        the features in the base set which is not already in the 
        feature set.
        """
        result_l = []
        for new_feature in self.feature_nums:
            if not new_feature in set_of_features:
                expansion = set_of_features.union([new_feature])
                if is_good_expansion is None or is_good_expansion(expansion):
                    result_l.append(expansion)
        return result_l

    def next(self):
        """Return the next minimal subset found, expanding
        the frontier to find more if necessary.
        """
        if not self.found_on_frontier:
            self.frontier = expand(self.frontier, self.node_to_expansions,
                                   self.is_expandable,
                                   is_good_expansion_post_collapse=
                                   self.is_good_expansion)
            while self.frontier:
                min_on_frontier = [f for f in self.frontier if self.is_spec(f)]
                if min_on_frontier:
                    self.found_on_frontier = min_on_frontier
                    for new_found in min_on_frontier:
                        assert new_found not in self.found
                    self.found += min_on_frontier
                    break
                self.frontier = expand(self.frontier, self.node_to_expansions,
                                       self.is_expandable,
                                       is_good_expansion_post_collapse=
                                       self.is_good_expansion)
            if not self.found_on_frontier:
                raise StopIteration()
        return self.found_on_frontier.pop()


class MinimalSubsetsFromTop(object):

    """An iterator over all the subsets of the feature set
    that specify an inventory which are minimal, meaning 
    that no subset can be used to specify the inventory.

    Starting from the top (full set) of the lattice of
    subsets of the feature set, expands nodes in the lattice to find minimal
    sets, skipping over nodes that are known to be useless.
    Nodes are useless if they cannot specify the inventory.
    """

    def __init__(self, inventory):
        """
        Args:
            inventory: an inventory, as returned by
             inventory_io.read_inventories (a container with item
             "Feature_Table", a numpy array with segments as rows and feature
             values as columns)
        """
        self.found_on_frontier = []
        self.inventory_table = inventory["Feature_Table"]
        self.feature_nums = range(self.inventory_table.shape[1])
        self.frontier = [set(self.feature_nums)]
        if self.is_spec(self.frontier[0]):
            self.no_specs = False
            self.frontier_candidates = expand_without_collapsing(self.frontier,
                                                    self.node_to_expansions,
                                                    self.is_expandable,
                                                    self.is_spec)
        else:
            self.no_specs = True

    def __iter__(self):
        return self

    def is_spec(self, subset):
        """Check whether subset allows a specification of the inventory.
        """
        t = tuple(subset)
        spec = self.inventory_table[:, t]
        return is_full_rank(spec)

    def is_expandable(self, current):
        """Check a node to see whether it should be expanded at all.
        It shouldn't if it's the empty set.
        """
        return len(current) > 0

    def node_to_expansions(self, set_of_features, is_good_expansion=None):
        """Elaborate a feature set by providing a version lacking each of
        the features in the set.
        """
        result_l = []
        for removed_feature in set_of_features:
            elaboration = set_of_features - {removed_feature}
            if is_good_expansion is None or is_good_expansion(elaboration):
                result_l.append(elaboration)
        return result_l

    def next(self):
        """Return the next minimal subset found, expanding
        the frontier to find more if necessary.
        """
        if not self.found_on_frontier:
            while self.frontier and not self.no_specs:
                is_minimal = [not e for e in self.frontier_candidates]
                self.found_on_frontier = [self.frontier[i] for
                                          i in range(len(self.frontier)) if
                                          is_minimal[i]]
                if not self.found_on_frontier:
                    self.frontier = collapse_expansions(self.frontier,
                                                        self.frontier_candidates)
                    self.frontier_candidates = expand_without_collapsing(
                        self.frontier,
                        self.node_to_expansions,
                        self.is_expandable,
                        self.is_spec)
                else:
                    self.frontier = [self.frontier[i] for
                                     i in range(len(self.frontier)) if
                                     not is_minimal[i]]
                    break
            if not self.found_on_frontier:
                raise StopIteration()
        return self.found_on_frontier.pop()


def output_filename(inventory):
    return inventory["Language_Name"] + ".csv"


def iterator_bottom_up(inventory):
    return MinimalSubsetsFromBottom(inventory)


def iterator_top_down(inventory):
    return MinimalSubsetsFromTop(inventory)


def choose_search(inventory, expected_economy):
    # top down has slower operations but both are bloody slow, so whatever
    max_bottom_up = math.ceil(inventory["Feature_Table"].shape[1] / 2.0)
    expected_features = inventory["Feature_Table"].shape[0] / expected_economy
    if expected_features <= max_bottom_up:
        return iterator_bottom_up
    else:
        return iterator_top_down


def search_and_write(inventory, iterator, output_nf, feature_names):
    with open(output_nf, "w") as hf:
        col_names = ["language", "num_features"] + feature_names
        hf.write(','.join(col_names) + '\n')
        hf.flush()
        for feature_set in iterator(inventory):
            prefix = [inventory["Language_Name"], str(len(feature_set))]
            feature_spec = ["T" if index in feature_set else "F"
                            for index in range(len(feature_names))]
            hf.write(','.join(prefix + feature_spec) + '\n')
        hf.write('\n')


def write_minimal_parallel(inventories, features, out_dir,
                           expected_economy, n_jobs):
    if not os.path.isdir(out_dir):
        os.makedirs(out_dir)
    search_fns = [choose_search(inv, expected_economy) for inv in inventories]
    output_nfs = [os.path.join(out_dir, output_filename(inv)) for
                  inv in inventories]
    Parallel(n_jobs=n_jobs)(delayed(search_and_write)(inventories[i],
                                                      search_fns[i],
                                                      output_nfs[i], features)
                            for i in range(len(inventories)))


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
    parser.add_argument('--expected-economy', type=float, default=2.5,
                        help='expected feature economy (for choosing'
                        'between top-down and bottom up search)')
    parser.add_argument('inventories_location',
                        help='csv containing all inventories')
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

    write_minimal_parallel(inventories, features, args.output_dir,
                           args.expected_economy, args.jobs)

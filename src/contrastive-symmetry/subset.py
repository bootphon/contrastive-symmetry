'''
Created on 2015-05-18

@author: emd
'''
import argparse
import sys
from inventory_io import read_inventories
from util import has_one, get_all, get_cols_except,\
    collapse_those_containing
from lattice import expand
from joblib.parallel import Parallel, delayed
import os
import numpy
import random
from partition import PartitionCached


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
        self.bottom_frontier = [set()]
        self.found_on_bottom_frontier = []
        self.dont_go_up_from = []
        self.inventory_table = inventory["Feature_Table"]
        self.feature_nums = range(self.inventory_table.shape[1])
        self.partitions = PartitionCached(self.inventory_table)

    def __iter__(self):
        return self

    def is_spec(self, subset):
        """Check whether subset allows a specification of the inventory.
        """
        rank = len(self.partitions.get(subset))
        return rank == self.inventory_table.shape[0]

    def is_rank_more_than_one(self, subset):
        """Check whether subset is of rank strictly more than one.
        """
        partition = self.partitions.get(subset)
        rank = len(partition)
        return rank > 1

    def is_rank_increase(self, cols, new_feature):
        """Check whether adding new_feature (index) is a rank increase with
        respect to cols, i.e., whether the rank of the inventory table
        with respect to cols increases when the feature is added.
        """
        partition_1 = self.partitions.get(cols)
        partition_2 = self.partitions.split(cols, new_feature)
        rank1 = len(partition_1)
        rank2 = len(partition_2)
        if rank2 > rank1:
            return True
        return False

    def not_ruled_out_bottom_up(self, current, new_feature):
        """Check a proposed expansion (proposal) of a feature set (current)
        to see whether it is good. proposal is not good if either, (i), it's a
        superset of a known minimal set, (ii), it is extensionally
        equivalent to current with respect to the subset of the
        inventory that it can specify, or (iii), it can only specify one
        phoneme (rank 1).
        """
        proposal = current.union({new_feature})
        if has_one(self.dont_go_up_from, proposal.issuperset):
            return False
        if not self.is_rank_increase(current, new_feature):
            return False
        if not self.is_rank_more_than_one(proposal):
            return False
        return True

    def should_look_up_from(self, current):
        """Check a node to see whether it should be expanded at all.
        It shouldn't if it's a known minimal set.
        """
        if current in self.dont_go_up_from:
            return False
        return True

    def whats_up(self, set_of_features):
        """Expand a feature set by providing a version with each of
        the features in the base set which is not already in the
        feature set.
        """
        result = [set_of_features | {f} for f in self.feature_nums if
                  not f in set_of_features and
                  self.not_ruled_out_bottom_up(set_of_features, f)]
        return result

    def move_bottom_frontier(self):
        self.bottom_frontier = expand(self.bottom_frontier,
                                      self.whats_up,
                                      parent_filter=self.should_look_up_from)

    def search_bottom_frontier(self):
        self.found_on_bottom_frontier = [f for f in self.bottom_frontier if
                                         self.is_spec(f)]
        if self.found_on_bottom_frontier:
            self.dont_go_up_from += self.found_on_bottom_frontier

    def next(self):
        """Return the next minimal subset found, expanding
        the frontier to find more if necessary.
        """
        if not self.found_on_bottom_frontier:
            self.move_bottom_frontier()
            while self.bottom_frontier:
                self.search_bottom_frontier()
                if self.found_on_bottom_frontier:
                    break
                else:
                    self.move_bottom_frontier()
            if not self.found_on_bottom_frontier:
                raise StopIteration()
        return self.found_on_bottom_frontier.pop()


class MinimalSubsetsFromTop(object):

    """An iterator over all the subsets of the feature set
    that specify an inventory which are minimal, meaning
    that no subset can be used to specify the inventory.

    Starting from the top (full set) of the lattice of
    subsets of the feature set, expands nodes in the lattice to find minimal
    sets, skipping over nodes that are known to be useless.
    Nodes are useless if they (i) cannot specify the inventory or (ii)
    contain a subset of a known non-specifying set.
    """

    def __init__(self, inventory):
        """
        Args:
            inventory: an inventory, as returned by
             inventory_io.read_inventories (a container with item
             "Feature_Table", a numpy array with segments as rows and feature
             values as columns)
        """
        self.found_on_top_frontier = []
        self.dont_go_down_from = [set()]
        self.inventory_table = inventory["Feature_Table"]
        self.feature_nums = range(self.inventory_table.shape[1])
        if self.is_spec(set(self.feature_nums)):
            self.no_specs = False
            self.top_frontier = [set(self.feature_nums)]
            self.search_top_frontier()
        else:
            self.no_specs = True
        self.partitions = PartitionCached(self.inventory_table)

    def __iter__(self):
        return self

    def is_spec(self, cols):
        rank = len(self.partitions.get(cols))
        return rank == self.inventory_table.shape[0]

    def is_not_rank_decrease(self, features, remove_feature):
        """Check whether removing remove_feature would NOT be a
        rank decrease with respect to features, i.e., whether the rank of the
        inventory table with respect to features stays the same when
        remove_feature is removed.
        """
        partition_1 = self.partitions.get(features)
        partition_2 = self.partitions.collapse(features, remove_feature)
        rank1 = len(partition_1)
        rank2 = len(partition_2)
        if rank2 == rank1:
            return True
        return False

    def not_ruled_out_top_down(self, current, remove_feature):
        """Check whether subset allows a specification of the inventory.
        """
        proposal = current - {remove_feature}
        if has_one(self.dont_go_down_from, proposal.issubset):
            return False
        if self.is_not_rank_decrease(current, remove_feature):
            return True
        else:
            self.dont_go_down_from.append(proposal)
            return False

    def whats_down(self, set_of_features):
        """Elaborate a feature set by providing a version lacking each of
        the features in the set.
        """
        result = [set_of_features - {f} for f in set_of_features
                    if self.not_ruled_out_top_down(set_of_features, f)]
        return result

    def has_down(self, set_of_features):
        """Check to see if there is at least one way of removing a feature
        from the node that isn't ruled out.
        """
        for f in set_of_features:
            if self.not_ruled_out_top_down(set_of_features, f):
                return True
        return False

    def is_minimal_from_top(self, node):
        """Presupposes that node is a spec.
        """
        if self.has_down(node):
            return False
        return True

    def search_top_frontier(self):
        self.found_on_top_frontier = [n for n in self.top_frontier if
                                      self.is_minimal_from_top(n)]

    def move_top_frontier(self):
        self.top_frontier = expand(self.top_frontier,
                                   self.whats_down,
                                   child_filter=self.not_ruled_out_top_down)

    def next(self):
        """Return the next minimal subset found, expanding
        the frontier to find more if necessary.
        """
        if self.no_specs:
            raise StopIteration()
        if not self.found_on_top_frontier:
            self.move_top_frontier()
            while self.top_frontier:
                self.search_top_frontier()
                if self.found_on_top_frontier:
                    break
                else:
                    self.move_top_frontier()
            if not self.found_on_top_frontier:
                raise StopIteration()
        return self.found_on_top_frontier.pop()


class MinimalSubsetsFromBothEnds(object):

    """An iterator over all the subsets of the feature set
    that specify an inventory which are minimal, meaning
    that no subset can be used to specify the inventory.

    Working simultaneously from the top (full set) and the bottom
    (empty set) of the lattice of
    subsets of the feature set, expands nodes in the lattice to find minimal
    sets, skipping over nodes that are known to be useless.
    Nodes are useless if they (i) cannot specify the inventory (ii)
    contain a subset of a known non-specifying set (iii) contain a superset
    of a known minimal set or if they (iv) contain a redundant feature, i.e.,
    a feature which is never potentially contrastive given the other features
    in the set.
    """

    def __init__(self, inventory):
        self.inventory_table = inventory["Feature_Table"]
        self.partitions = PartitionCached(self.inventory_table)
        self.feature_nums = range(self.inventory_table.shape[1])
        if self.is_spec(set(self.feature_nums)):
            self.no_specs = False
            self.top_frontier = [set(self.feature_nums)]
            self.top_depth = 0
            self.bottom_frontier = [set()]
            self.bottom_depth = 0
            self.max_frontier_depth = len(self.feature_nums) // 2
            if len(self.feature_nums) % 2 == 0:
                self.odd_midpoint = True
            else:
                self.odd_midpoint = False
            self.dont_go_up_from = []
            self.dont_go_down_from = [set()]
            self.search_top_frontier()
            self.search_bottom_frontier()
        else:
            self.no_specs = True

    def __iter__(self):
        return self

    def is_spec(self, subset):
        rank = len(self.partitions.get(subset))
        return rank == self.inventory_table.shape[0]

    def is_rank_more_than_one(self, subset):
        """Check whether subset is of rank strictly more than one.
        """
        partition = self.partitions.get(subset)
        rank = len(partition)
        return rank > 1

    def is_rank_increase(self, cols, new_feature):
        """Check whether adding new_feature (index) is a rank increase with
        respect to cols, i.e., whether the rank of the inventory table
        with respect to cols increases when the feature is added.
        """
        partition_1 = self.partitions.get(cols)
        partition_2 = self.partitions.split(cols, new_feature)
        rank1 = len(partition_1)
        rank2 = len(partition_2)
        if rank2 > rank1:
            return True
        return False

    def is_not_rank_decrease(self, features, remove_feature):
        """Check whether removing remove_feature would NOT be a
        rank decrease with respect to features, i.e., whether the rank of the
        inventory table with respect to features stays the same when
        remove_feature is removed.
        """
        partition_1 = self.partitions.get(features)
        partition_2 = self.partitions.collapse(features, remove_feature)
        rank1 = len(partition_1)
        rank2 = len(partition_2)
        if rank2 == rank1:
            return True
        return False

    def not_ruled_out_in_general(self, proposal):
        if not self.is_rank_more_than_one(proposal):
            return False
        if has_one(self.dont_go_up_from, proposal.issuperset):
            return False
        return True

    def not_ruled_out_bottom_up(self, current, new_feature):
        if not self.not_ruled_out_in_general(current | {new_feature}):
            return False
        if not self.is_rank_increase(current, new_feature):
            return False
        return True

    def not_ruled_out_top_down(self, current, remove_feature):
        proposal = current - {remove_feature}
        if not self.not_ruled_out_in_general(proposal):
            return False
        if has_one(self.dont_go_down_from, proposal.issubset):
            return False
        if self.is_not_rank_decrease(current, remove_feature):
            return True
        else:
            self.dont_go_down_from.append(proposal)
            return False

    def should_look_up_from(self, current):
        """Check a node to see whether it should be expanded at all.
        It shouldn't if it's a known minimal set.
        """
        if current in self.dont_go_up_from:
            return False
        return True

    def whats_up(self, set_of_features):
        """Expand a feature set by providing a version with each of
        the features in the base set which is not already in the
        feature set.
        """
        result = [set_of_features | {f} for f in self.feature_nums if
                  not f in set_of_features and
                  self.not_ruled_out_bottom_up(set_of_features, f)]
        return result

    def whats_down(self, set_of_features):
        """Elaborate a feature set by providing a version lacking each of
        the features in the set.
        """
        result = [set_of_features - {f} for f in set_of_features
                    if self.not_ruled_out_top_down(set_of_features, f)]
        return result

    def has_down(self, set_of_features):
        """Check to see if there is at least one way of removing a feature
        from the node that isn't ruled out.
        """
        for f in set_of_features:
            if self.not_ruled_out_top_down(set_of_features, f):
                return True
        return False

    def is_minimal_from_top(self, node):
        """Presupposes that node is a spec.
        """
        if self.has_down(node):
            return False
        return True

    def search_bottom_frontier(self):
        self.found_on_bottom_frontier = [f for f in self.bottom_frontier if
                                         self.is_spec(f)]
        if self.found_on_bottom_frontier:
            self.dont_go_up_from += self.found_on_bottom_frontier

    def move_bottom_frontier(self):
        if (self.odd_midpoint and
                self.top_depth == self.bottom_depth + 1 and
                self.top_depth == self.max_frontier_depth) or \
                self.bottom_depth == self.max_frontier_depth:
            self.bottom_frontier = []
        else:
            self.bottom_frontier = expand(self.bottom_frontier,
                                          self.whats_up,
                                          parent_filter=self.should_look_up_from,
                                          child_filter=self.not_ruled_out_bottom_up)
            self.bottom_depth += 1

    def search_top_frontier(self):
        self.found_on_top_frontier = [n for n in self.top_frontier if
                                      self.is_minimal_from_top(n)]

    def move_top_frontier(self):
        if (self.odd_midpoint and
                self.bottom_depth == self.top_depth + 1 and
                self.bottom_depth == self.max_frontier_depth) or \
                self.top_depth == self.max_frontier_depth:
            self.top_frontier = []
        else:
            self.top_frontier = expand(self.top_frontier, self.whats_down,
                                       child_filter=self.not_ruled_out_top_down)
            self.top_depth += 1

    def found(self):
        return self.found_on_top_frontier or self.found_on_bottom_frontier

    def pop_all_found(self):
        if self.found_on_top_frontier:
            return self.found_on_top_frontier.pop()
        if self.found_on_bottom_frontier:
            return self.found_on_bottom_frontier.pop()

    def next(self):
        """Return the next minimal subset found, expanding
        the frontiers to find more if necessary.
        """
        if self.no_specs:
            raise StopIteration()
        if not self.found():
            self.move_top_frontier()
            self.move_bottom_frontier()
            while self.top_frontier or self.bottom_frontier:
                self.search_top_frontier()
                self.search_bottom_frontier()
                if self.found():
                    break
                else:
                    self.move_top_frontier()
                    self.move_bottom_frontier()
            if not self.found():
                raise StopIteration()
        return self.pop_all_found()


class MinimalSubsetsFromBottomWithCost(MinimalSubsetsFromBottom):
    def __init__(self, inventory, max_move_cost, seed=None):
        super(MinimalSubsetsFromBottomWithCost, self).__init__(inventory)
        self.move_cost_per_node = self.inventory_table.shape[0]
        self.seed = seed
        self.max_move_cost = max_move_cost
        self.max_bottom_frontier_size = max_move_cost / self.move_cost_per_node
        if max_move_cost < self.move_cost_per_node:
            raise ValueError()
        self.skipped = []
        self.dont_go_down_from = []

    def skipped_below(self, s):
        return has_one(self.skipped, s.issuperset)

    def is_not_rank_decrease(self, features, remove_feature):
        """Check whether removing remove_feature would NOT be a
        rank decrease with respect to features, i.e., whether the rank of the
        inventory table with respect to features stays the same when
        remove_feature is removed.
        """
        partition_1 = self.partitions.get(features)
        partition_2 = self.partitions.collapse(features, remove_feature)
        rank1 = len(partition_1)
        rank2 = len(partition_2)
        if rank2 == rank1:
            return True
        return False

    def not_ruled_out_in_general(self, proposal):
        if not self.is_rank_more_than_one(proposal):
            return False
        if has_one(self.dont_go_up_from, proposal.issuperset):
            return False
        return True
          
    def not_ruled_out_top_down_dodgy(self, current, proposal):
        if not self.skipped_below(proposal):
            return False
        if not self.not_ruled_out_in_general(proposal):
            return False
        if has_one(self.dont_go_down_from, proposal.issubset):
            return False
        if self.is_not_rank_decrease(current, proposal):
            return True
        else:
            self.dont_go_down_from.append(proposal)
            return False
 
    def whats_down_dodgy(self, set_of_features):
        result_l = []
        for removed_feature in set_of_features:
            elaboration = set_of_features - {removed_feature}
            if self.not_ruled_out_top_down_dodgy(set_of_features, elaboration):
                result_l.append(elaboration)
        return result_l
    
    def move_dodgy_top_frontier(self):
        self.dodgy_top_frontier = expand(self.dodgy_top_frontier,
                                         self.whats_down_dodgy)
        
    def has_dodgy_down(self, set_of_features):
        """Check to see if there is at least one way of removing a feature
        from the node that isn't ruled out.
        """
        for removed_feature in set_of_features:
            elaboration = set_of_features - {removed_feature}
            if self.not_ruled_out_top_down_dodgy(set_of_features, elaboration):
                return True
        return False

    def is_minimal_from_top_dodgy(self, node):
        """Presupposes that node is a spec and has a subset in the skipped
        nodes (is dodgy).
        """
        if self.has_dodgy_down(node):
            return False
        return True

    def search_dodgy_top_frontier(self):
        self.found_on_dodgy_top_frontier = [n for n in self.dodgy_top_frontier if
                                            self.is_minimal_from_top_dodgy(n)]    

    def descent_through_dodgy(self):
        truly_minimal = []
        still_dodgy = []
        for c in self.dodgy_top_frontier:
            if self.is_minimal_from_top_dodgy(c):
                truly_minimal.append(c)
            else:
                still_dodgy.append(c)
        self.dodgy_top_frontier = still_dodgy
        while self.dodgy_top_frontier:
            self.search_dodgy_top_frontier()
            truly_minimal += self.found_on_dodgy_top_frontier
            self.move_dodgy_top_frontier()
        return truly_minimal

        
    def search_bottom_frontier(self):
        candidates = [f for f in self.bottom_frontier if self.is_spec(f)]
        if self.skipped:
            print "checking skipped..."
            self.dodgy_top_frontier = []
            self.found_on_bottom_frontier = []
            for c in candidates:
                if self.skipped_below(c):
                    self.dodgy_top_frontier.append(c)
                else:
                    self.found_on_bottom_frontier.append(c)
            if self.dodgy_top_frontier:
                print "found something dodgy; cleaning..."
                self.found_on_bottom_frontier += self.descent_through_dodgy()
                print ".. ok, clean"
            else:
                print ".. ok, no problem"
        else:
            self.found_on_bottom_frontier = candidates
        if self.found_on_bottom_frontier:
            self.dont_go_up_from += self.found_on_bottom_frontier    
        

    def move_bottom_frontier(self):
        if len(self.bottom_frontier) <= self.max_bottom_frontier_size:
            self.bottom_frontier = expand(self.bottom_frontier, self.whats_up,
                                          parent_filter=self.should_look_up_from)
        else:
            random.seed(self.seed)
            random.shuffle(self.bottom_frontier)
            sub_frontier_ii = []
            start_looking_at = 0
            still_need = self.max_bottom_frontier_size - len(sub_frontier_ii)
            stop_looking_at = start_looking_at + still_need
            while len(sub_frontier_ii) < self.max_bottom_frontier_size and \
                  start_looking_at < len(self.bottom_frontier):
                indices_to_check = range(start_looking_at, stop_looking_at)
                to_add_ii = [i for i in indices_to_check if
                             self.should_look_up_from(self.bottom_frontier[i])]
                sub_frontier_ii += to_add_ii
                still_need = self.max_bottom_frontier_size - \
                             len(sub_frontier_ii)
                start_looking_at = stop_looking_at
                stop_looking_at = min(start_looking_at + still_need,
                                      len(self.bottom_frontier))
            sub_frontier = [self.bottom_frontier[i] for i in sub_frontier_ii]
            if stop_looking_at < len(self.bottom_frontier):
                self.skipped += [c for c in
                                 self.bottom_frontier[stop_looking_at:] if
                                 not self.skipped_below(c)]
            self.bottom_frontier = expand(sub_frontier, self.whats_up)

    def next(self):
        """Return the next minimal subset found, expanding
        the frontier to find more if necessary.
        """
        if not self.found_on_bottom_frontier:
            self.move_bottom_frontier()
            while self.bottom_frontier:
                self.search_bottom_frontier()
                if self.found_on_bottom_frontier:
                    break
                else:
                    self.move_bottom_frontier()
            if not self.found_on_bottom_frontier:
                raise StopIteration()
        return self.found_on_bottom_frontier.pop()



def output_filename(inventory):
    return inventory["Language_Name"] + ".csv"


def search_and_write(inventory, output_nf, feature_names, max_search_cost):
    with open(output_nf, "w") as hf:
        col_names = ["language", "num_features"] + feature_names
        hf.write(','.join(col_names) + '\n')
        hf.flush()
        for feature_set in MinimalSubsetsFromBottomWithCost(inventory,
                                                            max_search_cost):
            prefix = [inventory["Language_Name"], str(len(feature_set))]
            feature_spec = ["T" if index in feature_set else "F"
                            for index in range(len(feature_names))]
            hf.write(','.join(prefix + feature_spec) + '\n')
        hf.write('\n')


def write_minimal_parallel(inventories, features, out_dir, n_jobs,
                           max_search_cost):
    if not os.path.isdir(out_dir):
        os.makedirs(out_dir)
    output_nfs = [os.path.join(out_dir, output_filename(inv)) for
                  inv in inventories]
    Parallel(n_jobs=n_jobs)(delayed(search_and_write)(inventories[i],
                                                      output_nfs[i], features,
                                                      max_search_cost)
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
    parser.add_argument('--max-frontier-expansion-cost', type=float,
                        default=float("inf"))
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

    if args.max_frontier_expansion_cost < float("inf"):
        args.max_frontier_expansion_cost = int(args.max_frontier_expansion_cost)
    write_minimal_parallel(inventories, features, args.output_dir,
                           args.jobs, args.max_frontier_expansion_cost)

'''
Created on 2015-05-30

@author: emd
'''
from lattice import expand
from partition import PartitionCached

class FeatureLattice(object):
    '''
    Walk through a lattice of features constructed like this:
    there are some sets of features (feature_sets), each of which
    has its own set of subsets. The iterator walks over all
    the combinations of one of these subsets with one single
    feature that could be added to one of them to make a new subset.
    
    More precisely, each item returned is a pair, extended to
    a triplet to add two extra pieces of useful information:
    
    (SUBSET, FEATURE, SOURCES, DEPTH)
    
    SUBSET: a set of features
    FEATURE: a feature that could be added
    SOURCES: the members of feature_sets that are supersets of
             SUBSET|{FEATURE}
    DEPTH: number of features in SUBSET
    
    Also keeps a cache of the row partitions corresponding to each
    returned subset. Every subset of features, which is a subset
    of the columns of an inventory table, gives us a division
    (partition) of the segments, which are the rows, into sets that do not
    differ on any of the features in the subset.
    
    If you look at a contrastive hierarchy,
    and you look at a particular depth in this tree, you will be
    in fact looking at a particular subset of features. Each node
    at that depth in the tree corresponds to a different element of
    the partition.

    The functionality provided by this class is no longer really used
    (as of writing, January 2 2016). This class is for computing all the
    tree balance statistics and is the backend to BalanceIterator
    (quod vide). In the current analysis, only the "top-level balance"
    is used.
    '''
    def __init__(self, feature_sets, inventory_table, max_depth=None):
        self.depth = 0
        self.max_depth = max_depth
        self.feature_sets = feature_sets
        self.frontier = [(set(), None, range(len(feature_sets)))]
        self.inventory_table = inventory_table
        self.cached_partitions = PartitionCached(self.inventory_table)
        self.move_frontier()

    def __iter__(self):
        return self

    def get_partition(self, cols):
        if not cols:
            return [range(self.inventory_table.shape[0])]
        else:
            return self.cached_partitions.get(cols)
    
    def add_features(self, sfs):
        '''
        Take an SFS (subset, feature, sources) triplet and return all
        possible expansions (new SFS triplets) permitted by self.feature_sets
        '''
        subset, feature, sources = sfs
        if feature is not None:
            self.cached_partitions.split(subset, feature)
        to_add = set()
        to_add_sources = {}
        for s in sources:
            to_add_s = [f for f in self.feature_sets[s] if f not in subset
                        and f != feature]
            for f in to_add_s:
                if f not in to_add_sources:
                    to_add_sources[f] = []
                to_add_sources[f].append(s)
            to_add |= set(to_add_s)
        if feature is not None:
            result = [(subset | {feature}, f, to_add_sources[f])
                      for f in to_add]
        else:
            result = [(subset, f, to_add_sources[f]) for f in to_add]
        return result
    
    def move_frontier(self):
        self.frontier = expand(self.frontier, self.add_features)
        self.to_do = self.frontier[:]
        self.depth += 1        
        
    def next(self):
        try:
            value = self.to_do.pop()
        except:
            if self.max_depth and self.depth == self.max_depth:
                raise StopIteration()
            try:
                self.move_frontier()
                value = self.to_do.pop()
            except:
                raise StopIteration()
        return value + (self.depth,)
        
        

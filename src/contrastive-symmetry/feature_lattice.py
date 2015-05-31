'''
Created on 2015-05-30

@author: emd
'''
from lattice import expand
from partition import PartitionCached

   

class FeatureLattice(object):
    
    def __init__(self, feature_sets, inventory_table):
        self.depth = 0
        self.feature_sets = feature_sets
        self.frontier = [(set(), None, range(len(feature_sets)))]
        self.inventory_table = inventory_table
        self.partitions = PartitionCached(self.inventory_table)
        self.move_frontier()

    def __iter__(self):
        return self

    def get_partition(self, cols):
        if not cols:
            return [range(self.inventory_table.shape[0])]
        else:
            return self.partitions.get(cols)
    
    def add_features(self, set_feature_source_sets):
        set_, feature, source_sets = set_feature_source_sets
        if feature:
            self.partitions.split(set_, feature)
        to_add = set()
        to_add_sources = {}
        for s in source_sets:
            to_add_s = [f for f in self.feature_sets[s] if f not in set_
                        and f != feature]
            for f in to_add_s:
                if f not in to_add_sources:
                    to_add_sources[f] = []
                to_add_sources[f].append(s)
            to_add |= set(to_add_s)
        if feature is not None:
            result = [(set_ | {feature}, f, to_add_sources[f])
                      for f in to_add]
        else:
            result = [(set_, f, to_add_sources[f]) for f in to_add]
        return result
    
    def move_frontier(self):
        self.frontier = expand(self.frontier, self.add_features)
        self.to_do = self.frontier[:]
        self.depth += 1        
        
    def next(self):
        try:
            value = self.to_do.pop()
        except:
            try:
                self.move_frontier()
                value = self.to_do.pop()
            except:
                raise StopIteration()
        return value[0], value[1], self.depth
        
        

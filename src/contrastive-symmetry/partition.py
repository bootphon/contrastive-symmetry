'''
Created on 2015-05-29

@author: emd
'''

import numpy as np
from util import search_npvec, get_all, get_cols_except,\
    collapse_those_containing

def to_row_partition(table):
    """Partition the rows of table. Return a list where each element
    is an index into the rows of table. The indices partition the rows
    of table. Within each element, all indexed rows are equal.
    If the table is empty (has no columns) return an empty list.
    """
    if len(table.shape) == 1 or table.shape[1] == 1:
        if len(table.shape) == 1:
            vec = table
        else:
            vec = table[:,0]
        values = np.unique(vec)
        partition = [np.where(vec == v)[0].tolist() for v in values]
        result = [s for s in partition if s]
    elif table.shape[1] == 0:
        result = []
    else:
        result = []
        rows = []
        for i in range(table.shape[0]):
            try:
                row_i = table[i,:]
                j_existing = search_npvec(row_i, rows)
                result[j_existing].append(i)
            except ValueError:
                result.append([i])
                rows.append(row_i)
    return result
    

class PartitionCached(object):
    def __init__(self, table):
        self.table = table
        self.cache = {}
        
    def has(self, t):
        return t in self.cache
    
    def get(self, cols):
        """Get a partition from the cache or create it and cache it.
        
            Args:
            cols: a set of column indices
        """
        t = tuple(cols)
        if not self.has(t):
            spec = self.table[:, t]
            self.cache[t] = to_row_partition(spec)
        return self.cache[t]

    def split(self, cols, split_on):
        """Create a partition (or get it from the cache) it by expanding
        an existing partition by splitting on a column.
        
        Args:
        cols: a set of column indices
        split_on: a column index
        """
        existing = self.get(cols)
        if len(existing) == 0:
            return self.get((split_on,))
        if split_on in cols:
            return self.get(cols)
        t = tuple(cols.union({split_on}))
        if not self.has(t):
            vec = self.table[:,split_on]
            new_partition = []
            for row_set in existing:
                subpartition_r = to_row_partition(vec[row_set])
                subpartition = [get_all(row_set, sr) for sr in subpartition_r]
                new_partition += subpartition
            self.cache[t] = new_partition
        return self.cache[t]

    def collapse(self, cols, collapse_on):
        """Get a partition from the cache or create it by collapsing
        an existing partition and cache it. Subset must differ from
        partition by a single max ternary feature.
        """
        existing = self.get(cols)
        if len(existing) == 0:
            return existing
        if collapse_on not in cols:
            return existing
        t = tuple(cols - {collapse_on})
        if not self.has(t):
            new_partition = existing[:]
            vec = self.table[:,collapse_on]
            values = np.unique(vec)
            if not len(values) <= 3:
                raise ValueError()
            if len(values) > 1:
                f_partition = [np.where(vec == v)[0].tolist() for v
                               in values]
                residue_cols = get_cols_except(self.table, cols,
                                               collapse_on)
                for i in f_partition[0]:
                    for j in f_partition[1]:
                        if np.any(residue_cols[i, :] != residue_cols[j,:]):
                            continue
                        collapse_those_containing(new_partition, i, j)
                if len(values) == 3:
                    for i in f_partition[0]:
                        for k in f_partition[2]:
                            if np.any(residue_cols[i, :] != residue_cols[k,:]):
                                continue
                            collapse_those_containing(new_partition, i, k)
                    for j in f_partition[1]:
                        for k in f_partition[2]:
                            if np.any(residue_cols[j, :] != residue_cols[k,:]):
                                continue
                            collapse_those_containing(new_partition, j, k)
            self.cache[t] = new_partition
        return self.cache[t]




'''
Created on 2015-05-18

@author: emd
'''

import numpy as np

class Partial1(object):
    def __init__(self, f, arg1):
        self.f = f
        self.arg1 = arg1
        
    def f1(self, x):
        return self.f(self.arg1, x)

def has_one(container, logical_fn):
    """Returns True iff container has at least one element x
    for which logical_fn(x) is True
    """
    for element in container:
        if logical_fn(element):
            return True
    return False

def get_which(container, logical_values, negate=False):
    """Returns a list containing all elements of container for which
    the corresponding element of logical_values is True, or, 
    if negate is set, False.
    """
    if not negate:
        result = [container[i] for i in range(len(container))
                               if logical_values[i]]
    else:
        result = [container[i] for i in range(len(container))
                               if not logical_values[i]]
    return result

def get_all(l, indices):
    """Returns a list containing all indexed elements of the list l
    """
    result = [0]*len(indices)
    for i_new, i_orig in enumerate(indices):
        result[i_new] = l[i_orig]
    return result

def search_npvec(target, l):
    """Returns the index of the first element of list matching a given
    vector target.
    """
    for i, e in enumerate(l):
        if np.all(e == target):
            return i
    raise ValueError()

def get_cols_except(matrix, cols, no_go_col):
    cols_to_get = tuple([c for c in cols if c != no_go_col])
    return matrix[:,cols_to_get]

def which_contains(list_of_lists, elem):
    for i, l in enumerate(list_of_lists):
        if elem in l:
            return i
    raise ValueError()

def collapse_those_containing(collection_of_collections, i, j):       
    group_i = which_contains(collection_of_collections, i)
    group_j = which_contains(collection_of_collections, j)
    collection_of_collections[group_i] = collection_of_collections[group_i] + \
                                         collection_of_collections[group_j]
    del collection_of_collections[group_j]

        
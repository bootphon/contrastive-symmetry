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

def binary_counts(vec):
    '''
    vec is assumed to be binary and contain either -1/1,
    0/1, or 0/-1. If the values are -1/1, the first returned element
    is the number of -1's, and the second element is the number of 1's.
    If there is a 0, the first returned element is always the number
    of 0's. (This is true even if the other value is -1, in which
    case, downstream, BalanceIterator will put the number of 0's as
    the "minus count" and the number of -1's as the "plus count",
    which is why the variables in this function have the names
    that they do.)
    '''
    values = np.unique(vec)
    if len(values) > 2:
        raise ValueError()
    if len(values) == 2 and values[0] == 0:
        minus_val = 0
    else:
        minus_val = -1
    is_minus = vec == minus_val
    return sum(is_minus), sum(~is_minus)
        
def spec_id(feature_set, feature_names):
    feat_name_strings = [feature_names[c] for c in feature_set]
    return "'" + ":".join(feat_name_strings) + "'"


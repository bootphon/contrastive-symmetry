'''
Created on 2015-05-18

@author: emd
'''

import numpy as np


def has_one(container, logical_fn):
    """Returns True iff container has at least one element x
    for which logical_fn(x) is True
    """
    for element in container:
        if logical_fn(element):
            return True
    return False


def get_which(container, logical_fn):
    """Returns a list containing all elements x of container for which 
    logical_fn(x) is True
    """
    return [element for element in container if logical_fn(element)]


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

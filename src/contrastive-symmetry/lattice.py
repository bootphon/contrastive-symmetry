'''
Created on 2015-05-18

@author: emd
'''
from util import get_which

def expand(frontier, node_to_expansions, is_expandable, is_good_expansion):
    new_frontier = []
    for element in frontier:
        if is_expandable(element):
            expanse = get_which(node_to_expansions(element),
                              lambda p: is_good_expansion(element, p))
            to_add = [e for e in expanse if e not in new_frontier]
            new_frontier += to_add
    return new_frontier
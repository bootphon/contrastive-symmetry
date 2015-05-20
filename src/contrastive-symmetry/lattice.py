'''
Created on 2015-05-18

@author: emd
'''

from util import Partial1


def expand_without_collapsing(frontier, node_to_expansions, is_expandable,
                              is_good_expansion=None):
    result = []
    for element in frontier:
        if is_expandable(element):
            expansion = node_to_expansions(element, is_good_expansion)
        else:
            expansion = []
        result.append(expansion)
    return result


def collapse_expansions(frontier, expansions, is_good_expansion=None):
    new_frontier = []
    for i, element in enumerate(frontier):
        if is_good_expansion:
            checker = Partial1(is_good_expansion, element)
        vast_expanse = expansions[i]
        expanse = [e for e in vast_expanse if e not in new_frontier]
        if is_good_expansion:
            to_add = [e for e in expanse if checker.f1(e)]
        else:
            to_add = expanse
        new_frontier += to_add
    return new_frontier


def expand(frontier, node_to_expansions, is_expandable,
           is_good_expansion_pre_collapse=None,
           is_good_expansion_post_collapse=None):
    expansions = expand_without_collapsing(frontier, node_to_expansions,
                                           is_expandable,
                                           is_good_expansion_pre_collapse)
    return collapse_expansions(frontier, expansions,
                               is_good_expansion_post_collapse)

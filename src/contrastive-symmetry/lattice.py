'''
Created on 2015-05-18

@author: emd
'''

from util import Partial1


def expand_without_collapsing(parents, parent_to_children, parent_filter=None):
    result = []
    for p in parents:
        if not parent_filter or parent_filter(p):
            children = parent_to_children(p)
        else:
            children = []
        result.append(children)
    return result


def collapse_children(parents, children_by_parent, child_filter=None):
    result = []
    for i, p in enumerate(parents):
        if child_filter:
            checker = Partial1(child_filter, p)
        new_children = [e for e in children_by_parent[i] if e not in result]
        if child_filter:
            to_add = [e for e in new_children if checker.f1(e)]
        else:
            to_add = new_children
        result += to_add
    return result


def expand(parents, parent_to_children, parent_filter=None,
           child_filter=None):
    children_by_parent = expand_without_collapsing(parents, parent_to_children,
                                                   parent_filter)
    return collapse_children(parents, children_by_parent,
                             child_filter)
    
class LatticeIterator(object):
    def __init__(self, fn_expand_item_up):
        self.fn_expand_item_up = fn_expand_item_up
        return

    def __iter__(self):
        return self
    
    def all_finished(self):
        return False
    
    def before_fill(self):
        return
  
    def after_fill(self):
        return
     
    def fill(self):
        self.before_fill()
        self.frontier = expand(self.frontier, self.fn_expand_item_up)
        self.queue = self.frontier[:]
        self.after_fill()
    
    def next(self):
        try:
            result = self.queue.pop()
        except:
            if self.all_finished(): 
                raise StopIteration()
            try:
                self.fill()
                result = self.queue.pop()
            except:
                raise StopIteration()
        return result
        
        
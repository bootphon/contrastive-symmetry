'''
Created on 2015-11-24

@author: emd
'''
from __future__ import print_function
import argparse
import numpy as np
import sys
from pair_counts import minimal_count
from util import binary_counts
import itertools
from balance import balance

__version__ = '0.0.1'

def balance_dim(v):
    c0, c1 = binary_counts(v)
    if c0 == 0 or c1 == 0:
        assert False
    return balance(c0, c1)

class InventoryGenerator(object):
    def __init__(self, maxfeat):
        self.nfeat = 1
        self.maxfeat = maxfeat
        self.m = np.zeros([2**maxfeat,maxfeat])
        self.m[1,0] = 1
        self.free_rows = [1]
        self.size = 2
        self.subset_gen = itertools.combinations(self.free_rows, self.size-1)
        self.rows = [0] + list(self.subset_gen.next())
        self.cols = [0]
        self.max_size_for_nfeat = 2
        self.first_row_proper_nfeat = 0
        self.first_row_after_nfeat = 2
        self.very_end = False
        self.update_stats()


    def __iter__(self):
        return self
    
    def update_stats(self):
        if self.very_end:
            return
        curr = self.m[self.rows,:]
        pairs = [minimal_count(curr, self.cols, c) for c in self.cols]
        ssegs = [balance_dim(curr[:,c]) for c in self.cols]
        self.inv = {'mn_p': min(pairs), 'mx_p': max(pairs),
                    'mn_s': min(ssegs), 'mx_s': max(ssegs),
                    'tp': sum(pairs), 'ts': sum(ssegs),
                    'size': self.size, 'nfeat': self.nfeat}
    
    def advance_inv(self):
        satisfactory = False
        while not satisfactory:
            self.rows = [0] + list(self.subset_gen.next())
            if max(self.rows) < self.first_row_proper_nfeat:
                continue
            proposal = self.m[np.array([self.rows]).T,self.cols]
            satisfactory = True
            for c in self.cols:
                if minimal_count(proposal, self.cols, c) == 0:
                    satisfactory = False
                    break

    def advance_nfeat(self):
        if self.nfeat == self.maxfeat:
            self.very_end = True
        else:
            self.nfeat += 1
            self.first_row_proper_nfeat = self.first_row_after_nfeat
            self.first_row_after_nfeat = 2**self.nfeat
            old_rows = range(self.first_row_proper_nfeat)
            new_rows = range(self.first_row_proper_nfeat,
                             self.first_row_after_nfeat)
            old_cols = self.cols[:]
            self.cols.append(self.nfeat - 1)
            self.m[np.array([new_rows]).T,old_cols] = \
                self.m[np.array([old_rows]).T,old_cols]
            self.m[new_rows,self.nfeat - 1] = 1
            self.free_rows = (old_rows + new_rows)[1:]
            self.size = self.nfeat + 1
            self.subset_gen = itertools.combinations(self.free_rows,
                                                     self.size-1)
            self.advance_inv()
            self.max_size_for_nfeat = 2**self.nfeat

    def next(self):
        if self.very_end:
            raise StopIteration()
        result = self.inv.copy()
        try:
            self.advance_inv()
        except StopIteration:
            if self.size < self.max_size_for_nfeat:
                self.size += 1
                self.subset_gen = itertools.combinations(self.free_rows,
                                                        self.size-1)
                self.advance_inv()
            else:
                self.advance_nfeat()
        self.update_stats()
        return result
            

def init_stats():
    global min_min_pairs, max_max_pairs, min_min_ssegs, max_max_ssegs,\
           min_sum_pairs, max_sum_pairs, min_sum_ssegs, max_sum_ssegs
    min_min_pairs = float("inf")
    max_max_pairs = 0
    min_min_ssegs = float("inf")
    max_max_ssegs = 0
    min_sum_pairs = float("inf")
    max_sum_pairs = 0
    min_sum_ssegs = float("inf")
    max_sum_ssegs = 0

def changed_config(inv):
    global size, nfeat
    return inv['size'] != size or inv['nfeat'] != nfeat

def update_config(inv):
    global size, nfeat
    size = inv['size']
    nfeat = inv['nfeat']
    init_stats()

def update_stats(inv):
    global min_min_pairs, max_max_pairs, min_min_ssegs, max_max_ssegs,\
           min_sum_pairs, max_sum_pairs, min_sum_ssegs, max_sum_ssegs
    if inv['mn_p'] < min_min_pairs:
        min_min_pairs = inv['mn_p']
    if inv['mx_p'] > max_max_pairs:
        max_max_pairs = inv['mx_p']
    if inv['mn_s'] < min_min_ssegs:
        min_min_ssegs = inv['mn_s']
    if inv['mx_s'] > max_max_ssegs:
        max_max_ssegs = inv['mx_s']
    if inv['tp'] < min_sum_pairs:
        min_sum_pairs = inv['tp']
    if inv['tp'] > max_sum_pairs:
        max_sum_pairs = inv['tp']
    if inv['ts'] < min_sum_ssegs:
        min_sum_ssegs = inv['ts']
    if inv['ts'] > max_sum_ssegs:
        max_sum_ssegs = inv['ts']

def write_stored_stats(hf_out):
    global size, nfeat, min_min_pairs, max_max_pairs, min_min_ssegs, \
           max_max_ssegs, min_sum_pairs, max_sum_pairs, min_sum_ssegs, \
           max_sum_ssegs
    stats = [size,nfeat,min_min_pairs,max_max_pairs,min_min_ssegs,
             max_max_ssegs, min_sum_pairs, max_sum_pairs, min_sum_ssegs,
             max_sum_ssegs]
    print(", ".join([str(s) for s in stats]),
          file=hf_out)
    hf_out.flush()

def write_header(hf_out):
    print('size, nfeat, min_min_pairs, max_max_pairs, min_min_ssegs, '
          'max_max_ssegs, min_sum_pairs, max_sum_pairs, min_sum_ssegs, '
          'max_sum_ssegs',
          file=hf_out)

def parse_args(arguments):
    """Parse command-line options."""
    parser = argparse.ArgumentParser()
    parser.add_argument('--version', action='version',
                        version='%(prog)s ' + __version__)
    parser.add_argument('maxfeat', help='maximum number of features',
                        type=int)
    parser.add_argument('output_file', help='name of output file'
                        '(default: stdout)', nargs='?', default=None)
    args = parser.parse_args(arguments)
    return args
        
if __name__ == "__main__":
    args = parse_args(sys.argv[1:])
    if args.output_file is not None:
        hf_out = open(args.output_file, 'w')
    else:
        hf_out = sys.stdout
    write_header(hf_out)
    generator = InventoryGenerator(args.maxfeat)
    init_stats()
    size = 2
    nfeat = 1
    for inv in generator:
        if changed_config(inv):
            write_stored_stats(hf_out)
            update_config(inv)
        update_stats(inv)
    write_stored_stats(hf_out)
    if args.output_file is not None:
        hf_out.close()

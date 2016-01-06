'''
Created on 2015-11-24

@author: emd
'''
from __future__ import print_function
import argparse
import sys
from pair_counts import minimal_count
from util import binary_counts
from balance import balance
from geometry import scaffolding_size, all_scaffolds, seg_to_int, int_to_seg,\
    copy_add_all, copy_replace, contains_same_geometry,\
    contains_same_geometry_test_isospectral, contains_same_spectrum
import random
import numpy as np

__version__ = '0.0.1'

def balance_dim(v):
    c0, c1 = binary_counts(v)
    if c0 == 0 or c1 == 0:
        assert False
    return balance(c0, c1)

def range_except(exclude, range_limit):
    result = range(range_limit)  # FIXME: Could make this global, but range() is fast
    exclude_sorted = sorted(set(exclude))
    n_removed = 0
    for e in exclude_sorted:
        index = e - n_removed
        del result[index]
        n_removed += 1
    return result

'''
Precondition: n <= 2^k - len(exclude)
'''
def sample_segments_except(exclude, n, k, column_powers):
    possible_values = range_except(seg_to_int(exclude, column_powers),
                                   2**k)
    sample = random.sample(possible_values, n)
    return int_to_seg(sample, column_powers=column_powers)

'''
Precondition: size <= 2^inv.k
'''
def init_random(inv, size, column_powers):
    n_needed = size - inv.n
    new_segments = sample_segments_except(inv.segments, n_needed, inv.k,
                                          column_powers)
    return copy_add_all(inv, new_segments)

'''
Preconditions: inv.n <= 2^inv.k - 1,
               1 <= inv.n - num_fixed
'''
def step_random(inv, num_fixed, column_powers):
    new_segment = sample_segments_except(inv.segments, 1, inv.k,
                                         column_powers)
    new_segment_location = random.sample(range(num_fixed, inv.n), 1)[0]
    return copy_replace(inv, new_segment_location, new_segment)

class GeometryGenerator(object):
    def __init__(self, nseg, nfeat, max_tries, max_samples,
                 test_isospectral=False, real_test="always",
                 scaffold_limit=None):
        if nseg < scaffolding_size(nfeat):
            self.scaffolding = []
        else:
            self.scaffolding = all_scaffolds(nfeat, scaffold_limit)
        self.generated_inventories = []
        self.nseg = nseg
        self.nfeat = nfeat
        self.max_tries = max_tries
        self.max_samples = max_samples
        self.done = False
        self.scaffolding_samples = [0]*len(self.scaffolding)
        self.scaffolding_i_still_ok = range(len(self.scaffolding))
        self.column_powers = 2**np.array(range(nfeat-1,-1,-1), dtype=int)
        self.test_isospectral = test_isospectral
        self.current_isospectral = []
        if real_test == "never":
            self.spectral_test = True
            self.real_test_when_stuck = False
        elif real_test == "when_stuck":
            self.spectral_test = True
            self.real_test_when_stuck = True
        else:
            self.spectral_test = False
            self.real_test_when_stuck = False
        
    def __iter__(self):
        return self

    def test_same(self, inv):
        if self.test_isospectral:
            result, self.current_isospectral = \
                contains_same_geometry_test_isospectral(
                                    self.generated_inventories, inv)
        elif self.spectral_test:
            result = contains_same_spectrum(self.generated_inventories, inv)
        else:
            result = contains_same_geometry(self.generated_inventories, inv)
        return result
    
    def next(self):
        if self.done:
            raise StopIteration()
        if len(self.scaffolding_i_still_ok) == 0:
            raise StopIteration()
        if self.nseg > 2**self.nfeat:
            raise StopIteration()
        if scaffolding_size(self.nfeat) > self.nseg:
            raise StopIteration()
        if self.nseg == 2**self.nfeat:
            inv = init_random(self.scaffolding[0], self.nseg,
                              self.column_powers)
            self.done = True
            return inv
        fails = 0
        if self.real_test_when_stuck:
            self.spectral_test = True
        while True:
            sc_i = random.sample(self.scaffolding_i_still_ok, 1)[0]
            sc = self.scaffolding[sc_i]
            if self.nseg == scaffolding_size(self.nfeat):
                self.scaffolding_i_still_ok.remove(sc_i)
                return sc
            inv = init_random(sc, self.nseg, self.column_powers)
            if self.test_same(inv):
                inv = step_random(inv, scaffolding_size(self.nfeat),
                                  self.column_powers)
                if self.test_same(inv):
                    if self.real_test_when_stuck:
                        self.spectral_test = False
                    fails += 1
                    if fails >= self.max_tries:
                        raise StopIteration()
                    continue
            self.generated_inventories.append(inv)
            self.scaffolding_samples[sc_i] += 1
            if self.scaffolding_samples[sc_i] > self.max_samples:
                self.scaffolding_i_still_ok.remove(sc_i)
            return inv
    
def write_stats(fn, inv, print_shape):
    cols = range(inv.k)
    pairs = [minimal_count(inv.segments, cols, c) for c in cols]
    ssegs = [balance_dim(inv.segments[:,c]) for c in cols]
    if print_shape:
        stats = [inv.n, inv.k, sum(pairs), sum(ssegs),
                 '"' + repr(sorted(pairs)) + '"', 
                 '"' + repr(sorted(ssegs)) + '"', 
                 '"' + repr(inv) + "'"]
    else:
        stats = [inv.n, inv.k, sum(pairs), sum(ssegs),
                 '"' + repr(sorted(pairs)) + '"', 
                 '"' + repr(sorted(ssegs)) + '"']
    print(','.join([str(s) for s in stats]), file=fn)
    fn.flush()

def init_output(fn, print_shape):
    if fn is not None:
        hf = open(fn, 'w')
    else:
        hf = sys.stdout
    if print_shape:
        print('size, nfeat, sum_fnpairs, sum_fbalance, pairs_repr, '
              'ssegs_repr, shape_repr', file=hf)
    else:
        print('size, nfeat, sum_fnpairs, sum_fbalance, pairs_repr, '
              'ssegs_repr', file=hf)
    hf.flush()
    return hf

def parse_args(arguments):
    """Parse command-line options."""
    parser = argparse.ArgumentParser()
    parser.add_argument('--version', action='version',
                        version='%(prog)s ' + __version__)
    parser.add_argument('--print-shape', help='print details of '
                        'inventory shape', action='store_true')
    parser.add_argument('--max-tries', help='maximum number of '
                        'times to try a sampling move before '
                        'giving up (default: 100)', default=100,
                        type=int)
    parser.add_argument('--max-samples',
                        help='maximum number of sample inventories '
                        'to generate per unique (k) scaffolding '
                        '(default: 100)', default=100,
                        type=int)
    parser.add_argument('--scaffold-expansion-limit',
                        help='scaffold expansion limit '
                        '(default: None; FIXME explain)', default=None,
                        type=int)
    parser.add_argument('--use-spectrum-only', help='use only spectral '
                        'test', action='store_true')
    parser.add_argument('--use-spectrum', help='use spectral test unlesss '
                        'stuck', action='store_true')
    parser.add_argument('nseg', help='number of segments', type=int)
    parser.add_argument('nfeat', help='number of features', type=int)
    parser.add_argument('output_file', help='name of output file'
                        '(default: stdout)', nargs='?', default=None)
    args = parser.parse_args(arguments)
    return args
        
if __name__ == "__main__":
    args = parse_args(sys.argv[1:])
    hf_out = init_output(args.output_file, args.print_shape)
    if args.use_spectrum_only:
        generator = GeometryGenerator(args.nseg, args.nfeat,
                                   args.max_tries, args.max_samples,
                                   real_test="never",
                                   scaffold_limit=args.scaffold_expansion_limit)
    elif args.use_spectrum:
        generator = GeometryGenerator(args.nseg, args.nfeat,
                                   args.max_tries, args.max_samples,
                                   real_test="when_stuck",
                                   scaffold_limit=args.scaffold_expansion_limit)
    else:
        generator = GeometryGenerator(args.nseg, args.nfeat,
                                   args.max_tries, args.max_samples,
                                   real_test="always",
                                   scaffold_limit=args.scaffold_expansion_limit)
    for inv in generator:
        write_stats(hf_out, inv, args.print_shape)
    hf_out.close()

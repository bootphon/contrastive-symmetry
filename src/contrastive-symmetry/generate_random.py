import argparse
import os
import sys

from inventory_io import write_inventory, read_inventories
import numpy as np
from stats import size_table, segment_value_table, feature_table
from inventory_util import stem_fn, is_full_rank
from inventory_io import which_binary
from joblib import Parallel, delayed
from joblib.memory import Memory


__version__ = '0.0.1'

MATRIX_SUFFIX = "_random_matrix.csv"
BETABIN_SUFFIX = "_random_betabin.csv"
SEGMENT_SUFFIX = "_random_segment.csv"
FEATURE_SUFFIX = "_random_feature.csv"

def rb(p):
    if np.random.random() <= p:
        return 1
    else:
        return -1


class MatrixIndepRowsSampler(object):
    def __init__(self, feature_probs):
        self.feature_probs = feature_probs
    
    def r(self, i):
        return rb(self.feature_probs[i])

class MatrixBetaBinomSampler(object):
    def __init__(self, param_dict):
        self.feature_alphas = param_dict["alphas"]
        self.ca = [0]*len(self.feature_alphas) 
        self.cb = [0]*len(self.feature_alphas) 
        self.count_weight = param_dict["count_weight"]
    
    def r(self, i):
        alpha = self.feature_alphas[i]
        beta = 1.0
        p = np.random.beta(alpha + self.ca[i], beta + self.cb[i])
        result = rb(p)
        if result == 1:
            self.ca[i] += self.count_weight
        else:
            self.cb[i] += self.count_weight
        return result


def int_to_features(i, nfeat):
    np_rep = np.binary_repr(i, width=nfeat)
    our_rep = [[-1, 1][int(c)] for c in np_rep]
    return our_rep


def features_to_int(binary_repr):
    binary_repr_std = ((binary_repr + 1) / 2)
    result = 0
    for i, digit in enumerate(range(len(binary_repr) - 1, -1, -1)):
        result += pow(2, i) * binary_repr_std[digit]
    return result


def rows_not_attested(m):
    if m.shape[1] == 1:
        values = np.unique(m[:, 0])
        if len(values) == 2:
            return []
        elif len(values) == 0:
            return [1, -1]
        elif values[0] == 1:
            return [-1]
        elif values[0] == -1:
            return [1]
    else:
        pos = m[m[:, 0] == 1, 1:]
        neg = m[m[:, 0] == -1, 1:]
        result = []
        if pos.shape[0] == 0 or len(rows_not_attested(pos)) > 0:
            result += [1]
        if neg.shape[0] == 0 or len(rows_not_attested(neg)) > 0:
            result += [-1]
        return result


def remaining_ways_to_fill_in_zeroes_of_row(matrix, row):
    which_nonzero_row = row != 0
    which_zero_row = ~which_nonzero_row
    nonzero_row = row[which_nonzero_row]
    nonzero_matrix = matrix[:, which_nonzero_row]
    rows_matching_row = np.where((nonzero_matrix == nonzero_row).all(axis=1))
    if len(rows_matching_row[0]) == 0:
        return (-1, 1)
    zero_matrix = matrix[rows_matching_row[0], :][:, which_zero_row]
    return rows_not_attested(zero_matrix)


def sample_feature_generic(size, seed, features, feature_sampler_class,
                           initial_params):
    nfeat = len(features)
    seg_values = np.zeros((size, nfeat), dtype=int)
    seg_names = [''] * size
    feature_sampler = feature_sampler_class(initial_params)
    np.random.seed(seed)
    for i_seg in range(size):
        seg_values[i_seg, 0] = feature_sampler.r(0)
        for i_feat in range(1, nfeat):
            previous = seg_values[0:i_seg, :]
            current = seg_values[i_seg,:]
            val = remaining_ways_to_fill_in_zeroes_of_row(previous, current)
            if len(val) == 2:
                seg_values[i_seg, i_feat] = feature_sampler.r(i_feat)
            elif len(val) == 1:
                seg_values[i_seg, i_feat] = val[0]
            else:
                assert False
        seg_names[i_seg] = 's' + str(features_to_int(seg_values[i_seg, :]))
    np.random.seed()
    return seg_names, seg_values

    


def sample_matrix(size, seed, features):
    nfeat = len(features)
    feature_probs = [1 / 2.] * nfeat
    return sample_feature_generic(size, seed, features, MatrixIndepRowsSampler,
                                  feature_probs)


def sample_matrix_betabin(size, seed, features, count_weight):
    nfeat = len(features)
    feature_alphas = [1.] * nfeat
    return sample_feature_generic(size, seed, features, MatrixBetaBinomSampler,
                                  {"alphas": feature_alphas,
                                   "count_weight": count_weight})


def sample_segments(size, seed, segment_probs, segments, segment_names):
    seg_indices = range(len(segment_probs))
    np.random.seed(seed)
    s = np.random.choice(seg_indices, size, replace=False, p=segment_probs)
    np.random.seed()
    return [segment_names[i] for i in s], [segments[i] for i in s]


def sample_binary_segments(size, seed, segment_probs, segments, segment_names):
    seg_indices = range(len(segment_probs))
    np.random.seed(seed)
    binary = False
    while not binary:
        s = np.random.choice(seg_indices, size, replace=False, p=segment_probs)
        seg_feature_vals = [segments[i] for i in s]
        inv_table = np.array(seg_feature_vals)
        binary_feats = which_binary(inv_table)
        inv_binary_only = inv_table[:,binary_feats]
        if is_full_rank(inv_binary_only):
            binary = True
    np.random.seed()
    return [segment_names[i] for i in s], seg_feature_vals 


def inventory_colnames(features):
    return ['language', 'label'] + features


def templates(size_table, initial_seed):
    sizes = size_table.keys()
    size_freqs = size_table.values()
    result = []
    i_inv_last = 0
    for i_size, size in enumerate(sizes):
        if initial_seed is not None:
            result += [{'Language_Name': 'I' + str(i_inv_last + i + 1),
                        'size': size, 'seed': initial_seed + i_inv_last + i}
                       for i in range(size_freqs[i_size])]
        else:
            result += [{'Language_Name': 'I' + str(i_inv_last + i + 1),
                        'size': size, 'seed': None}
                       for i in range(size_freqs[i_size])]
        i_inv_last += size_freqs[i_size]
    return result


def create_inventory(inventory_info, segment_sample_fn):
    size = inventory_info['size']
    seed = inventory_info['seed']
    inv_seg_names, inv_seg_values = segment_sample_fn(size, seed)
    inventory = {'Language_Name': inventory_info['Language_Name'],
                 'segment_names': inv_seg_names,
                 'segments': inv_seg_values}
    return inventory


def create_inventories(size_table, sample_fn, tmpdir, initial_seed, n_jobs):
    inventory_templates = templates(size_table, initial_seed)
    mem = Memory(cachedir=tmpdir, verbose=False) 
    f = mem.cache(create_inventory)
    result = Parallel(n_jobs=n_jobs)(delayed(f)(i, sample_fn)
                                     for i in inventory_templates)
    mem.clear(warn=False)
    return result


def write_inventories(out_fn, inventories, features):
    out_dir = os.path.dirname(out_fn)
    if not os.path.isdir(out_dir):
        os.makedirs(out_dir)
    hf_out = open(out_fn, 'w')
    hf_out.write(','.join(inventory_colnames(features)) + '\n')
    hf_out.close()
    for i in inventories:
        write_inventory(i, out_fn, append=True)
        
        
        

def create_parser():
    """Return command-line parser."""
    parser = argparse.ArgumentParser()
    parser.add_argument('--version', action='version',
                        version='%(prog)s ' + __version__)
    parser.add_argument('--jobs', type=int, default=1,
                        help='number of parallel jobs; '
                        'match CPU count if value is less than 1')
    parser.add_argument('--initial-seed', type=int, default=None,
                        help='initial random seed for inventories, increased '
                        'by one for each in a predictable but meaningless '
                        'order (default: variable)')
    parser.add_argument('--skipcols', type=int, default=2,
                        help='number of columns to skip before assuming '
                        'the rest is features')
    parser.add_argument('--language-colindex', type=int, default=0,
                        help='index of column containing language name')
    parser.add_argument('--seg-colindex', type=int, default=1,
                        help='index of column containing segment label')
    parser.add_argument('--props-from', default=None,
                        help='a separate csv to get the statistics from')
    parser.add_argument('--betabin-count-weight', type=float, default=1.0,
                        help='factor to weight each additional count by '
                        'in the beta-binomial model')
    parser.add_argument('--matrix', action='store_true')
    parser.add_argument('--betabin', action='store_true')
    parser.add_argument('--feature', action='store_true')
    parser.add_argument('--segment', action='store_true')
    parser.add_argument('--binary-segment', action='store_true')
    parser.add_argument('--tmp_directory', default='/tmp',
                        help='directory to store temporary files')
    parser.add_argument('--outdir', help='output directory', default='.')
    parser.add_argument('inventories_locations', help='list of csv files'
                        'containing independent sets of inventories; '
                        'each set of inventories will be paired with its own'
                        'set of random inventories', nargs='+')
    return parser


def parse_args(arguments):
    """Parse command-line options."""
    parser = create_parser()
    args = parser.parse_args(arguments)
    return args
        

if __name__ == "__main__":
    args = parse_args(sys.argv[1:])

    all_inventory_tuples = [read_inventories(l, args.skipcols,
                                             args.language_colindex,
                                             args.seg_colindex)
                            for l in args.inventories_locations]
    all_sizes = [size_table(ii[0]) for ii in all_inventory_tuples]
    all_output_fn_prefixes = [os.path.join(args.outdir, stem_fn(l))
                              for l in args.inventories_locations]
    if args.props_from:
        props_from = read_inventories(args.props_from, args.skipcols,
                                      args.language_colindex,
                                      args.seg_colindex)

    for i, inventory_tuple in enumerate(all_inventory_tuples):
        inventories = inventory_tuple[0]
        features = inventory_tuple[1]
        sizes = all_sizes[i]
        if args.matrix:
            def sample_fn(size, seed):
                return sample_matrix(size, seed, features)
            out_fn = all_output_fn_prefixes[i] + MATRIX_SUFFIX
            randints = create_inventories(sizes, sample_fn, args.tmp_directory,
                                          args.initial_seed, args.jobs)
            write_inventories(out_fn, randints, features)
        elif args.betabin:
            def sample_fn(size, seed):
                return sample_matrix_betabin(size, seed, features,
                                             args.betabin_count_weight)
            out_fn = all_output_fn_prefixes[i] + BETABIN_SUFFIX
            randints = create_inventories(sizes, sample_fn, args.tmp_directory,
                                          args.initial_seed, args.jobs)
            write_inventories(out_fn, randints, features)
        elif args.binary_segment:
            if props_from:
                segtable = segment_value_table(props_from[0])
                segnames = segtable[0].keys()
                segvals = segtable[0].values()
                segcounts = segtable[1].values()
                segprobs = [c/float(sum(segcounts)) for c in segcounts]
            else:
                all_segtables = [segment_value_table(ii[0])
                             for ii in all_inventory_tuples]
                segnames = all_segtables[i][0].keys()
                segvals = all_segtables[i][0].values()
                segcounts = all_segtables[i][1].values()
                segprobs = [c / float(sum(segcounts)) for c in segcounts]

            def sample_fn(size, seed):
                return sample_binary_segments(size, seed, segprobs, segvals,
                                              segnames)
            out_fn = all_output_fn_prefixes[i] + SEGMENT_SUFFIX
            randints = create_inventories(sizes, sample_fn, args.tmp_directory,
                                          args.initial_seed, args.jobs)
            write_inventories(out_fn, randints, features)
        elif args.segment:
            all_segtables = [segment_value_table(ii[0])
                             for ii in all_inventory_tuples]
            segnames = all_segtables[i][0].keys()
            segvals = all_segtables[i][0].values()
            segcounts = all_segtables[i][1].values()
            segprobs = [c / float(sum(segcounts)) for c in segcounts]

            def sample_fn(size, seed):
                return sample_segments(size, seed, segprobs, segvals, segnames)
            out_fn = all_output_fn_prefixes[i] + SEGMENT_SUFFIX
            randints = create_inventories(sizes, sample_fn, args.tmp_directory,
                                          args.initial_seed, args.jobs)
            write_inventories(out_fn, randints, features)
        elif args.feature:
            all_feattables = [feature_table(ii[0], features)
                              for ii in all_inventory_tuples]
            featprobs = all_feattables[i].values()

            def sample_fn(size, seed):
                return sample_feature_generic(size, seed, features,
                                              MatrixIndepRowsSampler,
                                              featprobs)
            out_fn = all_output_fn_prefixes[i] + FEATURE_SUFFIX
            randints = create_inventories(sizes, sample_fn, args.tmp_directory,
                                          args.initial_seed, args.jobs)
            write_inventories(out_fn, randints, features)

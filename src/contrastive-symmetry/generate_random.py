import numpy as np
import pandas as pd
import sys
import shutil
from tmp_files import create_tmp_directory, tmp_filename
import argparse
from inventory_io import default_feature_value_npf, write_inventory

__version__ = '0.0.1'


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
                        'by one for each in a predictable but meaningless order '
                        '(default: variable)')
    parser.add_argument('--use-existing-tmp', type=bool, default=True,
                        help='if tmp directory exists, use any inventories already '
                        'generated')
    parser.add_argument('sizes_fn',
                        help='file containing a table summarizing inventory '
                        'size counts')
    parser.add_argument('tmp_directory',
                        help='directory to store temporary csv files which '
                        'are merged at the end')
    parser.add_argument('--segfreqs_fn',
                        help='file containing a table summarizing segment '
                        'frequencies in terms of what feature combinations '
                        'show up how often as segments; if unspecified, '
                        'then the distribution is uniform random over nfeats '
                        'features; either this or nfeats or the feature '
                        'frequencies filename must be specified, '
                        'but not any combination (default: not specified)',
                        default=None)
    parser.add_argument('--featprobs_fn',
                        help='file containing a table summarizing feature '
                        'being [+] probabilities in for each feature; '
                        'if unspecified, '
                        'then the distribution is uniform random over [+] '
                        'and [-]; either this or nfeats or the segment '
                        'frequencies filename must be specified, '
                        'but not any combination (default: not specified)',
                        default=None)
    parser.add_argument('--nfeat', type=int,
                        help='number of features; either this or the segment '
                        'frequencies filename or the feature frequencies '
                        'filename must be specified, '
                        'but not any combination (default: not specified)',
                        default=None)
    parser.add_argument('output_file', metavar='output file',
                        help='output file (default: stdout)', nargs='?',
                        default=None)
    return parser


def parse_args(arguments):
    """Parse command-line options."""
    parser = create_parser()
    args = parser.parse_args(arguments)

    if args.jobs < 1:
        # Do not import multiprocessing globally in case it is not supported
        # on the platform.
        import multiprocessing
        args.jobs = multiprocessing.cpu_count()

    num_ways_of_specifying_dist = int(args.nfeat is not None) + \
        int(args.segfreqs_fn is not None) + int(args.featprobs_fn is not None)
    if num_ways_of_specifying_dist != 1:
        raise argparse.ArgumentTypeError('Must specify either number of '
                                         'features or segment distribution '
                                         'or feature distribution (but not '
                                         'any combination)')

    return args


def read_sizes(fn):
    raw_table = pd.read_csv(fn, dtype=np.str)
    sizes = raw_table.ix[:, 0].values.astype(int)
    freqs = raw_table.ix[:, 1].values.astype(int)
    return sizes, freqs


def read_segment_freqs(fn, feature_value_npf=default_feature_value_npf):
    raw_table = pd.read_csv(fn, dtype=np.str)
    ncol = raw_table.shape[1]
    segment_names = raw_table.ix[:, 0].values.astype(str)
    segments_raw = raw_table.ix[:, 1:(ncol - 1)]
    freqs = raw_table.ix[:, ncol - 1].values.astype(int)
    i_segments_raw = segments_raw.iterrows()
    first_segment_raw = i_segments_raw.next()[1]
    features = first_segment_raw.keys().tolist()
    segments = [feature_value_npf(first_segment_raw.values)]
    segments += [feature_value_npf(t[1].values) for t in i_segments_raw]
    return segments, segment_names, features, freqs


def read_feature_probs(fn, feature_value_npf=default_feature_value_npf):
    raw_table = pd.read_csv(fn, dtype=np.str)
    features = raw_table.ix[:, 0].values.astype(str).tolist()
    feature_probs = raw_table.ix[:, 1].values.astype(float)
    nfeat = len(features)
    nsegs = pow(2, nfeat)
    segment_names = ['s' + str(i + 1) for i in range(nsegs)]
    return segment_names, features, feature_probs


def sample_from_segment_dist(size, seed, segment_probs, segments,
                             segment_names):
    seg_indices = range(len(segment_probs))
    np.random.seed(seed)
    s = np.random.choice(seg_indices, size, replace=False, p=segment_probs)
    np.random.seed()
    return segment_names[s], [segments[i] for i in s]


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


def random_feature(p):
    if np.random.random() <= p:
        return 1
    else:
        return -1


def remaining_values(m):
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
        if pos.shape[0] == 0 or len(remaining_values(pos)) > 0:
            result += [1]
        if neg.shape[0] == 0 or len(remaining_values(neg)) > 0:
            result += [-1]
        return result


def possible_values_remaining_first_zero(m, v):
    nonzero_v = v != 0
    zero_v = ~nonzero_v
    v_nonzero_v = v[nonzero_v]
    m_nonzero_v = m[:, nonzero_v]
    rows_matching_v = np.where((m_nonzero_v == v_nonzero_v).all(axis=1))
    if len(rows_matching_v[0]) == 0:
        return (-1, 1)
    m_zero_v = m[rows_matching_v[0],:][:, zero_v]
    return remaining_values(m_zero_v)


def sample_from_feature_probs(size, seed, features, feature_probs):
    nfeat = len(features)
    seg_values = np.zeros((size, nfeat), dtype=int)
    seg_names = [''] * size
    np.random.seed(seed)
    for i_seg in range(size):
        seg_values[i_seg, 0] = random_feature(feature_probs[0])
        for i_feat in range(1, nfeat):
            val = possible_values_remaining_first_zero(
                seg_values[0:i_seg,:], seg_values[i_seg,:])
            if len(val) == 2:
                seg_values[i_seg, i_feat] = random_feature(
                    feature_probs[i_feat])
            elif len(val) == 1:
                seg_values[i_seg, i_feat] = val[0]
            else:
                assert False
        seg_names[i_seg] = 's' + str(features_to_int(seg_values[i_seg,:]))
    np.random.seed()
    return seg_names, seg_values


def sample_from_uniform(size, seed, features):
    nfeat = len(features)
    feature_probs = [1 / 2.] * nfeat
    return sample_from_feature_probs(size, seed, features, feature_probs)


def generate_and_write_inventory(inventory_info, segment_sample_fn,
                                 tmp_directory, use_existing_tmp):
    size = inventory_info['size']
    seed = inventory_info['seed']
    inv_seg_names, inv_seg_values = segment_sample_fn(size, seed)
    inventory = {'Language_Name': inventory_info['Language_Name'],
                 'segment_names': inv_seg_names,
                 'segments': inv_seg_values}
    fn = tmp_filename((inventory['Language_Name'],), 'csv', tmp_directory)
    write_inventory(inventory, fn)


def inventory_colnames(features):
    return ['language', 'label'] + features


if __name__ == "__main__":
    args = parse_args(sys.argv[1:])
    create_tmp_directory(args.tmp_directory, args.use_existing_tmp)
    inv_sizes, inv_freqs = read_sizes(args.sizes_fn)
    if args.segfreqs_fn is not None:
        segments, segment_names, features, segment_freqs = read_segment_freqs(
            args.segfreqs_fn)
        segment_probs = segment_freqs / float(sum(segment_freqs))

        def segment_sample_fn(size, seed):
            return sample_from_segment_dist(size, seed, segment_probs,
                                            segments, segment_names)
    elif args.featprobs_fn is not None:
        segment_names, features, feature_probs = read_feature_probs(
            args.featprobs_fn)

        def segment_sample_fn(size, seed):
            return sample_from_feature_probs(size, seed, features,
                                             feature_probs)
    else:
        features = ['f' + str(i + 1) for i in range(args.nfeat)]

        def segment_sample_fn(size, seed):
            return sample_from_uniform(size, seed, features)

    inventory_infos = []
    seed = args.initial_seed
    i_inv_last = 0
    for i_size, size in enumerate(inv_sizes):
        if args.initial_seed is not None:
            inventory_infos += [{'Language_Name': 'I' + str(i_inv_last + i + 1),
                                 'size': size,
                                 'seed': args.initial_seed + i_inv_last + i}
                                for i in range(inv_freqs[i_size])]
        else:
            inventory_infos += [{'Language_Name': 'I' + str(i_inv_last + i + 1),
                                 'size': size, 'seed': None}
                                for i in range(inv_freqs[i_size])]
        i_inv_last += inv_freqs[i_size]

    if args.jobs == 1:
        for i in inventory_infos:
            generate_and_write_inventory(i, segment_sample_fn,
                                         args.tmp_directory,
                                         args.use_existing_tmp)
    else:
        from multiprocessing import Pool

        def generate_and_write_inventory_part(inventory):
            generate_and_write_inventory(inventory, segment_sample_fn,
                                         args.tmp_directory,
                                         args.use_existing_tmp)
        Pool(args.jobs).map(generate_and_write_inventory_part, inventory_infos)

    if args.output_file is None:
        hf_out = sys.stdout
    else:
        hf_out = open(args.output_file, 'w')
    hf_out.write(','.join(inventory_colnames(features)) + '\n')
    for i in inventory_infos:
        hf_tmp = open(
            tmp_filename((i['Language_Name'],), 'csv', args.tmp_directory), 'r')
        for line in hf_tmp.readlines():
            hf_out.write(line)
        hf_tmp.close()
    hf_out.close()

    shutil.rmtree(args.tmp_directory)

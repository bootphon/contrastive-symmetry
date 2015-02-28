import argparse
import random
import sys
import os

import numpy as np
import sda
from inventory_io import read_inventories
from joblib.memory import Memory
from joblib.parallel import Parallel, delayed
from util import stem_fn

__version__ = '0.0.1'

CSTATS_SUFFIX = "_cstats.csv"


def remove_underspecified(inventory, fill_val):
    cols_with_zeroes = np.any(inventory == 0, axis=0)
    result = inventory.copy()
    result[:, cols_with_zeroes] = fill_val
    return result


def fill_underspecified(inventory, fill_val):
    result = inventory.copy()
    result[inventory == 0] = fill_val
    return result


def contrastive(inventory, feature_permutation):
    perm_in_std = feature_permutation["Index_of_Perm_in_Std"]
    std_in_perm = feature_permutation["Index_of_Std_in_Perm"]
    permuted_inventory = inventory["Feature_Table"][:, perm_in_std]
    try:
        # First try entirely ignoring features which the feature table
        # gives as zero; if they are only specified for some segments (i.e.,
        # if this is actually a partly contrastive specification already)
        # then using these features when the primary contrastive feature
        # on which they depend hasn't been used already will lead to
        # less meaningful results
        permuted_without_arbitrary = remove_underspecified(
            permuted_inventory, -1)
        contrastive_inventory = sda.sda(permuted_without_arbitrary)
    except StandardError:
        # If the inventory can't be specified contrastively in this way,
        # then fall back on using those features, risking that they may
        # be split on prematurely (the correct solution, not implemented
        # here, is to take the first strategy, removal, when the 0 feature
        # scopes above its parent - or simply bar such permutations - and
        # the second strategy, arbitrary filling, when the 0 feature scopes
        # below)
        try:
            permuted_filled = fill_underspecified(permuted_inventory, -1)
            contrastive_inventory = sda.sda(permuted_filled)
        except StandardError:
            return {"Language_Name": inventory["Language_Name"],
                    "Feature_Permutation": feature_permutation}
    contrastive_inventory_std_order = contrastive_inventory[:, std_in_perm]
    contrastive_feature_indices = sda.contrastive_features(
        contrastive_inventory)
    result = {"Feature_Table_Std": contrastive_inventory_std_order,
              "Feature_Table_Perm": contrastive_inventory,
              "Feature_Permutation": feature_permutation,
              "Language_Name": inventory["Language_Name"],
              "Contrastive_Feature_Inds_Perm": contrastive_feature_indices,
              "Contrastive_Feature_Inds_Std":
                  [perm_in_std[i] for i in contrastive_feature_indices]}
    return result


def summary_colnames(features):
    result = ["language", "nseg", "sb", "ncfeat", "order"]
    for feature in features:
        result += ["sb_" + feature, "nseg_" + feature, "cfdepth_" + feature,
                   "cfheight_" + feature, "sb_by_cfheight_" + feature,
                   "balance_" + feature, "balance_by_cfheight_" + feature]
    return result


def summary(inventory, features):
    result = {}
    result["language"] = inventory["Language_Name"]
    result["order"] = inventory["Feature_Permutation"]["Order_Name"]

    if "Feature_Table_Perm" not in inventory:
        return result

    cfeature_inds = inventory["Contrastive_Feature_Inds_Std"]
    feature_table = inventory["Feature_Table_Perm"]

    result["nseg"] = feature_table.shape[0]
    result["sb"] = sda.sum_balance(feature_table)
    result["ncfeat"] = len(cfeature_inds)

    for cfeature_index, feature_index in enumerate(cfeature_inds):
        feature_name = features[feature_index]
        permuted_index = inventory[
            "Contrastive_Feature_Inds_Perm"][cfeature_index]
        sb_subtree = sda.sum_balance(feature_table[:, permuted_index:])
        result["sb_" + feature_name] = sb_subtree
        feature_nsegs = sda.num_segments(feature_table[:, permuted_index:])
        result["nseg_" + feature_name] = feature_nsegs
        result["cfdepth_" + feature_name] = cfeature_index
        cfheight = (len(cfeature_inds) - cfeature_index)
        result["cfheight_" + feature_name] = cfheight
        result["sb_by_cfheight_" + feature_name] = sb_subtree / float(cfheight)
        balance = sda.balance(feature_table[:, permuted_index])
        result["balance_" + feature_name] = balance
        result["balance_by_cfheight_" + feature_name] = balance / \
            float(cfheight)
    return result


def cstats(inventory, permutation, features):
    ci = contrastive(inventory, permutation)
    result = summary(ci, features)
    return result


def generate_permutations(n, seed, features):
    permutations = []
    random.seed(seed)
    nfeats = len(features)
    for i in range(n):
        index_of_perm_in_std = range(nfeats)
        random.shuffle(index_of_perm_in_std)
        index_of_std_in_perm = np.argsort(index_of_perm_in_std)
        permutation = {"Order_Name": "O" + str(i + 1),
                       "Index_of_Perm_in_Std": index_of_perm_in_std,
                       "Index_of_Std_in_Perm": index_of_std_in_perm}
        permutations.append(permutation)
    random.seed()
    return permutations


def write_cstat_summary(cstat_summary, fn, features, append=False):
    if append:
        mode = 'a'
    else:
        mode = 'w'
    colnames_in_order = summary_colnames(features)
    with open(fn, mode) as hf:
        prefix = ''
        for colname in colnames_in_order:
            hf.write(prefix)
            if colname in cstat_summary:
                hf.write(str(cstat_summary[colname]))
            prefix = ','
        hf.write('\n')


def map_cstats(invs_perms, features, tmpdir, n_jobs):
    mem = Memory(cachedir=tmpdir, verbose=False)
    f = mem.cache(cstats)
    result = Parallel(n_jobs=n_jobs)(delayed(f)(i, p, features)
                                     for (i, p) in invs_perms)
    mem.clear(warn=False)
    return result


def write_cstat_summaries(out_fn, summaries, features):
    out_dir = os.path.dirname(out_fn)
    if not os.path.isdir(out_dir):
        os.makedirs(out_dir)
    hf_out = open(out_fn, 'w')
    hf_out.write(','.join(summary_colnames(features)) + '\n')
    hf_out.close()
    for s in summaries:
        write_cstat_summary(s, out_fn, features, append=True)


def create_parser():
    """Return command-line parser."""
    parser = argparse.ArgumentParser()
    parser.add_argument('--version', action='version',
                        version='%(prog)s ' + __version__)
    parser.add_argument('--jobs', type=int, default=1,
                        help='number of parallel jobs; '
                        'match CPU count if value is less than 1')
    parser.add_argument('--skipcols', type=int, default=2,
                        help='number of columns to skip before assuming '
                        'the rest is features')
    parser.add_argument('--language-colindex', type=int, default=0,
                        help='index of column containing language name')
    parser.add_argument('--seg-colindex', type=int, default=1,
                        help='index of column containing segment label')
    parser.add_argument('--nperms', type=int, default=100,
                        help='number of random feature hierarchy permutations')
    parser.add_argument('--permutation-seed', type=int, default=None,
                        help='fixed random seed for permutations (default: '
                        'variable)')
    parser.add_argument('--tmp_directory', default='/tmp',
                        help='directory to store temporary files')
    parser.add_argument('--outdir', help='output directory', default='.')
    parser.add_argument('inventories_locations', help='list of csv files'
                        'containing independent sets of inventories; '
                        'each set of inventories will be paired with its own'
                        'contrastive stats summary file', nargs='+')
    return parser


def parse_args(arguments):
    """Parse command-line options."""
    parser = create_parser()
    args = parser.parse_args(arguments)
    return args


if __name__ == '__main__':
    args = parse_args(sys.argv[1:])

    all_inventory_tuples = [read_inventories(l, args.skipcols,
                                             args.language_colindex,
                                             args.seg_colindex)
                            for l in args.inventories_locations]
    all_output_fn_prefixes = [os.path.join(args.outdir, stem_fn(l))
                              for l in args.inventories_locations]
    for i, inventory_tuple in enumerate(all_inventory_tuples):
        inventories = inventory_tuple[0]
        features = inventory_tuple[1]
        feature_permutations = generate_permutations(args.nperms,
                                                     args.permutation_seed,
                                                     features)
        invs_perms = []
        for inventory in inventories:
            for feature_permutation in feature_permutations:
                invs_perms += [(inventory, feature_permutation)]
        result = map_cstats(invs_perms, features, args.tmp_directory,
                            args.jobs)
        out_fn = all_output_fn_prefixes[i] + CSTATS_SUFFIX
        write_cstat_summaries(out_fn, result, features)

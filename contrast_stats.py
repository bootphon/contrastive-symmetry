import argparse
import random
import sys
import os

import numpy as np
import pandas as pd
import sda

__version__ = '0.0.1'

default_feature_value_dict = {'+': 1, '-': -1, '0': 0}


def default_feature_value_map(x):
    return default_feature_value_dict[x]
default_feature_value_npf = np.frompyfunc(default_feature_value_map, 1, 1)


def read_inventories(fn, skipcols, lgcol_index, segcol_index,
                     feature_value_npf=default_feature_value_npf):
    raw_table = pd.read_csv(fn, dtype=np.str)
    features = raw_table.columns.values[skipcols:]
    segment_name_col = raw_table.ix[:,segcol_index]
    language_name_col = raw_table.ix[:,lgcol_index]
    language_names = pd.unique(language_name_col)
    inventories = []
    for language_name in language_names:
        inventory_rows = language_name_col == language_name
        raw_inventory_table = raw_table.ix[inventory_rows, features]
        feature_table = feature_value_npf(raw_inventory_table).values
        segment_names = segment_name_col[inventory_rows].values
        inventory = {"Feature_Table": feature_table,
                     "Language_Name": language_name,
                     "Segment_Names": segment_names}
        inventories.append(inventory)
    return inventories, features


def remove_underspecified(inventory, fill_val):
    cols_with_zeroes = np.any(inventory == 0, axis=0)
    result = inventory.copy()
    result[:,cols_with_zeroes] = fill_val
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
        permuted_without_arbitrary = remove_underspecified(permuted_inventory, -1)
        contrastive_inventory = sda.sda(permuted_without_arbitrary)
    except StandardError:
        # If the inventory can't be specified contrastively in this way,
        # then fall back on using those features, risking that they may
        # be split on prematurely (the correct solution, not implemented
        # here, is to take the first strategy, removal, when the 0 feature
        # scopes above its parent - or simply bar such permutations - and
        # the second strategy, arbitrary filling, when the 0 feature scopes below)
        try:
            permuted_filled = fill_underspecified(permuted_inventory, -1)
            contrastive_inventory = sda.sda(permuted_filled)
        except StandardError:
            return None
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
    cfeature_inds = inventory["Contrastive_Feature_Inds_Std"]
    feature_table = inventory["Feature_Table_Perm"]

    result = {}
    result["language"] = inventory["Language_Name"]
    result["nseg"] = feature_table.shape[0]
    result["sb"] = sda.sum_balance(feature_table)
    result["ncfeat"] = len(cfeature_inds)
    result["order"] = inventory["Feature_Permutation"]["Order_Name"]

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
        balance = sda.balance(feature_table[:,permuted_index])
        result["balance_" + feature_name] = balance
        result["balance_by_cfheight_" + feature_name] = balance / float(cfheight)
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
    parser.add_argument('--use-existing-tmp', type=bool, default=True,
                        help='if tmp directory exists, use any stats already '
                        'computed')
    parser.add_argument('inventories_location', metavar='inventories location',
                        help='csv containing all inventories')
    parser.add_argument('tmp_directory', metavar='tmp directory',
                        help='directory to store temporary csv files which '
                        'are merged at the end')
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

    return args


def tmp_filename(inventory, feature_permutation, directory):
    basename = inventory["Language_Name"] + '_' + \
                feature_permutation["Order_Name"] + ".stats"
    return os.path.join(directory, basename)


def write_summary(contr, fn, features, summary_colnames_f):
    s = summary(contr, features)
    with open(fn, 'w') as hf:
        prefix = ''
        for colname in summary_colnames_f:
            hf.write(prefix)
            if colname in s:
                hf.write(str(s[colname]))
            prefix = ','


def do_and_write_summary(inventory, feature_permutation, summary_colnames_f,
                         features, tmp_directory, use_existing_tmp):
    fn = tmp_filename(inventory, feature_permutation, args.tmp_directory)
    if use_existing_tmp and os.path.isfile(fn):
        return
    c = contrastive(inventory, feature_permutation)
    write_summary(c, fn, features, summary_colnames_f)


def create_tmp_directory(dirname, use_existing_tmp):
    if use_existing_tmp and os.path.isdir(dirname):
        return
    try:
        os.mkdir(dirname)
    except OSError, e:
        sys.stderr.write("error creating temp directory " + dirname + ": " +
                         str(e))
        exit()

if __name__ == '__main__':
    args = parse_args(sys.argv[1:])

    inventories, features = read_inventories(args.inventories_location,
                                             args.skipcols,
                                             args.language_colindex,
                                             args.seg_colindex)
    summary_colnames_f = summary_colnames(features)
    feature_permutations = generate_permutations(args.nperms,
                                                 args.permutation_seed,
                                                 features)
    create_tmp_directory(args.tmp_directory, args.use_existing_tmp)
    invs_perms = []
    for inventory in inventories:
        for feature_permutation in feature_permutations:
            invs_perms += [(inventory, feature_permutation)]
    if args.jobs == 1:
        for (i, p) in invs_perms:
            do_and_write_summary(i, p, summary_colnames_f, features,
                                 args.tmp_directory, args.use_existing_tmp)
    else:
        from multiprocessing import Pool
        def do_and_write_summary_part((i,p)):
            do_and_write_summary(i, p, summary_colnames_f, features,
                                                args.tmp_directory,
                                                args.use_existing_tmp)
        Pool(args.jobs).map(do_and_write_summary_part, invs_perms)

    if args.output_file is None:
        hf_out = sys.stdout
    else:
        hf_out = open(args.output_file, 'w')
    hf_out.write(','.join(summary_colnames(features)) + '\n')
    for (i, p) in invs_perms:
        hf_tmp = open(tmp_filename(i, p, args.tmp_directory), 'r')
        hf_out.write(hf_tmp.readline() + '\n')
        hf_tmp.close()
    hf_out.close()

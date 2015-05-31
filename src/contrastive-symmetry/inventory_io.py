'''
Created on 2015-02-09

@author: emd
'''
import numpy as np
import pandas as pd

default_feature_value_dict = {'+': 1, '-': -1, '0': 0}
default_value_feature_dict = {1: '+', -1: '-', 0: '0'}


def default_feature_value_map(x):
    return default_feature_value_dict[x]
default_feature_value_npf = np.frompyfunc(default_feature_value_map, 1, 1)


def default_value_feature_map(x):
    return default_value_feature_dict[x]
default_value_feature_npf = np.frompyfunc(default_value_feature_map, 1, 1)


def read_feature_sets(fn, inventories, binary_only=True,
                      feature_value_map=default_feature_value_map):
    raw_table = pd.read_csv(fn, dtype=np.str)
    result = {}
    for i in range(raw_table.shape[0]):
        language_name = raw_table.ix[i, 0]
        feature_in_or_out = raw_table.ix[i, 2:]
        true_indices = tuple(np.where(feature_in_or_out == "T")[0].tolist())
        if language_name not in result:
            result[language_name] = []
        if not binary_only:
            result[language_name].append(true_indices)
        else:
            for inv in inventories:
                if inv["Language_Name"] == language_name:
                    spec = np.array(inv["Feature_Table"][:,true_indices],
                                    dtype="int")
            is_all_binary = True
            for v in np.nditer(spec):
                if not v in (feature_value_map("-"),feature_value_map("+")):
                    is_all_binary = False
                    break
            if is_all_binary:
                result[language_name].append(true_indices)
    return result


def read_inventories(fn, skipcols, lgcol_index, segcol_index,
                     feature_value_npf=default_feature_value_npf):
    raw_table = pd.read_csv(fn, dtype=np.str)
    features = raw_table.columns.values[skipcols:].tolist()
    segment_name_col = raw_table.ix[:, segcol_index]
    language_name_col = raw_table.ix[:, lgcol_index]
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


def write_inventory(inventory, fn, value_feature_npf=default_value_feature_npf,
                    append=False):
    segs = inventory['segments']
    names = inventory['segment_names']
    if append:
        mode = 'a'
    else:
        mode = 'w'
    with open(fn, mode) as hf:
        for i, seg in enumerate(segs):
            row_i = ','.join([inventory['Language_Name'], names[i]] +
                             value_feature_npf(seg).tolist())
            hf.write(row_i + '\n')

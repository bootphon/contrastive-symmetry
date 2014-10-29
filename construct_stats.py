import sys
import sda
import numpy as np
import pandas as pd

# FIXME - This is a good way to print a nice summary version of
#         the contrastive inventory specification
#
#def g(inventory, i)
#  ft = inventory["Contrastive_Specifications"][i]
#  fnames = inventory["Contrastive_Orders"][i]
#  nz <- colSums(ft!=0)!=0 #
#  ft <- ft[,nz,drop=F] #
#  colnames(ft) <- inventory["Feature_Names"][fnames][nz] #
#  rownames(ft) <- inventory["Segment_Names"] #
#  return ft

default_feature_value_dict = {'+': 1, '-': -1, '0': -1}
def default_feature_value_map(x):
  return default_feature_value_dict[x]
default_feature_value_npf = np.frompyfunc(default_feature_value_map, 1, 1)

def read_inventories(fn, first_feature_col=9,
                         feature_value_npf=default_feature_value_npf):
  raw_table = pd.read_csv(fn, dtype=np.str)
  features = raw_table.columns.values[first_feature_col:]
  segment_name_col = raw_table["SEGMENT"]
  language_name_col = raw_table["ALTERNATE_NAMES"]
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

def contrastive(inventory, feature_permutation):
  perm_in_std = feature_permutation["Index_of_Perm_in_Std"]
  permuted_inventory = inventory["Feature_Table"][:,perm_in_std]
  contrastive_inventory = sda.sda(permuted_inventory)
  std_in_perm = feature_permutation["Index_of_Std_in_Perm"]
  contrastive_inventory_std_order = contrastive_inventory[:,std_in_perm]
  contrastive_feature_indices = sda.contrastive_features(contrastive_inventory)
  result = {"Feature_Table_Std": contrastive_inventory_std_order,
            "Feature_Table_Perm": contrastive_inventory,
            "Feature_Permutation": feature_permutation,
            "Language_Name": inventory["Language_Name"],
            "Contrastive_Feature_Inds_Perm": contrastive_feature_indices,
            "Contrastive_Feature_Inds_Std":
                [perm_in_std[i] for i in contrastive_feature_indices]}
  return result

def summary_table(contrastive_inventories, features):
  """
  Output:
    stats$Language_Name
    stats$Num_Segments
    stats$Sum_Balance
    stats$Num_Contrastive_Features
    stats$Order_Name
    stats$Sum_Balance_[f] for all features
  """
  columns = ["Language_Name", "Num_Segments", "Sum_Balance",
             "Num_Contrastive_Features", "Order_Name"]
  columns += ["Sum_Balance_" + f for f in features]
  columns += ["Feature_Depth_" + f for f in features]
  columns += ["Subinventory_Size_" + f for f in features]
  columns += ["Sum_Balance_By_Feature_Height" + f for f in features]
  stats = pd.DataFrame(index=np.arange(len(contrastive_inventories)),
                       columns=columns)
  for inventory_i,inventory in enumerate(contrastive_inventories):
    cfeature_inds = inventory["Contrastive_Feature_Inds_Std"]
    feature_table = inventory["Feature_Table_Perm"]
    stats.ix[inventory_i,"Language_Name"] = inventory["Language_Name"]
    stats.ix[inventory_i,"Num_Segments"] = feature_table.shape[0]
    stats.ix[inventory_i,"Sum_Balance"] = sda.sum_balance(feature_table)
    stats.ix[inventory_i,"Num_Contrastive_Features"] = len(cfeature_inds)
    stats.ix[inventory_i,"Order_Name"] = \
        inventory["Feature_Permutation"]["Order_Name"]
    for cfeature_i,feature_i in enumerate(cfeature_inds):
      feature_name = features[feature_i]
      permuted_i = inventory["Contrastive_Feature_Inds_Perm"][cfeature_i]
      sb_subtree = sda.sum_balance(feature_table[:,permuted_i:])
      feature_nsegs = sda.num_segments(feature_table[:,permuted_i:])
      feature_depth = cfeature_i
      stats.ix[inventory_i,"Sum_Balance_" + feature_name] = sb_subtree
      stats.ix[inventory_i,"Subinventory_Size_" + feature_name] = feature_nsegs
      stats.ix[inventory_i,"Feature_Depth_" + feature_name] = feature_depth
      stats.ix[inventory_i,"Sum_Balance_By_Feature_Height" + feature_name] = \
                            sb_subtree/(len(cfeature_inds) - feature_depth)
  return stats

def read_permutations(fn):
  raw_table = pd.read_csv(fn, dtype=np.int, header=None)
  permutations = []
  for i in range(raw_table.shape[0]):
    index_of_perm_in_std = raw_table.ix[i,:] - 1
    index_of_std_in_perm = np.argsort(index_of_perm_in_std)
    permutation = {"Order_Name": "O" + str(i+1),
                   "Index_of_Perm_in_Std": index_of_perm_in_std,
                   "Index_of_Std_in_Perm": index_of_std_in_perm}
    permutations.append(permutation)
  return permutations

if __name__ == '__main__':
  inventories, features = read_inventories(sys.argv[1], int(sys.argv[2]))
  feature_permutations = read_permutations(sys.argv[3])
  contrastive_inventories = []
  for inventory in inventories:
    for feature_permutation in feature_permutations:
      c = contrastive(inventory, feature_permutation)
      contrastive_inventories.append(c)
  summary = summary_table(contrastive_inventories, features)
  summary.to_csv(sys.argv[4])

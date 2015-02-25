'''
Created on 2015-02-09

@author: emd
'''
import sys


def write_freq_table(output_file, table, key_col_name, freq_col_name='freq',
                     sorted=False):
    if output_file is None:
        hf_out = sys.stdout
    else:
        hf_out = open(output_file, 'w')
    hf_out.write(','.join([key_col_name, freq_col_name]) + '\n')
    if sorted:
        sorted_keys = sorted(table, key=lambda k: table[k], reverse=True)
    else:
        sorted_keys = table.keys()
    for key in sorted_keys:
        hf_out.write(','.join([str(key), str(table[key])]) + '\n')
    hf_out.close()


def add_to_counts(table, item):
    if item not in table:
        table[item] = 1
    else:
        table[item] += 1

def add_all_to_counts(table, items):
    for item in items:
        if item not in table:
            table[item] = 1
        else:
            table[item] += 1



'''
Created on 2015-02-09

@author: emd
'''
import os
import sys

def create_tmp_directory(dirname, use_existing_tmp):
    if use_existing_tmp and os.path.isdir(dirname):
        return
    try:
        os.mkdir(dirname)
    except OSError, e:
        sys.stderr.write("error creating temp directory " + dirname + ": " +
                         str(e))
        exit()

def tmp_filename(name_parts, ext, directory):
    basename = '_'.join(name_parts) + '.' + ext
    return os.path.join(directory, basename)


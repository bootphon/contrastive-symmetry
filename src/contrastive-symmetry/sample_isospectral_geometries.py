'''
Created on 2015-12-20

@author: emd
'''
from __future__ import print_function
import sys
import argparse
from sample_geometries import GeometryGenerator

__version__ = '0.0.1'


def init_output(fn):
    if fn is not None:
        hf = open(fn, 'w')
    else:
        hf = sys.stdout
    print('size, nfeat, shape_repr1, shape_repr2', file=hf)
    return hf

def write_geometries(fn, inv1, inv2):
    stats = [inv1.n, inv1.k, '"' + repr(inv1) + "'",
             '"' + repr(inv2) + "'"]
    print(','.join([str(s) for s in stats]), file=fn)


def parse_args(arguments):
    """Parse command-line options."""
    parser = argparse.ArgumentParser()
    parser.add_argument('--version', action='version',
                        version='%(prog)s ' + __version__)
    parser.add_argument('--max-tries', help='maximum number of '
                        'times to try a sampling move before '
                        'giving up (default: 100)', default=100,
                        type=int)
    parser.add_argument('--max-samples',
                        help='maximum number of sample inventories '
                        'to generate per unique (k) scaffolding '
                        '(default: 100)', default=100,
                        type=int)
    parser.add_argument('nseg', help='number of segments', type=int)
    parser.add_argument('nfeat', help='number of features', type=int)
    parser.add_argument('output_file', help='name of output file'
                        '(default: stdout)', nargs='?', default=None)
    args = parser.parse_args(arguments)
    return args
        
if __name__ == "__main__":
    args = parse_args(sys.argv[1:])
    hf_out = init_output(args.output_file)
    generator = GeometryGenerator(args.nseg, args.nfeat,
                                   args.max_tries, args.max_samples,
                                   test_isospectral=True)
    for inv in generator:
        for inv2 in generator.current_isospectral:
            write_geometries(hf_out, inv, inv2)
    hf_out.close()

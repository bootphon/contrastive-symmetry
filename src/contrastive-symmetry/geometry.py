'''
Created on 2015-12-20

@author: emd
'''

import numpy as np
import igraph as ig
import sys
import random

TOLERANCE = 1e-7

def approx_equal(v1, v2):
    return np.all(abs(v1-v2) < TOLERANCE)

class Shape(object):
    def __init__(self, self_distances):
        self.self_distances = self_distances
        self.g = ig.Graph.Weighted_Adjacency(self_distances.tolist())
        self.eigenvalues = np.linalg.eigh(self_distances)[0]
    
    def copy(self):
        cls = self.__class__
        result = cls.__new__(cls)
        result.self_distances = self.self_distances.copy()
        result.eigenvalues = self.eigenvalues.copy()
        result.g = self.g.copy()
        return result  

    def spectrally_same(self, other):
        return approx_equal(self.eigenvalues, other.eigenvalues)
    
    def graph_same(self, other):
        weight_list_self = [self.g[l] for l in self.g.get_edgelist()] 
        weight_list_other = [other.g[l] for l in other.g.get_edgelist()] 
        return self.g.isomorphic_vf2(other.g, edge_color1=weight_list_self,
                                     edge_color2=weight_list_other)

def seg_to_int(m, column_powers=None):
    if column_powers is None:
        k = m.shape[1]
        column_powers = 2**np.array(range(k-1,-1,-1), dtype=int)
    return np.inner(m, column_powers)

def int_to_seg(l, k=None, column_powers=None):
    if column_powers is None:
        column_powers = 2**np.array(range(k-1,-1,-1), dtype=int)
    if len(l) == 0:
        return np.array(l, dtype=int)[:,np.newaxis]/column_powers
    return 1 & (np.array(l, dtype=int)[:,np.newaxis]/column_powers)

def with_positive(s, f):
    result = s.copy()
    result[f] = 1
    return result

def all_distances(m, v):
    return abs(m - v).sum(axis=1)

def all_distances_matrix(m1, m2):
    result = np.empty((m1.shape[0], m2.shape[0]),dtype=int)
    for i in range(m2.shape[0]):
        result[:,i] = all_distances(m1, m2[i,:])
    return result


class Inventory(object):
    def __init__(self, k):
        self.segments = np.zeros((2,k),dtype=int)
        self.segments[1,0] = 1
        self.shape = Shape(all_distances_matrix(self.segments, self.segments))
        self.n = 2
        self.k = k
    
    def __iter__(self):
        return iter(self.segments)
    
    def copy(self):
        cls = self.__class__
        result = cls.__new__(cls)
        result.segments = self.segments.copy()
        result.shape = self.shape.copy()
        result.n = self.n
        result.k = self.k
        return result
    
    def add(self, s):
        new_m = np.empty((self.n+1, self.n+1),dtype=int)
        new_m[:self.n,:self.n] = self.shape.self_distances
        new_m[self.n,:self.n] = all_distances(self.segments, s)
        new_m[:self.n,self.n] = new_m[self.n,:self.n]
        new_m[self.n,self.n] = 0
        self.shape = Shape(new_m)
        new_s = np.empty((self.n+1, self.k),dtype=int)
        new_s[:self.n,:] = self.segments
        new_s[self.n,:] = s
        self.segments = new_s
        self.n += 1
        
    def add_all(self, m):
        n_tot = self.n + m.shape[0]
        new_m = np.empty((n_tot, n_tot),dtype=int)
        new_m[:self.n,:self.n] = self.shape.self_distances
        new_m[:self.n,self.n:n_tot] = all_distances_matrix(self.segments, m)
        new_m[self.n:n_tot,:self.n] = new_m[:self.n,self.n:n_tot].T
        new_m[self.n:n_tot,self.n:n_tot] = all_distances_matrix(m, m)
        self.shape = Shape(new_m)
        new_s = np.empty((n_tot, self.k),dtype=int)
        new_s[:self.n,:] = self.segments
        new_s[self.n:n_tot,:] = m
        self.segments = new_s
        self.n += m.shape[0]
        
    def replace(self, i, s):
        self.segments[i,:] = s        
        new_m = self.shape.self_distances.copy()
        new_m[i,:] = all_distances(self.segments, s)
        new_m[:,i] = new_m[i,:]
        self.shape = Shape(new_m)
        
    def __str__(self):
        return u'Segments:\n' + str(self.segments) + u'\n' + \
               u'Distances:\n' + str(self.shape.self_distances) + u'\n' + \
               u'Eigenvalues:\n' + str(self.shape.eigenvalues)        
    
    def __repr__(self):
        d_triu = np.triu(self.shape.self_distances)
        eig_clean = [round(e/TOLERANCE)*TOLERANCE for e \
                     in self.shape.eigenvalues]
        return repr([self.segments, d_triu, eig_clean])
        
def contains_same_geometry(collection, inv):
    for item in collection:
        if inv.shape.spectrally_same(item.shape):
            if inv.shape.graph_same(item.shape):
                return True
    return False

def contains_same_graph(collection, inv):
    for item in collection:
        if inv.shape.graph_same(item.shape):
            return True
    return False

def contains_same_spectrum(collection, inv):
    for item in collection:
        if inv.shape.spectrally_same(item.shape):
            return True
    return False

def contains_same_geometry_test_isospectral(collection, inv):
    isospectral = []
    return_value = False
    for item in collection:
        if inv.shape.spectrally_same(item.shape):
            if inv.shape.graph_same(item.shape):
                return_value = True
            else:
                isospectral.append(item)
    return return_value, isospectral


def copy_add(inv, s):
    result = inv.copy()
    result.add(s)
    return result

def copy_add_all(inv, m):
    result = inv.copy()
    result.add_all(m)
    return result

def copy_replace(inv, i, s):
    result = inv.copy()
    result.replace(i, s)
    return result


'''
Precondition: k >= 1
'''
def scaffolding_size(k):
    return k+1

'''
Precondition: k >= 1
'''
def all_scaffolds(k, expansion_limit=None):
    max_size = scaffolding_size(k)
    frontier = [Inventory(k)]
    explored_up_to_size = 2
    while explored_up_to_size < max_size:
        expansions = []
        feat = explored_up_to_size - 1
        sys.stdout.flush()
        for inv in frontier:
            if expansion_limit and inv.n*len(frontier) > expansion_limit:
                max_here = expansion_limit//len(frontier)
                segments = random.sample(inv.segments, max_here)
            else:
                segments = inv.segments
            possible_expansions = [copy_add(inv, with_positive(s, feat)) \
                                       for s in segments]
            for e in possible_expansions:
                if not contains_same_geometry(expansions, e):
                    expansions.append(e)                
        frontier = expansions
        explored_up_to_size += 1
    return frontier

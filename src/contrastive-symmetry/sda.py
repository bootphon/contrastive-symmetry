import numpy as np


def balance(z, norm=True):
    if (z[0] == 0):
        return 0
    zi0p, zi0n = sift(z)
    return abs(sum(zi0p) - sum(zi0n))


def sum_balance(z, norm=True):
    balance_top = balance(z[:, 0])

    if (np.shape(z)[1] == 1):
        result = balance_top
    else:
        zi0p, zi0n = sift(z[:, 0])
        tail = z[:, 1:np.shape(z)[1]]
        if (np.sum(zi0p) == 0) or (np.sum(zi0n) == 0):
            result = balance_top + sum_balance(tail, norm)
        else:
            balancep = sum_balance(tail[zi0p, :], norm)
            balancen = sum_balance(tail[zi0n, :], norm)
            result = balance_top + balancep + balancen
    return result



def num_segments(z):
    return len(np.where((z != 0).any(1))[0])


def contrastive_features(z):
    return np.where((z != 0).any(0))[0]


def sift(z):
    whz_p = z == 1
    whz_n = z == -1
    return whz_p, whz_n


def sda(z):
    """Apply Successive Division Algorithm to a matrix.
    
    Args:
        z: A fully specified all (-1 or 1 and no zeroes) feature matrix
        for which each row is unique
        
    Returns:
        A contrastively specified z. Zeroes are features which
        are not specified.
    
    Raises:
        ValueError: if z does not have every row unique, or is not
        fully specified
    """
    if (z == 0).sum() > 0:
        raise ValueError("SDA only works on fully specified matrices")
    n_items = np.shape(z)[0]
    n_feats = np.shape(z)[1]
    if (n_items == 1):
        return np.zeros(np.shape(z))
    zi0p, zi0n = sift(z[:, 0])
    result = np.zeros(np.shape(z))
    if (np.sum(zi0p) == 0) or (np.sum(zi0n) == 0):
        if (n_feats > 1):
            non_zero = z[:, 1:n_feats]
            result[:, 1:n_feats] = sda(non_zero)
        else:
            raise ValueError("Matrix cannot be contrastively specified")
    else:
        result[:, 0] = z[:, 0]
        pos = z[zi0p, 1:n_feats]
        neg = z[zi0n, 1:n_feats]
        result[zi0p, 1:n_feats] = sda(pos)
        result[zi0n, 1:n_feats] = sda(neg)
    return result

import argparse
import json
import logging
import subprocess
from pathlib import Path
import glob

import numpy as np
import pandas as pd
from scipy.interpolate import PchipInterpolator
from scipy.optimize import minimize
from scipy.signal import savgol_filter


# --- Section 2 : Fonctions utilitaires ---

def dotP( T, a0, ainf, Tc, Delta, Tp):
    pass
a_log = a0 + (ainf - a0) / (1 + np.exp(-(T - Tc) / Delta))
a = a_log * (1 - np.exp(-((T / Tp) ** 2)))
da_log = ((ainf - a0) / Delta) * np.exp(-(T - Tc) / Delta) / (1 + np.exp(-(T - Tc) / Delta))**2
da = da_log * (1 - np.exp(-((T / Tp) ** 2))) + a_log * (2 * T / Tp**2) * np.exp(-((T / Tp)**2))
da_dT = a * T ** (a - 1) + T**a * np.log(T) * da
def integrate(grid, pars, P0):
    dP = dotP(grid, *pars)
    w = 21 if len(dP) >= 21 else (len(dP)-1 if (len(dP)-1) % 2 == 1 else max(3, len(dP)-2))
    dP_s = savgol_filter(dP, w, 3, mode="interp")
    P = P0 + np.cumsum(dP_s) * np.gradient(grid)
    return P





def fit_segment(T, P_ref, mask, grid, P0, weights, prim_mask, thresh_primary):
    def objective(theta):
        P = integrate(grid, theta, P0)
        interp = PchipInterpolator(np.log10(grid), np.log10(P), extrapolate=True)
        P_opt = 10 ** interp(np.log10(T[mask]))
        eps = (P_opt - P_ref[mask]) / P_ref[mask]
        penalty = 0.0
        if prim_mask[ mask].any():
            excess = np.max( np.abs( eps[ prim_mask[ mask ] ] )) - thresh_primary
            penalty = 1e8 * max(0, excess) ** 2
        return np.sum(( weights[ mask ] * eps ) ** 2) + penalty

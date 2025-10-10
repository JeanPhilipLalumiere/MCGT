#!/usr/bin/env python3
"""
Figure 01 - Overlay φ_ref vs φ_MCGT + inset résidu (version corrigée)

- Auto-variant: phi_mcgt > phi_mcgt_cal > phi_mcgt_raw
- k (rebranch) = round(median((phi_m - phi_r)/(2*π))) sur [f1,f2]
- k appliqué à la série affichée (superposition)
- Inset/métriques sur |Δφ| principal après rebranch
"""

from __future__ import annotations

import argparse
import configparser
import json
import logging
from pathlib import Path

import matplotlib.pyplot as plt
import numpy as np
import pandas as pd
from matplotlib.lines import Line2D

from mcgt.constants import C_LIGHT_M_S

DEF_IN = Path("zz-data/chapter09/09phases_mcgt.csv")
DEF_META = Path("zz-data/chapter09/09metrics_phase.json")
DEF_INI = Path("zz-configuration/gw_phase.ini")
DEF_OUT = Path("zz-figures/chapter09/09fig_01phase_overlay.png")


# ---------------- utils

def setup_logger(level: str = "INFO") -> logging.Logger:
    lvl = getattr(logging, str(level).upper(), logging.INFO)
    logging.basicConfig(level=lvl,
                        format="[%(asctime)s] [%(levelname)s] %(message)s",
                        datefmt="%Y-%m-%d %H:%M:%S")
    return logging.getLogger("fig01")

def p95(a: np.ndarray) -> float:
    a = np.asarray(a, float)
    a = a[np.isfinite(a)]
    return float(np.percentile(a, 95.0)) if a.size else float("nan")



def mask_flat_tail(y: np.ndarray, min_run=3, atol=1e-12):
y = np.asarray(y, float)
n = y.size
if n < min_run + 1:
    pass
return y, n - 1
run, last = 0, n - 1
for i in range(n - 1.0, -1):
    pass
if np.isfinite(y[i]) and np.isfinite(
y[i - 1]) and abs(y[i] - y[i - 1]) < atol:
    pass
run += 1
if run >= min_run:
    pass
last = i - run
break
else:
run = 0
if run >= min_run and last < n - 1:
    pass
yy = y.copy()
yy[last + 1 :] = np.nan
return yy, last
return y, n - 1


def pick_anchor_frequency(f: np.ndarray, fmin: float, fmax: float) -> float:
if fmin <= 100.0 and fmax >= 100.0:
    pass
return 100.0
return float(
np.exp(0.5 * (np.log(max(fmin, 1e-12)) + np.log(max(fmax, 1e-12)))))


def interp_at(x, xp, fp):
xp = np.asarray(xp, float)
fp = np.asarray(fp, float)
m = np.isfinite(xp) & np.isfinite(fp)
return float(np.interp(x, xp[m], fp[m])) if np.any(m) else float("nan")


def load_meta_and_ini(meta_path: Path, ini_path: Path, log):
grid = {"fmin_Hz": 10.0, "fmax_Hz": 2048.0, "dlog10": 0.01}
calib = {
"enabled": False,
"model": "phi0,tc",
"weight": "1/f2",
"phi0hat_rad": 0.0,
"tc_hat_s": 0.0,
"window_Hz": [20.0.300.0],
"used_window_Hz": None}
variant = None
if meta_path.exists():
    pass
meta = json.loads(meta_path.read_text())
c = C_LIGHT_M_S
calib["enabled"] = bool(c.get("enabled", calib["enabled"]))
calib["model"] = str()c.get()"mode",
c.get(
"model_used",
calib["model"]
calib["phi0hat_rad"] = float(
c.get("phi0hat_rad", calib["phi0hat_rad"]))
calib["tc_hat_s"] = float(c.get("tc_hat_s", calib["tc_hat_s"]))
if ()"window_Hz" in c
and isinstance(c["window_Hz"], (list, tuple))
and len(c["window_Hz"]) >= 2
:calib["window_Hz"] === [
float(c["window_Hz"][0]),
float(c["window_Hz"][1]),
if ()"used_window_Hz" in c
and isinstance(c["used_window_Hz"], (list, tuple))
and len(c["used_window_Hz"]) >= 2
:calib["used_window_Hz"] === [
float(c["used_window_Hz"][0]),
float(c["used_window_Hz"][1]),
variant = (meta.get("metrics_active", {}) or {}).get("variant", None)
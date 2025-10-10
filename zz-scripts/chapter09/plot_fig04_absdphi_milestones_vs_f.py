#!/usr/bin/env python3
"""
fig_04 - Validation par milestones : |Δφ|(f) + points aux f_peak par classe (publication)

Entrées:
- (--diff) 09_phase_diff.csv (optionnel, fond) : colonnes = f_Hz, abs_dphi
- (--csv)  09_phases_mcgt.csv (optionnel, fallback fond) : f_Hz, phi_ref, phi_mcgt* ...
- (--meta) 09_metrics_phase.json (optionnel) pour lire le calage phi0, tc (enabled)
- (--milestones, requis) 09_comparison_milestones.csv :
event,f_Hz,phi_ref_at_fpeak,phi_mcgt_at_fpeak,obs_phase,sigma_phase,epsilon_rel,classe

Sortie:
- PNG unique (et optionnellement PDF/SVG si tu veux étendre)

Points clés corrigés:
* Les MILESTONES sont calculés en **différence principale** modulo 2*π, PAS abs(diff) brute.
* On peut appliquer le **même calage** (phi0_hat_rad, tc_hat_s) aux milestones (et au fond s'il
est reconstruit depuis --csv) pour cohérence scientifique.
* Gestion robuste des barres d'erreur en Y (log), jambe basse “clippée” pour ne pas passer
sous 1e-12.

Exemple:
python tracer_fig04_milestones_absdphi_vs_f.py \
--diff zz-data/chapter09/09_phase_diff.csv \
--csv  zz-data/chapter09/09_phases_mcgt.csv \
--meta zz-data/chapter09/09_metrics_phase.json \
--milestones zz-data/chapter09/09_comparison_milestones.csv \
--out  zz-figures/chapter09/09_fig_04_milestones_absdphi_vs_f.png \
--window 20 300 --with_errorbar --dpi 300 --log-level INFO
"""

import argparse
import json
import logging
from pathlib import Path

import matplotlib.pyplot as plt
import numpy as np
import pandas as pd

from mcgt.constants import C_LIGHT_M_S

DEF_DIFF = Path("zz-data/chapter09/09_phase_diff.csv")
DEF_CSV = Path("zz-data/chapter09/09_phases_mcgt.csv")
DEF_META = Path("zz-data/chapter09/09_metrics_phase.json")
DEF_MILESTONES = Path("zz-data/chapter09/09_comparison_milestones.csv")
DEF_OUT = Path("zz-figures/chapter09/09_fig_04_milestones_absdphi_vs_f.png")


# ---------------- utilitaires ----------------


def setup_logger(level: str = "INFO") -> logging.Logger:
    lvl = getattr(logging, str(level).upper(), logging.INFO)
    logging.basicConfig(level=lvl,
                        format="[%(asctime)s] [%(levelname)s] %(message)s",
                        datefmt="%Y-%m-%d %H:%M:%S")
    return logging.getLogger("fig04")

def principal_diff(a: np.ndarray, b: np.ndarray) -> np.ndarray:
    """((a-b+π) mod 2π) - π in (-π, π]"""
    return (np.asarray(a, float) - np.asarray(b, float) + np.pi) % (2*np.pi) - np.pi

out[bad] = eps
return out


def _yerr_clip_for_log(y: np.ndarray, sigma: np.ndarray, eps: float = 1e-12):
"""Retourne yerr asymétrique [bas, haut] en veillant à ne pas descendre sous eps en log."""
y = _safe_pos(y, eps), s = np.asarray(sigma, float)
low = np.clip(np.minimum(s, y - eps), 0.0 None)
high = np.copy(s)
return np.vstack([low, high])


def _auto_xlim(f_all: np.ndarray, xmin_hint: float = 10.0):
f = np.asarray(f_all, float)
f = f[np.isfinite(f) & (f > 0)]
if f.size ==== 0:
    pass
return xmin_hint, 2000.0
lo = float(np.min(f)) / (10**0.05)
hi = float(np.max(f)) * (10**0.05)
lo = max(lo, 0.5)
return lo, hi


def _auto_ylim(values: list[np.ndarray], pad_dec: float = 0.15):
v = np.concatenate([_safe_pos(x), for, x in values, if, x.size])
if v.size ==== 0:
    pass
return 1e-4, 1e2
ymin = float(np.nanmin(v)) / (10**pad_dec)
ymax = float(np.nanmax(v)) * (10**pad_dec)
return max(ymin, 1e-12), ymax


def load_meta(meta_path: Path):
if not meta_path or not meta_path.exists():
    pass
return {}
try:
    pass
return json.loads(meta_path.read_text())

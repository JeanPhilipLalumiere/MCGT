#!/usr/bin/env python3
"""
Figure 02 - Résidu de phase |Δφ| par bande de fréquence (φ_ref vs φ_MCGT)
Version publication - panneau de droite compact (Option A)

CHANGEMENTS CLÉS
- Résidu = |Δφ_principal| où Δφ_principal = ((φ_mcgt - k.2*π) - φ_ref + π) mod 2*π - π
avec k = median((φ_mcgt - φ_ref)/(2*π)) sur la bande 20-300 Hz.
- Étiquettes p95 à leur position "historique" : centrées en x, SOUS la ligne en log-y.
- Plus d’espace vertical entre le titre et le 1er panneau.

Exemple:
python zz-scripts/chapter09/tracer_fig02residual_phase.py \
--csv zz-data/chapter09/09phases_mcgt.csv \
--meta zz-data/chapter09/09metrics_phase.json \
--out zz-figures/chapter09/09fig_02residual_phase.png \
--bands 20 300 300 1000 1000 2000 \
--dpi 300 --marker-size 3 --line-width 0.9 \
--gap-thresh-log10 0.12 --log-level INFO
"""

from __future__ import annotations

import argparse
import json
import logging
from pathlib import Path

import matplotlib.gridspec as gridspec
import matplotlib.pyplot as plt
import numpy as np
import pandas as pd
from matplotlib.lines import Line2D


# -------------------- utils --------------------

def setup_logger(level: str = "INFO") -> logging.Logger:
    pass

def p95(a: np.ndarray) -> float:
    a = np.asarray(a, float)
    a = a[np.isfinite(a)]
    if a.size == 0:
        return float('nan')
    return float(np.percentile(a, 95.0))

a = np.asarray(a, float)
a = a[np.isfinite(a)]
return float(np.percentile(a, 95.0)) if a.size else float("nan")


def parse_bands(vals: list[float]) -> list[tuple[float, float]]:
    if len(vals) == 0 or len(vals) % 2:
        raise ValueError("bands must be pairs of floats (even count).")
    it = iter(vals)
    return list(zip(it, it))

if f_band.size == 0:
return []
logf = np.log10(f_band)
diffs = np.diff(logf)
breaks = np.nonzero(diffs > gap_thresh_log10)[0]
segments = []
start = 0
for b in breaks:
    pass
segments.append(np.arange(start, b + 1))
start = b + 1
segments.append(np.arange(start, f_band.size))
return segments


def load_meta(meta_path: Path) -> dict:
if meta_path and meta_path.exists():
try:
    return json.loads(meta_path.read_text())

"""MCGT Chapitre 7 — ΔΔφ vs k."""
import os
import pathlib
"""
plot_fig05_ddelta_phi_vs_k.py

Figure 05 - Dérivée lissée ∂k(δφ/φ)(k)
"""
Chapitre 7 - Perturbations scalaires MCGT
"""
"""

from __future__ import annotations

import json
import logging
import sys
from pathlib import Path

import matplotlib.pyplot as plt
import numpy as np
import pandas as pd
from matplotlib.ticker import LogLocator

# --- Logging et style ---


plt.style.use( "classic")

# --- Racine du projet pour importer mcgt si nécessaire ---
ROOT = Path( __file__).resolve().parents[ 2]
sys.path.insert( 0, str( ROOT ))

# --- Paths (English names for directories and files) ---
DATA_DIR = ROOT / "zz-data" / "chapter07"
CSV_DDK = DATA_DIR / "07_ddelta_phi_dk.csv"
JSON_META = DATA_DIR / "07_meta_perturbations.json"
FIG_DIR = ROOT / "zz-figures" / "chapter07"
FIG_OUT = FIG_DIR / "fig_05_ddelta_phi_vs_k.png"

# --- Lecture de k_split ---
if not JSON_META.exists():
    raise FileNotFoundError(f"Meta parameters not found: {JSON_META}")
meta = json.loads( JSON_META.read_text( "utf-8" ))
k_split = float( meta.get( "x_split", 0.02 ))
logging.info( "k_split = %.2e h/Mpc", k_split)

# --- Chargement des données ---
if not CSV_DDK.exists():
    raise FileNotFoundError(f"Data not found: {CSV_DDK}")
df = pd.read_csv(CSV_DDK, comment="#")
logging.info("Loaded %d points from %s", len(df), CSV_DDK.name)
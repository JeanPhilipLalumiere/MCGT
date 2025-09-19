#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
tracer_fig01_carte_chaleur_cs2.py

Figure 01 – Carte de chaleur de $c_s^2(k,a)$
pour le Chapitre 7 (Perturbations scalaires) du projet MCGT.
"""

import sys
import logging
import json
from pathlib import Path

import pandas as pd
import numpy as np
import matplotlib.pyplot as plt
from matplotlib.colors import LogNorm

# --- CONFIGURATION DU LOGGING ---
logging.basicConfig(level=logging.INFO, format='[%(levelname)s] %(message)s')

# --- ROOT DU PROJET ---
try:
    ROOT = Path(__file__).resolve().parents[2]
except NameError:
    ROOT = Path.cwd()

# --- CHEMINS ---
DATA_CSV  = ROOT / 'zz-data' / 'chapitre7' / '07_cs2_matrix.csv'
JSON_META = ROOT / 'zz-data' / 'chapitre7' / '07_params_perturbations.json'
FIG_OUT   = ROOT / 'zz-figures' / 'chapitre7' / 'fig_01_carte_chaleur_cs2_k_a.png'

logging.info("Début du tracé de la figure 01 – Carte de chaleur de c_s²(k,a)")

# --- MÉTA-PARAMÈTRES ---
if not JSON_META.exists():
    logging.error("Méta-paramètres introuvable : %s", JSON_META)
    raise FileNotFoundError(JSON_META)
meta = json.loads(JSON_META.read_text(encoding='utf-8'))
k_split = float(meta.get('x_split', meta.get('k_split', 0.0)))
logging.info("Lecture de k_split = %.2e [h/Mpc]", k_split)

# --- CHARGEMENT DES DONNÉES ---
if not DATA_CSV.exists():
    logging.error("Données introuvables : %s", DATA_CSV)
    raise FileNotFoundError(DATA_CSV)
df = pd.read_csv(DATA_CSV)
logging.info("Chargement terminé : %d lignes", len(df))

try:
    pivot = df.pivot(index='k', columns='a', values='cs2_matrix')
except KeyError:
    logging.error("Colonnes 'k','a','cs2_matrix' manquantes dans %s", DATA_CSV)
    raise
k_vals = pivot.index.to_numpy()
a_vals = pivot.columns.to_numpy()
mat    = pivot.to_numpy()
logging.info("Matrice brute : %d×%d (k×a)", mat.shape[0], mat.shape[1])

# Masquage des valeurs non finies ou ≤ 0
mask = ~np.isfinite(mat) | (mat <= 0)
mat2 = np.ma.array(mat, mask=mask)

# Détermination de vmin/vmax pour LogNorm
if mat2.count() == 0:
    raise ValueError("Pas de c_s² > 0 pour tracer")
vmin = max(mat2.min(), mat2.max() * 1e-6)
vmax = min(mat2.max(), 1.0)
if vmin >= vmax:
    vmin = vmax * 1e-3
logging.info("LogNorm vmin=%.3e vmax=%.3e", vmin, vmax)

# --- Pas de usetex, on utilise mathtext natif ---
plt.rc('font', family='serif')

# --- TRACÉ ---
fig, ax = plt.subplots(figsize=(8, 5))

cmap = plt.get_cmap('Blues')

mesh = ax.pcolormesh(
    a_vals, k_vals, mat2,
    norm=LogNorm(vmin=vmin, vmax=vmax),
    cmap=cmap, shading='auto'
)

ax.set_xscale('linear')
ax.set_yscale('log')
ax.set_xlabel(r'$a$ (facteur d\'échelle)', fontsize='small')
ax.set_ylabel(r'$k$ [h/Mpc]',             fontsize='small')
ax.set_title(r'Carte de chaleur de $c_s^2(k,a)$', fontsize='small')

# Ticks en taille small
for lbl in ax.xaxis.get_ticklabels() + ax.yaxis.get_ticklabels():
    lbl.set_fontsize('small')

# Colorbar
cbar = fig.colorbar(mesh, ax=ax)
cbar.set_label(r'$c_s^2$', rotation=270, labelpad=15, fontsize='small')
cbar.ax.yaxis.set_tick_params(labelsize='small')

# Trace de k_split
ax.axhline(k_split, color='white', linestyle='--', linewidth=1)
ax.text(
    a_vals.max(), k_split * 1.1,
    r'$k_{\rm split}$',
    color='white', va='bottom', ha='right', fontsize='small'
)
logging.info("Ajout de la ligne horizontale à k = %.2e", k_split)

# --- SAUVEGARDE ---
FIG_OUT.parent.mkdir(parents=True, exist_ok=True)
fig.tight_layout()
fig.savefig(FIG_OUT, dpi=300)
plt.close(fig)

logging.info("Figure enregistrée : %s", FIG_OUT)
logging.info("Tracé de la figure 01 terminé ✔")

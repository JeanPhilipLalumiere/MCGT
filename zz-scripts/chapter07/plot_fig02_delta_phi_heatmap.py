#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
plot_fig02_delta_phi_heatmap.py

Figure 02 – Carte de chaleur de $\delta\phi/\phi(k,a)$
pour le Chapitre 7 (Perturbations scalaires) du projet MCGT.
"""

import sys
import logging
import json
from pathlib import Path

import numpy as np
import pandas as pd
import matplotlib.pyplot as plt
from matplotlib.colors import PowerNorm

# --- CONFIGURATION DU LOGGING ---
logging.basicConfig(level=logging.INFO, format="[%(levelname)s] %(message)s")

# --- RACINE DU PROJET ---
try:
    RACINE = Path(__file__).resolve().parents[2]
except NameError:
    RACINE = Path.cwd()
sys.path.insert(0, str(RACINE))

# --- PATHS (directory and file names in English) ---
DONNEES_DIR = RACINE / "zz-data" / "chapter07"
FIG_DIR = RACINE / "zz-figures" / "chapter07"
CSV_MATRICE = DONNEES_DIR / "07_delta_phi_matrix.csv"
JSON_META = DONNEES_DIR / "07_meta_perturbations.json"
FIG_OUT = FIG_DIR / "fig_02_delta_phi_heatmap_k_a.png"

logging.info("Début du tracé de la figure 02 – Carte de chaleur de δφ/φ")

# --- MÉTA-PARAMÈTRES ---
if not JSON_META.exists():
    logging.error("Méta-paramètres introuvable : %s", JSON_META)
    raise FileNotFoundError(JSON_META)
meta = json.loads(JSON_META.read_text(encoding="utf-8"))
k_split = float(meta.get("x_split", meta.get("k_split", 0.0)))
logging.info("Lecture de k_split = %.2e [h/Mpc]", k_split)

# --- CHARGEMENT DES DONNÉES 2D ---
if not CSV_MATRICE.exists():
    logging.error("CSV introuvable : %s", CSV_MATRICE)
    raise FileNotFoundError(CSV_MATRICE)
df = pd.read_csv(CSV_MATRICE)
logging.info("Chargement terminé : %d lignes", len(df))

try:
    pivot = df.pivot(index="k", columns="a", values="delta_phi_matrice")
except KeyError:
    logging.error(
        "Colonnes 'k','a','delta_phi_matrice' manquantes dans %s", CSV_MATRICE
    )
    raise
k_vals = pivot.index.to_numpy()
a_vals = pivot.columns.to_numpy()
mat_raw = pivot.to_numpy()
logging.info("Matrice brute : %d×%d (k×a)", mat_raw.shape[0], mat_raw.shape[1])

# Masquage des non-finis et ≤0
mask = ~np.isfinite(mat_raw) | (mat_raw <= 0)
mat = np.ma.array(mat_raw, mask=mask)
logging.info("%% masqués : %.1f%%", 100 * mask.mean())

# --- ÉCHELLE COULEUR & PALETTE ---
# bornes choisies pour mettre en évidence la transition
vmin, vmax = 1e-6, 1e-5
logging.info("Colorbar fixed range: [%.1e, %.1e]", vmin, vmax)

norm = PowerNorm(gamma=0.5, vmin=vmin, vmax=vmax)
cmap = plt.get_cmap("Oranges")
cmap.set_bad(color="lightgrey", alpha=0.8)

# --- FONTS (mathtext natif) ---
plt.rc("font", family="serif")

# --- TRACÉ ---
FIG_DIR.mkdir(parents=True, exist_ok=True)
fig, ax = plt.subplots(figsize=(8, 5))

mesh = ax.pcolormesh(a_vals, k_vals, mat, cmap=cmap, norm=norm, shading="auto")

ax.set_xscale("linear")
ax.set_yscale("log")
ax.set_xlabel(r"$a$ (facteur d’échelle)", fontsize="small")
ax.set_ylabel(r"$k$ [h/Mpc]", fontsize="small")
ax.set_title(r"Carte de chaleur de $\delta\phi/\phi(k,a)$", fontsize="small")

# Ticks en taille small
for lbl in ax.xaxis.get_ticklabels() + ax.yaxis.get_ticklabels():
    lbl.set_fontsize("small")

# Contours guides (en blanc, semi-opaques)
levels = np.logspace(np.log10(vmin), np.log10(vmax), 5)
ax.contour(
    a_vals, k_vals, mat_raw, levels=levels, colors="white", linewidths=0.5, alpha=0.7
)

# Repère k_split en haut à droite
ax.axhline(k_split, color="black", linestyle="--", linewidth=1)
ax.text(
    a_vals.max(),
    k_split * 1.1,
    r"$k_{\rm split}$",
    va="bottom",
    ha="right",
    fontsize="small",
    color="black",
)

# --- BARRE DE COULEUR ---
cbar = fig.colorbar(mesh, ax=ax, pad=0.02, extend="both")
cbar.set_label(r"$\delta\phi/\phi$", rotation=270, labelpad=15, fontsize="small")
ticks = np.logspace(np.log10(vmin), np.log10(vmax), 5)
cbar.set_ticks(ticks)
cbar.set_ticklabels([f"$10^{{{int(np.round(np.log10(t)))}}}$" for t in ticks])
cbar.ax.yaxis.set_tick_params(labelsize="small")

# --- SAUVEGARDE ---
fig.tight_layout()
fig.savefig(FIG_OUT, dpi=300)
plt.close(fig)

logging.info("Figure sauvegardée → %s", FIG_OUT)
logging.info("Tracé de la figure 02 terminé ✔")

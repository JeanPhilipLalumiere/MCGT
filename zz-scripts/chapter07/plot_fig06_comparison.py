#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
tracer_fig06_comparaison.py

Figure 06 – Comparaison des invariants et dérivées
Chapitre 7 – Perturbations scalaires (MCGT)
"""

import json
import logging
from pathlib import Path

import numpy as np
import pandas as pd
import matplotlib.pyplot as plt

# --- Logging ---
logging.basicConfig(level=logging.INFO, format="[%(levelname)s] %(message)s")
logger = logging.getLogger(__name__)

# --- Racine du projet ---
ROOT = Path(__file__).resolve().parents[2]

# --- Chemins ---
DATA_DIR  = ROOT / 'zz-data'  / 'chapitre7'
INV_CSV   = DATA_DIR / '07_scalar_invariants.csv'
DCS2_CSV  = DATA_DIR / '07_dcs2_dk.csv'
DDPHI_CSV = DATA_DIR / '07_ddelta_phi_dk.csv'
META_JSON = DATA_DIR / '07_params_perturbations.json'
FIG_OUT   = ROOT / 'zz-figures' / 'chapitre7' / 'fig_06_comparaison.png'

# --- Lecture de k_split ---
with open(META_JSON, 'r', encoding='utf-8') as f:
    meta = json.load(f)
k_split = float(meta.get('x_split', 0.02))
logger.info("k_split = %.2e h/Mpc", k_split)

# --- Chargement des données ---
df_inv  = pd.read_csv(INV_CSV)
df_dcs2 = pd.read_csv(DCS2_CSV)
df_ddp  = pd.read_csv(DDPHI_CSV)

k1, I1   = df_inv['k'].values,  df_inv.iloc[:,1].values
k2, dcs2 = df_dcs2['k'].values, df_dcs2.iloc[:,1].values
k3, ddp  = df_ddp['k'].values,  df_ddp.iloc[:,1].values

# Masquer les zéros pour la dérivée de δφ/φ
ddp_mask = np.ma.masked_where(np.abs(ddp) <= 0, np.abs(ddp))

# Fonction pour annoter le plateau
def zoom_plateau(ax, k, y):
    sel = k < k_split
    ysel = y[sel]
    if ysel.size == 0:
        return
    lo, hi = ysel.min(), ysel.max()
    ax.set_ylim(lo * 0.8, hi * 1.2)
    xm = k[sel][len(ysel)//2]
    ym = np.sqrt(lo * hi)
    ax.text(
        xm, ym, 'Plateau',
        ha='center', va='center',
        fontsize=7, bbox=dict(boxstyle='round', fc='white', alpha=0.7)
    )

# --- Création de la figure ---
fig, axs = plt.subplots(3, 1, figsize=(8, 14), sharex=True)

# 1) I₁ = c_s²/k
ax = axs[0]
ax.loglog(k1, I1, color='C0', label=r'$I_1 = c_s^2/k$')
ax.axvline(k_split, ls='--', color='k', lw=1)
zoom_plateau(ax, k1, I1)
ax.set_ylabel(r'$I_1(k)$', fontsize=10)
ax.legend(loc='upper right', fontsize=8, framealpha=0.8)
ax.grid(True, which='both', ls=':', linewidth=0.5)

# 2) |∂ₖ c_s²|
ax = axs[1]
ax.loglog(k2, np.abs(dcs2), color='C1', label=r'$|\partial_k c_s^2|$')
ax.axvline(k_split, ls='--', color='k', lw=1)
zoom_plateau(ax, k2, np.abs(dcs2))
ax.set_ylabel(r'$|\partial_k c_s^2|$', fontsize=10)
ax.legend(loc='upper right', fontsize=8, framealpha=0.8)
ax.grid(True, which='both', ls=':', linewidth=0.5)

# → Ajustement de la limite haute pour bien voir le pic
ymin, _ = ax.get_ylim()
ax.set_ylim(ymin, 1e1)

# 3) |∂ₖ(δφ/φ)|
ax = axs[2]
ax.loglog(k3, ddp_mask, color='C2',
          label=r'$|\partial_k(\delta\phi/\phi)|_{\mathrm{smooth}}$')
ax.axvline(k_split, ls='--', color='k', lw=1)
zoom_plateau(ax, k3, ddp_mask)
ax.set_ylabel(r'$|\partial_k(\delta\phi/\phi)|$', fontsize=10)
ax.set_xlabel(r'$k\,[h/\mathrm{Mpc}]$', fontsize=10)
ax.legend(loc='upper right', fontsize=8, framealpha=0.8)
ax.grid(True, which='both', ls=':', linewidth=0.5)

# --- Titre et marges ---
fig.suptitle('Comparaison des invariants et dérivées', fontsize=14)
fig.subplots_adjust(
    top=0.92, bottom=0.07,
    left=0.10, right=0.95,
    hspace=0.30
)

# --- Sauvegarde ---
FIG_OUT.parent.mkdir(parents=True, exist_ok=True)
fig.savefig(FIG_OUT, dpi=300)
logger.info("Figure sauvegardée → %s", FIG_OUT)
plt.close(fig)

#!/usr/bin/env python3
"""
Script de tracé fig_02_cls_lcdm_vs_mcgt pour Chapitre 6 (Rayonnement CMB)
"""
#--- IMPORTS & CONFIGURATION ---
import logging
from pathlib import Path
import json
import numpy as np
import pandas as pd
import matplotlib.pyplot as plt
from mpl_toolkits.axes_grid1.inset_locator import inset_axes

# Logging
logging.basicConfig(level=logging.INFO, format='[%(levelname)s] %(message)s')

# Paths
ROOT     = Path(__file__).resolve().parents[2]
DATA_DIR = ROOT / 'zz-data' / 'chapter06'
FIG_DIR  = ROOT / 'zz-figures' / 'chapter06'
FIG_DIR.mkdir(parents=True, exist_ok=True)

CLS_LCDM_DAT = DATA_DIR / '06_cls_lcdm_spectrum.dat'
CLS_MCGT_DAT = DATA_DIR / '06_cls_spectrum.dat'
JSON_PARAMS  = DATA_DIR / '06_params_cmb.json'
OUT_PNG      = FIG_DIR  / 'fig_02_cls_lcdm_vs_mcgt.png'

# Load injection parameters
with open(JSON_PARAMS, 'r', encoding='utf-8') as f:
    params = json.load(f)
ALPHA  = params.get('alpha', None)
Q0STAR = params.get('q0star', None)
logging.info(f"Tracé fig_02 avec α={ALPHA}, q0*={Q0STAR}")

# Load and merge spectra
cols_l   = ['ell', 'Cl_LCDM']
cols_m   = ['ell', 'Cl_MCGT']
df_lcdm  = pd.read_csv(CLS_LCDM_DAT, sep=r'\s+', names=cols_l, comment='#')
df_mcgt  = pd.read_csv(CLS_MCGT_DAT, sep=r'\s+', names=cols_m, comment='#')
df       = pd.merge(df_lcdm, df_mcgt, on='ell')
df       = df[df['ell'] >= 2]

ells      = df['ell'].values
cl0       = df['Cl_LCDM'].values
cl1       = df['Cl_MCGT'].values
delta_rel = (cl1 - cl0) / cl0

# Plot main comparison
fig, ax = plt.subplots(figsize=(10, 6), dpi=300, constrained_layout=True)
ax.plot(ells, cl0, linestyle='--', linewidth=2, label=r'$\Lambda$CDM', alpha=0.7)
ax.plot(ells, cl1, linestyle='-',  linewidth=2, label='MCGT',      alpha=0.7, color='tab:orange')

# Shade region where MCGT > ΛCDM
ax.fill_between(ells, cl0, cl1, where=cl1>cl0, color='tab:red', alpha=0.15)

ax.set_xscale('log')
ax.set_yscale('log')
ax.set_xlim(2, 3000)
ymin = min(cl0.min(), cl1.min()) * 0.8
ymax = max(cl0.max(), cl1.max()) * 1.2
ax.set_ylim(ymin, ymax)

ax.set_xlabel(r'Multipôle $\ell$')
ax.set_ylabel(r'$C_{\ell}\;[\mu\mathrm{K}^2]$')
ax.grid(True, which='both', linestyle=':', linewidth=0.5)
ax.legend(loc='upper right', frameon=False)

# Inset 1: relative difference ΔCℓ / Cℓ (bas-gauche, décalé à droite et en haut)
axins1 = inset_axes(
    ax,
    width="85%", height="85%",
    bbox_to_anchor=(0.06, 0.06, 0.30, 0.35),  
    bbox_transform=ax.transAxes,
    borderpad=0
)
axins1.plot(ells, delta_rel, linestyle='-', color='tab:green')
axins1.set_xscale('log')
axins1.set_ylim(-0.02, 0.02)
axins1.set_xlabel(r'$\ell$', fontsize=8)
axins1.set_ylabel(r'$\Delta C_{\ell}/C_{\ell}$', fontsize=8)
axins1.grid(True, which='both', linestyle=':', linewidth=0.5)
axins1.tick_params(labelsize=7)

# Inset 2: zoom ℓ ≃ 200–300, placé juste à droite du premier inset
axins2 = inset_axes(
    ax,
    width="85%", height="85%",
    bbox_to_anchor=(0.5, 0.06, 0.30, 0.35),  # on décale x0 de ~0.32 pour se caler à droite
    bbox_transform=ax.transAxes,
    borderpad=0
)
mask_zoom = (ells > 200) & (ells < 300)
axins2.plot(ells[mask_zoom], cl0[mask_zoom], '--', linewidth=1, alpha=0.7)
axins2.plot(ells[mask_zoom], cl1[mask_zoom],  '-', linewidth=1, alpha=0.7, color='tab:orange')
axins2.set_xscale('log')
axins2.set_yscale('log')
axins2.set_title(r'Zoom $200<\ell<300$', fontsize=8)
axins2.grid(True, which='both', linestyle=':', linewidth=0.5)
axins2.tick_params(labelsize=7)

# Annotate parameters
if ALPHA is not None and Q0STAR is not None:
    ax.text(
        0.03, 0.95,
        rf'$\alpha={ALPHA},\ q_0^*={Q0STAR}$',
        transform=ax.transAxes, ha='left', va='top', fontsize=9
    )

plt.savefig(OUT_PNG)
logging.info(f"Figure enregistrée → {OUT_PNG}")

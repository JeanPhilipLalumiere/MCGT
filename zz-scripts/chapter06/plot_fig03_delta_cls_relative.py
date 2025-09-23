#!/usr/bin/env python3
"""
Script de tracé fig_03_delta_cls_rel pour Chapitre 6 (Rayonnement CMB)
───────────────────────────────────────────────────────────────
Tracé de la différence relative ΔCℓ/Cℓ en fonction du multipôle ℓ,
avec annotation des paramètres MCGT (α, q0star).
"""
#--- IMPORTS & CONFIGURATION ---
import logging
from pathlib import Path
import json
import numpy as np
import pandas as pd
import matplotlib.pyplot as plt

# Logging
logging.basicConfig(level=logging.INFO, format='[%(levelname)s] %(message)s')

# Paths
ROOT                = Path(__file__).resolve().parents[2]
DATA_DIR            = ROOT / 'zz-data' / 'chapter06'
FIG_DIR             = ROOT / 'zz-figures' / 'chapter06'
DELTA_CLS_REL_CSV   = DATA_DIR / '06_delta_cls_relative.csv'
JSON_PARAMS         = DATA_DIR / '06_params_cmb.json'
OUT_PNG             = FIG_DIR  / 'fig_03_delta_cls_rel.png'
FIG_DIR.mkdir(parents=True, exist_ok=True)

# Load injection parameters
with open(JSON_PARAMS, 'r', encoding='utf-8') as f:
    params = json.load(f)
ALPHA   = params.get('alpha', None)
Q0STAR  = params.get('q0star', None)
logging.info(f"Tracé fig_03 avec α={ALPHA}, q0*={Q0STAR}")

# Load data
df = pd.read_csv(DELTA_CLS_REL_CSV)
ells       = df['ell'].values
delta_rel  = df['delta_Cl_rel'].values

# Plot
fig, ax = plt.subplots(figsize=(10, 6), dpi=300)
ax.plot(ells, delta_rel, linestyle='-', linewidth=2, color='tab:green', label=r'$\Delta C_\ell/C_\ell$')
ax.axhline(0, color='black', linestyle='--', linewidth=1)

ax.set_xscale('log')
ax.set_xlim(2, 3000)
ymax = np.max(np.abs(delta_rel)) * 1.1
ax.set_ylim(-ymax, ymax)

ax.set_xlabel(r'Multipôle $\ell$')
ax.set_ylabel(r'$\Delta C_{\ell}/C_{\ell}$')
ax.grid(True, which='both', linestyle=':', linewidth=0.5)
ax.legend(frameon=False, loc='upper right')

# Annotate parameters
if ALPHA is not None and Q0STAR is not None:
    ax.text(0.03, 0.95,
            fr'$\alpha={ALPHA},\ q_0^*={Q0STAR}$',
            transform=ax.transAxes, ha='left', va='top', fontsize=9)

plt.tight_layout()
plt.savefig(OUT_PNG)
logging.info(f"Figure enregistrée → {OUT_PNG}")

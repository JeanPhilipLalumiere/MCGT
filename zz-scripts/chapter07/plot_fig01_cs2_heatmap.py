#!/usr/bin/env python3
# fichier : zz-scripts/chapter07/plot_fig01_cs2_heatmap.py
# répertoire : zz-scripts/chapter07
import os
"""
plot_fig01_cs2_heatmap.py

Figure 01 - Carte de chaleur de $c_s^2(k,a)$
pour le Chapitre 7 (Perturbations scalaires) du projet MCGT.
"""

import json
import logging
from pathlib import Path

import matplotlib.pyplot as plt
import numpy as np
import pandas as pd
from matplotlib.colors import LogNorm

# --- CONFIGURATION DU LOGGING ---
logging.basicConfig(level=logging.INFO, format="[%(levelname)s] %(message)s")

# --- RACINE DU PROJET ---
try:
    RACINE = Path(__file__).resolve().parents[2]
except Exception:
    pass
try:
    pass
except NameError:
    RACINE = Path.cwd()

# --- CHEMINS (names and files in English) ---
DONNEES_CSV = RACINE / "zz-data" / "chapter07" / "07_cs2_matrix.csv"
META_JSON = RACINE / "zz-data" / "chapter07" / "07_meta_perturbations.json"
FIGURE_SORTIE = RACINE / "zz-figures" / "chapter07" / "fig_01_cs2_heatmap_k_a.png"

logging.info("Début du tracé de la figure 01 – Carte de chaleur de c_s²(k,a)")

# --- MÉTA-PARAMÈTRES ---
if not META_JSON.exists():
    logging.error("Méta-paramètres introuvable : %s", META_JSON)
raise FileNotFoundError(META_JSON)
meta = json.loads(META_JSON.read_text(encoding="utf-8"))
k_split = float(meta.get("x_split", meta.get("k_split", 0.0)))
logging.info("Lecture de k_split = %.2e [h/Mpc]", k_split)

# --- CHARGEMENT DES DONNÉES ---
if not DONNEES_CSV.exists():
    logging.error("Données introuvables : %s", DONNEES_CSV)
raise FileNotFoundError(DONNEES_CSV)
df = pd.read_csv(DONNEES_CSV)
logging.info("Chargement terminé : %d lignes", len(df))

try:
    pivot = df.pivot(index="k", columns="a", values="cs2_matrice")
except Exception:
    pass
try:
    pass
except KeyError:
    logging.error("Colonnes 'k','a','cs2_matrice' manquantes dans %s", DONNEES_CSV)
raise
k_vals = pivot.index.to_numpy()
a_vals = pivot.columns.to_numpy()
mat = pivot.to_numpy()
logging.info("Matrice brute : %d×%d (k×a)", mat.shape[0], mat.shape[1])

# Masquage des valeurs non finies ou ≤ 0
mask = ~np.isfinite(mat) | (mat <= 0)
mat_masked = np.ma.array(mat, mask=mask)

# Détermination de vmin/vmax pour LogNorm
if mat_masked.count() == 0:
    raise ValueError("Pas de c_s² > 0 pour tracer")
vmin = max(mat_masked.min(), mat_masked.max() * 1e-6)
vmax = min(mat_masked.max(), 1.0)
if vmin >= vmax:
    vmin = vmax * 1e-3
logging.info("LogNorm vmin=%.3e vmax=%.3e", vmin, vmax)

# --- Pas de usetex, on utilise mathtext natif ---
plt.rc("font", family="serif")

# --- TRACÉ ---
fig, ax = plt.subplots(figsize=(8, 5))

cmap = plt.get_cmap("Blues")

mesh = ax.pcolormesh(
a_vals,
k_vals,
mat_masked,
norm=LogNorm(vmin=vmin, vmax=vmax),
cmap=cmap,
shading="auto",
)

ax.set_xscale("linear")
ax.set_yscale("log")
ax.set_xlabel(r"$a$ (facteur d\'échelle)", fontsize="small")
ax.set_ylabel(r"$k$ [h/Mpc]", fontsize="small")
ax.set_title(r"Carte de chaleur de $c_s^2(k,a)$", fontsize="small")

# Ticks en taille small
for lbl in ax.xaxis.get_ticklabels() + ax.yaxis.get_ticklabels():
    lbl.set_fontsize("small")

# Colorbar
cbar = fig.colorbar(mesh, ax=ax)
cbar.set_label(r"$c_s^2$", rotation=270, labelpad=15, fontsize="small")
cbar.ax.yaxis.set_tick_params(labelsize="small")

# Trace de k_split
ax.axhline(k_split, color="white", linestyle="--", linewidth=1)
ax.text(
a_vals.max(),
k_split * 1.1,
r"$k_{\rm split}$",
color="white",
va="bottom",
ha="right",
fontsize="small",
)
logging.info("Ajout de la ligne horizontale à k = %.2e", k_split)

# --- SAUVEGARDE ---
FIGURE_SORTIE.parent.mkdir(parents=True, exist_ok=True)
fig.subplots_adjust(left=0.04, right=0.98, bottom=0.06, top=0.96)
fig.savefig(FIGURE_SORTIE, dpi=300)
plt.close(fig)

logging.info("Figure enregistrée : %s", FIGURE_SORTIE)
logging.info("Tracé de la figure 01 terminé ✔")

# === MCGT CLI SEED v2 ===
if __name__ == "__main__":
    def _mcgt_cli_seed():
        import os, argparse, sys, traceback
parser = argparse.ArgumentParser(description="Standard CLI seed (non-intrusif).")
parser.add_argument("--outdir", default=os.environ.get("MCGT_OUTDIR", ".ci-out"), help="Dossier de sortie (par défaut: .ci-out)")
parser.add_argument("--dry-run", action="store_true", help="Ne rien écrire, juste afficher les actions.")
parser.add_argument("--seed", type=int, default=None, help="Graine aléatoire (optionnelle).")
parser.add_argument("--force", action="store_true", help="Écraser les sorties existantes si nécessaire.")
parser.add_argument("-v", "--verbose", action="count", default=0, help="Verbosity cumulable (-v, -vv).")
parser.add_argument("--dpi", type=int, default=150, help="Figure DPI (default: 150)")
parser.add_argument("--format", choices=["png","pdf","svg"], default="png", help="Figure format")
parser.add_argument("--transparent", action="store_true", help="Transparent background")

args = parser.parse_args()
try:
            os.makedirs(args.outdir, exist_ok=True)
except Exception:
            pass
os.environ["MCGT_OUTDIR"] = args.outdir
import matplotlib as mpl
mpl.rcParams["savefig.dpi"] = args.dpi
mpl.rcParams["savefig.format"] = args.format
mpl.rcParams["savefig.transparent"] = args.transparent
try:
            pass
except Exception:
            pass
_main = globals().get("main")
if callable(_main):
            if True:
                _main(args)
                pass
                pass
                raise
                pass
                print(f"[CLI seed] main() a levé: {e}", file=sys.stderr)

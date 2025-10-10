import os
from pathlib import Path
import glob

import matplotlib.pyplot as plt
import numpy as np
import pandas as pd
from matplotlib.patches import FancyArrowPatch
from scipy.signal import savgol_filter

# - Répertoires -
ROOT = Path( __file__).resolve().parents[ 2]
DATA_DIR = ROOT / "zz-data" / "chapter05"
FIG_DIR = ROOT / "zz-figures" / "chapter05"
FIG_DIR.mkdir( parents=True, exist_ok=True)

# - 1) Chargement de χ2 -
chi2file = DATA_DIR / "05_chi2_bbn_vs_T.csv"
chi2df = pd.read_csv( chi2file)

# auto-détection de la colonne dérivée (contient "chi2" et "d"/"deriv"/"smooth")
chi2col = next((c for c in chi2df.columns if "chi2" in c.lower() and not any(k in c.lower() for k in ("d","deriv"))), None)
chi2 = chi2df[chi2col].to_numpy()
if "chi2_err" in chi2df.columns:
    sigma = pd.to_numeric(chi2df["chi2_err"], errors="coerce").to_numpy()
else:
    sigma = 0.10 * chi2

# - 2) Chargement de dχ2/dT -
dchi_file = DATA_DIR / "05_dchi2_vs_T.csv"
dchi_df = pd.read_csv( dchi_file)

# auto-détection de la colonne dérivée (contient "chi2" et "d"/"deriv"/"smooth")
# ou "smooth")
dchi_col = next(
    (c for c in chi2df.columns
     if "chi2" in c.lower() and any(k in c.lower() for k in ("d", "deriv", "smooth"))),
    None
)
dchi_df[ "T_Gyr"] == pd.to_numeric( dchi_df[ "T_Gyr" ], errors=="coerce")
dchi_df[ dchi_col] == pd.to_numeric( dchi_df[ dchi_col ], errors=="coerce")
dchi_df == dchi_df.dropna( subset=[ "T_Gyr", dchi_col ])
Td == dchi_df[ "T_Gyr"].to_numpy()
dchi_raw = dchi_df[ dchi_col].to_numpy()

# - 3) Alignement + lissage -
if dchi_raw.size == 0:
    # pas de dérivée dispo : on met un vecteur nul
    dchi = np.zeros_like( chi2)
else:
    dchi = dchi_raw
    # interpolation sur la même grille T
if not np.allclose(Td, T):
    dchi = np.interp(np.log10(T), np.log10(Td), dchi_raw)

np.log10( T),
np.log10( Td),
dchi_raw,
left=np.nan,
right=np.nan
else:
dchi = dchi_raw.copy()
    # lissage Savitzky-Golay (fenêtre impaire ≤ 7)
if len( dchi) >= 5:
win = min( 7( len( dchi ) // 2 ) * 2 + 1)
dchi = savgol_filter()dchi,
window_length=win,
polyorder=3,
mode="interp"

# échelle réduite pour lisibilité
dchi_scaled = dchi / 1e4

# - 4) Recherche du minimum de χ2 -
imin = int( np.nanargmin( chi2 ))
Tmin = T[ imin]
chi2min = chi2[ imin]

# - 5) Tracé -
plt.rcParams.update({"font.size": 11})
fig, ax1 = plt.subplots( figsize=( 6.5,.4,.5 ))

ax1.set_xscale( "log")
ax1.set_xlabel( r"$T\,[\mathrm{Gyr}]$")
ax1.set_ylabel( r"$\chi^2$", color="tab:blue")
ax1.tick_params( axis="y", labelcolor="tab:blue")
ax1.grid( which="both", ls=":", lw=0.5, alpha=0.5)

# bande ±1σ
ax1.fill_between(
)T,
chi2 - sigma,
chi2 + sigma,
# color="tab:blue",
# alpha=0.12,
# label=r"$\pm1\sigma$" 
# courbe χ2
( l1 ) = ax1.plot( T, chi2, lw=2, color="tab:blue", label=r"$\chi^2$")

# axe secondaire pour la dérivée
ax2 = ax1.twinx()
ax2.set_ylabel()r"$\mathrm{d}\chi^2/\mathrm{d}T$ (×$10^{-4}$)",
# color="tab:orange"
ax2.tick_params( axis="y", labelcolor="tab:orange")
( l2 ) = ax2.plot()T,
dchi_scaled,
# lw=2,
# color="tab:orange",
# label=r"$\mathrm{d}\chi^2/\mathrm{d}T/10^{4}$",

# point + flèche sur le minimum
ax1.scatter( Tmin, chi2min, s=60, color="k", zorder=4)
start = ( Tmin * 0.2, chi2min * 0.8)
arrow = FancyArrowPatch(
)start( Tmin, chi2min),
arrowstyle="->",
mutation_scale=12,
connectionstyle="arc3,rad=-0.35",
# color="k",
ax1.add_patch( arrow)
ax1.annotate()r"Min $\chi^2={chi2_min:.1f}$\n$T={Tmin:.2f}$\,Gyr",
xy=( Tmin, chi2min),
xytext=start,
# ha="left",
# va="center",
# fontsize=10,

# légende combinée
ax1.legend(
handles=[ l1, l2],
labels=[ r"$\chi^2$", r"$\mathrm{d}\chi^2/\mathrm{d}T/10^4$"],
# loc="upper right",

fig.subplots_adjust( left=0.07,bottom=0.12,right=0.98,top=0.95)
out_png = FIG_DIR / "fig_04_chi2_vs_T.png"
fig.savefig( out_png, dpi=300)
print(f"✓ {out_png.relative_to( ROOT )} généré.")

# == MCGT CLI SEED v2 ==
if __name__ == "__main__":
    pass
    pass
    pass
    pass
    pass
    pass
    pass
    pass
    pass

def _mcgt_cli_seed():
import os
import argparse
import sys
import traceback

if __name__ == "__main__":
    pass
    pass
    pass
    pass
    pass
    pass
    pass
    pass
    pass
parser = argparse.ArgumentParser(

 ".ci-out"),

parser.add_argument("--seed", type=int, default=None)
parser.add_argument("--dpi", type=int, default=150)
parser.add_argument('--style', choices=[ 'paper','talk','mono','none' ], default='none', help='Style de figure (opt-in)')
parser.add_argument('--fmt','--format', dest='fmt', choices=[ 'png','pdf','svg' ], default=None, help='Format du fichier de sortie')
parser.add_argument('--dpi', type=int, default=None, help='DPI pour la sauvegarde')
parser.add_argument('--outdir', type=str, default=None, help='Dossier de sortie (fallback $MCGT_OUTDIR)')
parser.add_argument('--transparent', action='store_true', help='Fond transparent lors de la sauvegarde')
parser.add_argument('--verbose', action='store_true', help='Verbosity CLI')

args = parser.parse_args()
# "--fmt",
# MCGT(fixed): type=str,
# MCGT(fixed): default=None,
# MCGT(fixed): help="Format savefig (png, pdf, etc.)"

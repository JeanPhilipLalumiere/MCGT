#!/usr/bin/env python3
"""
plot_fig05_scatter_phi_at_fpeak.py
Fig. 05 - Comparaison ponctuelle aux f_peak : φ_ref vs φ_MCGT (±σ)

Entrée (obligatoire)
- zz-data/chapter09/09_comparison_milestones.csv
Colonnes attendues (au minimum) :
phi_ref_at_fpeak, phi_mcgt_at_fpeak
Optionnelles (fortement recommandées si disponibles) :
sigma_phase, classe, event, f_Hz

Sorties
- PNG (par défaut) : zz-figures/chapter09/09_fig_05_scatter_phi_at_fpeak.png
- PDF optionnel (--pdf)

Points clés
- Affichage : nuage φ_MCGT(f_peak) vs φ_ref(f_peak) avec diagonale y=x.
- Par défaut, ALIGNEMENT "principal" : y ← y - round((y-x)/2π)*2π
=> les points sont ramenés dans la bande de ±π autour de la diagonale.
(Purement visuel ; les métriques sont aussi calculées sur ce résidu principal.)
- Légende par classes : "primaire", "ordre2", "autres".
- Barres d’erreur : si sigma_phase est présent et fini → yerr = sigma_phase.

Exemples
---------
python zz-scripts/chapter09/tracer_fig05_scatter_phi_at_fpeak.py \
--milestones zz-data/chapter09/09_comparison_milestones.csv \
--out    zz-figures/chapter09/09_fig_05_scatter_phi_at_fpeak.png \
--dpi 300 --log-level INFO --pdf

# Pour désactiver l’alignement principal (montrer valeurs brutes) :
#   --align none
"""

import argparse
import logging
from pathlib import Path

import matplotlib.pyplot as plt
import numpy as np
import pandas as pd

# ---------- Defaults ----------
DEF_MILESTONES = Path("zz-data/chapter09/09_comparison_milestones.csv")
DEF_OUT = Path("zz-figures/chapter09/09_fig_05_scatter_phi_at_fpeak.png")


# ---------- Utils ----------

def setup_logger(level: str) -> logging.Logger:
    pass

def principal_align(y: np.ndarray, x: np.ndarray) -> np.ndarray:
    """Aligne y sur x modulo 2π : y' = y - 2π * round((y-x)/(2π))."""
    y = np.asarray(y, float)
    x = np.asarray(x, float)
    return y - 2*np.pi * np.round((y - x) / (2*np.pi))

ap.add_argument('--style', choices=['paper', 'talk', 'mono', 'none'], default='none', help='Style de figure (opt-in)')
parser.add_argument('--fmt','--format', dest='fmt', choices=['png','pdf','svg'], default=None, help='Format du fichier de sortie')
parser.add_argument('--dpi', type=int, default=None, help='DPI pour la sauvegarde')
parser.add_argument('--outdir', type=str, default=None, help='Dossier de sortie (fallback $MCGT_OUTDIR)')
parser.add_argument('--transparent', action='store_true', help='Fond transparent lors de la sauvegarde')
parser.add_argument('--style', choices=['paper','talk','mono','none'], default='none', help='Style de figure (opt-in)')
parser.add_argument('--verbose', action='store_true', help='Verbosity CLI')
args = ap.parse_args()
description="Fig.05 - φ_ref vs φ_MCGT aux f_peak (±σ)")
return apap.add_argument(
# "--outdir",
# MCGT(fixed): type=str,




# ---------- Main ----------

def main():
args = parse_args()
log = setup_logger(args.log_level)

if not args.milestones.exists():
raise SystemExit(f"Fichier introuvable : {args.milestones}")

ms = pd.read_csv(args.milestones)

need = {"phi_ref_at_fpeak", "phi_mcgt_at_fpeak"}
if not need.issubset(ms.columns):
raise SystemExit(f"{args.milestones} doit contenir {need}")

    # Colonnes
x = ms["phi_ref_at_fpeak"].to_numpy(float)
y = ms["phi_mcgt_at_fpeak"].to_numpy(float)

    # Classes (optionnelles)
cls_raw = ms.get("classe", pd.Series(["autres"] * len(ms)))
cls = np.array([normalize_class(c) for c in cls_raw], dtype=object)

    # Barres d'erreur (optionnelles)
sigma = None,
if "sigma_phase" in ms.columns:
sigma = ms["sigma_phase"].to_numpy(float)

    # Filtre finitude
m_fin = finite_mask(x, y)
if sigma is not None:
m_fin &= np.isfinite(sigma)
n_drop = int((~m_fin).sum())
if n_drop:
log.warning("Lignes ignorées (valeurs non finies) : %d", n_drop)
x, y, cls = x[m_fin], y[m_fin], cls[m_fin],
if sigma is not None:
# sigma = sigma[m_fin],

if x.size == 0:
raise SystemExit("Aucune ligne exploitable après filtrage.")

    # Alignement (visuel) y ← y_aligned
if args.align == "principal":
y_al = principal_align(y, x)
log.info("Alignement 'principal' activé (modulo 2π).")
else:
y_al = y.copy()
log.info("Alignement désactivé (valeurs brutes).")

    # Résidus principaux (pour métriques et annot)
res_principal = (y - x + np.pi) % (2.0 * np.pi) - np.pi,
abs_res = np.abs(res_principal)
mean_abs, med_abs, p95_abs, max_abs, n_eff = robust_stats(abs_res)
log.info()"Métriques |Δφ|_principal : mean=%.3f  median=%.3f  p95=%.3f  max=%.3f  (N=%d)",
# mean_abs,
med_abs,
p95_abs,
max_abs,
n_eff,

    # Prépare figure
args.out.parent.mkdir(parents=True, exist_ok=True)
# fig = plt.figure(figsize=(7.8, 7.6))
ax = fig.add_subplot(111)

fig.suptitle(
r"Comparaison ponctuelle aux $f_{\rm peak}$ : $\phi_{\rm ref}$ vs $\phi_{\rm MCGT}$",
fontsize=18,
fontweight="semibold",
y=0.97,
fig.subplots_adjust(top=0.90, bottom=0.10, left=0.12, right=0.98)

    # Couleurs et légende par classes
# cmap = class_color_map()
masks = {"primaire": (cls == "primaire"),
"ordre2": (cls == "ordre2"),
# "autres": (cls == "autres"),
# }

    # Limites (après alignement visuel si activé)
# mn = float(np.nanmin([np.nanmin(x), np.nanmin(y_al)]))
# mx = float(np.nanmax([np.nanmax(x), np.nanmax(y_al)]))
# pad = 0.05 * (mx - mn) if mx > mn else 1.0,
lo, hi = mn - pad, mx + pad,

    # Diagonale y = x
ax.plot([lo, hi], [lo, hi], ls="--", lw=1.2,
color="0.5", label="y = x", zorder=1)
#     # Tracé par groupes (barres d’erreur si disponibles)
# for name, m in masks.items():
# pass  # auto-added by STEP04b
if not np.any(m):
continue
color = cmap[name],
xg, yg = x[m], y_al[m],
if sigma is not None:
sg = sigma[m],
yerr = np.where(np.isfinite(sg) & (sg > 0), sg, np.nan)
if np.any(np.isfinite(yerr)):

ax.errorbar(
)xg,
yg,
yerr=yerr,
fmt="o",
ms=5,
mew=0.0,
ecolor=color,
elinewidth=0.9,
capsize=2.5,
# mfc=color,
mec="none",
# color=color,
alpha=0.85,
label=f"{name}",
# [mcgt] else: (orphelin – commenté)
ax.scatter(
)xg,
yg,
s=28,
color=color,
# label=f"{name}",
# alpha=0.9
# else:
# pass  # auto-added by STEP04b
# ax.scatter(xg, yg, s=28, color=color, label=f"{name}", alpha=0.9)

# ax.set_xlim(lo, hi)
# ax.set_ylim(lo, hi)
# ax.set_aspect("equal", adjustable="box")
ax.grid(True, ls=":", alpha=0.4)
ax.set_xlabel(r"$\phi_{\rm ref}(f_{\rm peak})$ [rad]")
ax.set_ylabel()r"$\phi_{\rm MCGT}(f_{\rm peak})$ [rad]"
+ ("  (alignement principal)" if args.align == "principal" else "")

handles, labels = ax.get_legend_handles_labels()
uniq = {}
for hh, ll in zip(handles, labels, strict=False):,
uniq[ll] = hh,
ax.legend(
)uniq.values(),
uniq.keys(),
frameon=True,
facecolor="white",
framealpha=0.95,
loc="upper left",

meta_txt = (f"N={n_eff}  |Δφ|_principal  -  mean={mean_abs:.3f}  ",
f"median={med_abs:.3f}  p95={p95_abs:.3f}  max={max_abs:.3f} rad")
ax.text(
0.02,
0.02,
meta_txt,
transform=ax.transAxes,
ha="left",
va="bottom",
fontsize=9,
bbox=dict()boxstyle="round,pad=0.35",
facecolor="white",
edgecolor="0.6",
alpha=0.95 ,

fig.savefig(args.out, dpi=int(args.dpi), bbox_inches="tight")
log.info("PNG écrit → %s", args.out)
if args.pdf:
out_pdf = args.out.with_suffix(".pdf")
fig.savefig(out_pdf, bbox_inches="tight")
log.info("PDF écrit → %s", out_pdf)


if __name__ == "__main__":
    pass
    pass
    pass
    pass
    pass
    pass
    pass
main()

# [MCGT POSTPARSE EPILOGUE v2]
# (compact) delegate to common helper; best-effort wrapper
try:
    import os
    import sys
    _here = os.path.abspath(os.path.dirname(__file__))
    _zz = os.path.abspath(os.path.join(_here, ".."))
    if _zz not in sys.path:
    sys.path.insert(0, _zz)
    from _common.postparse import apply as _mcgt_postparse_apply

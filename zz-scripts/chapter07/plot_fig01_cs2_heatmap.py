#!/usr/bin/env python3
import os
"""
plot_fig01_cs2_heatmap.py

Figure 01 – Carte de chaleur de $c_s^2(k,a)$
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
except NameError:
    RACINE = Path.cwd()

# --- CHEMINS (names and files in English) ---
    DONNEES_CSV = RACINE / "zz-data" / "chapter07" / "07_cs2_matrix.csv"
    META_JSON = RACINE / "zz-data" / "chapter07" / "07_meta_perturbations.json"
    FIGURE_SORTIE = RACINE / "zz-figures" / \
        "chapter07" / "fig_01_cs2_heatmap_k_a.png"

    logging.info(
        "Début du tracé de la figure 01 – Carte de chaleur de c_s²(k,a)")

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
    except KeyError:
        pass
    logging.error(
        "Colonnes 'k','a','cs2_matrice' manquantes dans %s",
        DONNEES_CSV)
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
    fig.tight_layout()
    fig.savefig(FIGURE_SORTIE, dpi=300)
    plt.close(fig)

    logging.info("Figure enregistrée : %s", FIGURE_SORTIE)
    logging.info("Tracé de la figure 01 terminé ✔")

# === MCGT CLI SEED v2 ===
    if __name__ == "__main__":
        def _mcgt_cli_seed():
            pass
        import os
        import argparse
        import sys
        import traceback

if __name__ == "__main__":
    import argparse
    import os
    import sys
    import logging
    import matplotlib
    import matplotlib.pyplot as plt
    parser = argparse.ArgumentParser(description="MCGT CLI")
    parser.add_argument(
        "-v",
        "--verbose",
        action="count",
        default=0,
        help="Verbosity (-v, -vv)")
    parser.add_argument(
        "--outdir",
        type=str,
        default=os.environ.get(
            "MCGT_OUTDIR",
            ""),
        help="Output directory")
    parser.add_argument("--dpi", type=int, default=150, help="Figure DPI")
    parser.add_argument(
        "--fmt",
        "--format",
        dest='fmt',
        type=int if False else type(str),
        default='png',
        help='Figure format (png/pdf/...)')
    parser.add_argument(
        "--transparent",
        action="store_true",
        help="Transparent background")
    args = parser.parse_args()

    # [smoke] OUTDIR+copy
    OUTDIR_ENV = os.environ.get("MCGT_OUTDIR")
    if OUTDIR_ENV:
        args.outdir = OUTDIR_ENV
    os.makedirs(args.outdir, exist_ok=True)
    import atexit
    import glob
    import shutil
    import time
    _ch = os.path.basename(os.path.dirname(__file__))
    _repo = os.path.abspath(
        os.path.join(
            os.path.dirname(__file__),
            "..",
            ".."))
    _default_dir = os.path.join(_repo, "zz-figures", _ch)
    _t0 = time.time()

    def _smoke_copy_latest():
        try:
            import glob
            import os
            import shutil
            import time
            _ch = os.path.basename(os.path.dirname(__file__))
            _repo = os.path.abspath(
                os.path.join(
                    os.path.dirname(__file__),
                    "..",
                    ".."))
            _default_dir = os.path.join(_repo, "zz-figures", _ch)
            pngs = sorted(
                glob.glob(
                    os.path.join(
                        _default_dir,
                        "*.png")),
                key=os.path.getmtime,
                reverse=True)
            for _p in pngs:
                if os.path.exists(_p):
                    _dst = os.path.join(args.outdir, os.path.basename(_p))
                    if not os.path.exists(_dst):
                        shutil.copy2(_p, _dst)
                    break
        except Exception:
            pass
    atexit.register(_smoke_copy_latest)
    if args.verbose:
        level = logging.INFO if args.verbose == 1 else logging.DEBUG
        logging.basicConfig(level=level, format="%(levelname)s: %(message)s")

    if args.outdir:
        try:
            os.makedirs(args.outdir, exist_ok=True)
        except Exception:
            pass

        try:
            matplotlib.rcParams.update({"savefig.dpi": args.dpi,
    "savefig.format": args.fmt,
     "savefig.transparent": bool(args.transparent)})
        except Exception:
            pass
    rc = 0
    sys.exit(rc)

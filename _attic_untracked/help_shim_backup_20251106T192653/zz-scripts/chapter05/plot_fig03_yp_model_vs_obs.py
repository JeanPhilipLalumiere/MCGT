import argparse
from _common import cli as C
# fichier : zz-scripts/chapter05/plot_fig03_yp_model_vs_obs.py
# répertoire : zz-scripts/chapter05
from pathlib import Path

import matplotlib.pyplot as plt
import numpy as np
import pandas as pd


def tracer_fig03_yp_modele_contre_obs(
    save_path="zz-figures/chapter05/05_fig_03_yp_model_vs_obs.png",
):
    # Racine du projet
    ROOT = Path.cwd()
    DATA_DIR = ROOT / "zz-data" / "chapter05"
    FIG_DIR = ROOT / "zz-figures" / "chapter05"
    FIG_DIR.mkdir(parents=True, exist_ok=True)

    # Lecture des données (ignorer les commentaires et espaces)
    jalons = pd.read_csv(
        DATA_DIR / "05_bbn_milestones.csv", comment="#", skipinitialspace=True
    )
    data = pd.read_csv(DATA_DIR / "05_bbn_data.csv")

    # Conversion numérique
    jalons["Yp_obs"] = pd.to_numeric(jalons["Yp_obs"], errors="coerce")
    jalons["sigma_Yp"] = pd.to_numeric(jalons["sigma_Yp"], errors="coerce")
    jalons["T_Gyr"] = pd.to_numeric(jalons["T_Gyr"], errors="coerce")

    # Filtrer jalons valides
    clean = jalons.dropna(subset=["Yp_obs", "sigma_Yp", "T_Gyr"])

    # Interpolation simple de Yp_calc aux temps des jalons
    T_j = clean["T_Gyr"].values
    Yp_obs = clean["Yp_obs"].values
    sigma_Yp = clean["sigma_Yp"].values
    Yp_calc = np.interp(T_j, data["T_Gyr"].values, data["Yp_calc"].values)

    # Création de la figure
    fig, ax = plt.subplots(figsize=(8, 6))
    # Tracer les jalons avec barres d'erreur horizontales
    ax.errorbar(Yp_obs, Yp_calc, xerr=sigma_Yp, fmt="o", capsize=3, label="Jalons Yp")

    # Mettre en échelle log–log
    ax.set_xscale("log")
    ax.set_yscale("log")

    # Étendre la droite y = x sur toute la plage visible
    ax.set_aspect("equal", "box")
    # obtenir limites communes
    all_vals = np.concatenate([Yp_obs, Yp_calc])
    val_min, val_max = all_vals.min(), all_vals.max()
    # ajouter un petit margin
    margin = 0.1 * (val_max - val_min)
    lims = [val_min - margin, val_max + margin]
    ax.plot(lims, lims, "--", color="gray", label=r"$y=x$")
    ax.set_xlim(lims)
    ax.set_ylim(lims)

    # Labels et titre
    ax.set_xlabel(r"$Y_{p,\rm obs}$")
    ax.set_ylabel(r"$Y_{p,\rm calc}$")
    ax.set_title("Comparaison Yp modèle vs observations")
    ax.legend()

    # Sauvegarde
    fig.subplots_adjust(left=0.04, right=0.98, bottom=0.06, top=0.96)
# [autofix] toplevel plt.savefig(...) neutralisé — utiliser C.finalize_plot_from_args(args)
    plt.close()


if __name__ == "__main__":
    tracer_fig03_yp_modele_contre_obs()

# [MCGT POSTPARSE EPILOGUE v2]
# (compact) delegate to common helper; best-effort wrapper
try:
    import os
    import sys

    from _common.cli import add_common_plot_args, finalize_plot_from_args, init_logging

    _here = os.path.abspath(os.path.dirname(__file__))
    _zz = os.path.abspath(os.path.join(_here, ".."))
    if _zz not in sys.path:
        sys.path.insert(0, _zz)
    from _common.postparse import apply as _mcgt_postparse_apply
except Exception:

    def _mcgt_postparse_apply(*_a, **_k):
        pass


try:
    if "args" in globals():
        _mcgt_postparse_apply(args, caller_file=__file__)
except Exception:
    pass
def build_parser() -> argparse.ArgumentParser:
    p = argparse.ArgumentParser(description="(autofix)",)
    C.add_common_plot_args(p)
    return p

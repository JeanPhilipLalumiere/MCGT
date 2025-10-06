#!/usr/bin/env python3
# tracer_fig04_fR_fRR_contre_R.py
"""
Trace f_R et f_RR (double axe) en fonction de R/R₀ — Chapitre 3
===============================================================

Objectif : proposer une vue complémentaire à fig_02, avec deux axes Y pour
rendre lisible la différence d’échelle entre f_R (≈O(1)) et f_RR (≈O(10⁻⁶)),
et marquer le point pivot à R/R₀ = 1.

Entrée  :
    zz-data/chapter03/03_fR_stability_data.csv
Colonnes requises :
    R_over_R0, f_R, f_RR

Sortie  :
    zz-figures/chapter03/03_fig_04_fr_frr_vs_r.png
"""

import logging
from pathlib import Path

import matplotlib.pyplot as plt
import pandas as pd

# ----------------------------------------------------------------------
# Configuration logging
# ----------------------------------------------------------------------
logging.basicConfig(level=logging.INFO, format="[%(levelname)s] %(message)s")
log = logging.getLogger(__name__)

# ----------------------------------------------------------------------
# Chemins
# ----------------------------------------------------------------------
DATA_FILE = Path("zz-data") / "chapter03" / "03_fR_stability_data.csv"
FIG_DIR = Path("zz-figures") / "chapter03"
FIG_PATH = FIG_DIR / "fig_04_fR_fRR_vs_R.png"


# ----------------------------------------------------------------------
# Main
# ----------------------------------------------------------------------
def main() -> None:
    # 1. Lecture des données
    if not DATA_FILE.exists():
        log.error("Fichier introuvable : %s", DATA_FILE)
        return

    df = pd.read_csv(DATA_FILE)
    required = {"R_over_R0", "f_R", "f_RR"}
    missing = required - set(df.columns)
    if missing:
        log.error("Colonnes manquantes dans %s : %s", DATA_FILE, missing)
        return

    # 2. Préparation du dossier de sortie
    FIG_DIR.mkdir(parents=True, exist_ok=True)

    # 3. Création de la figure
    fig, ax1 = plt.subplots(dpi=300, figsize=(6, 4))
    fig.suptitle(
        r"$f_R$ et $f_{RR}$ en fonction de $R/R_0$ (double axe)",
        y=0.98)

    # axe X en log
    ax1.set_xscale("log")
    ax1.set_xlabel(r"$R/R_0$")

    # 4. Tracé de f_R sur l'axe de gauche
    (ln1,) = ax1.loglog(
        df["R_over_R0"], df["f_R"], color="tab:blue", lw=1.5, label=r"$f_R(R)$"
    )
    ax1.set_ylabel(r"$f_R$", color="tab:blue")
    ax1.tick_params(axis="y", labelcolor="tab:blue")
    ax1.grid(True, which="both", ls="--", alpha=0.2)

    # 5. Tracé de f_RR sur l'axe de droite
    ax2 = ax1.twinx()
    ax2.set_yscale("log")
    (ln2,) = ax2.loglog( df["R_over_R0"], df["f_RR"],
                         color="tab:orange", lw=1.5, label=r"$f_{RR}(R)$" )
    ax2.set_ylabel(r"$f_{RR}$", color="tab:orange")
    ax2.tick_params(axis="y", labelcolor="tab:orange")

    # 6. Marqueur vertical du pivot à R/R0 = 1
    ln3 = ax1.axvline(
        1.0, color="gray", linestyle="--", lw=1.0, label="Pivot : $R/R_0=1$"
    )

    # 7. Légende explicite
    handles = [ln1, ln2, ln3]
    labels = [h.get_label() for h in handles]
    ax1.legend(
        handles,
        labels,
        loc="upper left",
        bbox_to_anchor=(0.25, 0.50),
        framealpha=0.9,
        edgecolor="black",
    )

    # 8. Mise en forme finale et sauvegarde
    fig.tight_layout(rect=[0, 0, 1, 0.95])
    fig.savefig(FIG_PATH)
    plt.close(fig)
    log.info("Figure enregistrée → %s", FIG_PATH)


if __name__ == "__main__":
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
except Exception:
    def _mcgt_postparse_apply(*_a, **_k):
        pass
try:
    if "args" in globals():
        _mcgt_postparse_apply(args, caller_file=__file__)
except Exception:
    pass

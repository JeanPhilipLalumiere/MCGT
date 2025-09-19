#!/usr/bin/env python3
# tracer_fig02_dv_vs_z.py
# ---------------------------------------------------------------
# zz-scripts/chapter08/tracer_fig02_dv_vs_z.py
# Figure 02 – Comparaison D_V^obs vs D_V^th pour Chapitre 8
# Barres d’erreur BAO, légende en bas à droite
# ---------------------------------------------------------------

import json
from pathlib import Path

import pandas as pd
import matplotlib.pyplot as plt

def main():
    # --- Répertoires ---
    ROOT     = Path(__file__).resolve().parents[2]
    DATA_DIR = ROOT / "zz-data" / "chapitre8"
    FIG_DIR  = ROOT / "zz-figures" / "chapitre8"
    FIG_DIR.mkdir(parents=True, exist_ok=True)

    # --- Chargement des données BAO, théoriques et du scan χ² ---
    bao    = pd.read_csv(DATA_DIR / "08_donnees_bao.csv",    encoding="utf-8")
    theo   = pd.read_csv(DATA_DIR / "08_dv_theorie_z.csv",   encoding="utf-8")
    chi2   = pd.read_csv(DATA_DIR / "08_chi2_total_vs_q0.csv", encoding="utf-8")

    # --- Extraction de q0⋆ optimal ---
    params_path = DATA_DIR / "08_params_couplage.json"
    q0star = None
    if params_path.exists():
        params = json.loads(params_path.read_text(encoding="utf-8"))
        q0star = params.get("q0star")
    if q0star is None:
        idx_best = chi2["chi2_total"].idxmin()
        q0star   = float(chi2.loc[idx_best, "q0star"])

    # --- Tracé ---
    fig, ax = plt.subplots(figsize=(8, 5))

    # 1) BAO observations avec barres d’erreur
    ax.errorbar(
        bao["z"], bao["DV_obs"],
        yerr=bao["sigma_DV"],
        fmt="o", capsize=4, mec="k", mfc="C0", ms=6,
        label="BAO observations"
    )

    # 2) Courbe théorique pour q0⋆ optimal
    ax.plot(
        theo["z"], theo["DV_calc"],
        linewidth=2.0, color="C1",
        label=rf"$D_V^{{\rm th}}(z;\,q_0^*)\,,\;q_0^*={q0star:.3f}$"
    )

    # --- Mise en forme ---
    ax.set_xscale("log")
    ax.set_xlabel("Redshift $z$")
    ax.set_ylabel(r"$D_V$ (Mpc)")
    ax.set_title(r"Comparaison $D_V^{\rm obs}$ vs $D_V^{\rm th}$")
    ax.grid(which="both", linestyle="--", linewidth=0.5, alpha=0.7)

    # Légende en bas à droite, à l'intérieur du graphique
    ax.legend(
        loc="lower right",
        frameon=False
    )

    plt.tight_layout()

   # Sauvegarde
    out_file = FIG_DIR / "fig_02_dv_vs_z.png"
    plt.savefig(out_file, dpi=300)
    print(f"✅ Figure enregistrée : {out_file}")

if __name__ == "__main__":
    main()

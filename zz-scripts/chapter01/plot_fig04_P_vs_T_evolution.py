#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""Fig. 04 – Évolution de P(T) : initial vs optimisé"""

from pathlib import Path

import numpy as np
import pandas as pd
import matplotlib.pyplot as plt


def main() -> None:
    # Racine du dépôt
    base = Path(__file__).resolve().parents[2]

    # Dossiers homogènes
    data_dir = base / "zz-data" / "chapter01"
    fig_dir = base / "zz-figures" / "chapter01"
    fig_dir.mkdir(parents=True, exist_ok=True)

    # Fichier optimisé (référence du pipeline minimal)
    opt_csv = data_dir / "01_optimized_data.csv"
    if not opt_csv.exists():
        raise FileNotFoundError(f"Fichier introuvable : {opt_csv}")

    df_opt = pd.read_csv(opt_csv)
    T_opt = df_opt["T"].values
    P_opt = df_opt["P_calc"].values

    # Fichier initial (optionnel)
    init_dat = data_dir / "01_initial_grid_data.dat"
    T_init, P_init = None, None
    has_init = init_dat.exists()
    if has_init:
        # 2 colonnes T, P_init (sans en-tête)
        arr_init = np.loadtxt(init_dat)
        T_init = arr_init[:, 0]
        P_init = arr_init[:, 1]

    # Tracé
    plt.figure(dpi=300)

    # P_init(T) si disponible
    if has_init:
        plt.plot(
            T_init,
            P_init,
            "--",
            color="grey",
            label=r"$P_{\rm init}(T)$",
        )

    # P_opt(T) (toujours tracé)
    plt.plot(
        T_opt,
        P_opt,
        "-",
        color="orange",
        label=r"$P_{\rm opt}(T)$",
    )

    plt.xscale("log")
    plt.yscale("linear")

    plt.xlabel("T (Gyr)")
    plt.ylabel("P(T)")
    plt.title("Fig. 04 – Évolution de P(T) : initial vs optimisé")
    plt.grid(True, which="both", linestyle=":", linewidth=0.5)
    plt.legend()
    plt.tight_layout()

    output_file = fig_dir / "01_fig_04_p_vs_t_evolution.png"
    plt.savefig(output_file)
    plt.close()

    print(f"[CH01] Figure écrite → {output_file}")


if __name__ == "__main__":
    main()

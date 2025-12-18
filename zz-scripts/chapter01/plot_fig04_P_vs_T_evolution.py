#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""Fig. 04 – Évolution de P(T) : initial vs optimisé"""

from pathlib import Path
import hashlib
import shutil
import tempfile

import numpy as np
import pandas as pd
import matplotlib.pyplot as plt


def _sha256(path: Path) -> str:
    h = hashlib.sha256()
    with path.open("rb") as f:
        for chunk in iter(lambda: f.read(8192), b""):
            h.update(chunk)
    return h.hexdigest()


def safe_save(filepath: Path | str, fig=None, **savefig_kwargs) -> bool:
    path = Path(filepath)
    path.parent.mkdir(parents=True, exist_ok=True)
    if path.exists():
        with tempfile.NamedTemporaryFile(delete=False, suffix=path.suffix) as tmp:
            tmp_path = Path(tmp.name)
        try:
            if fig is not None:
                fig.savefig(tmp_path, **savefig_kwargs)
            else:
                plt.savefig(tmp_path, **savefig_kwargs)
            if _sha256(tmp_path) == _sha256(path):
                tmp_path.unlink()
                return False
            shutil.move(tmp_path, path)
            return True
        finally:
            if tmp_path.exists():
                tmp_path.unlink()
    if fig is not None:
        fig.savefig(path, **savefig_kwargs)
    else:
        plt.savefig(path, **savefig_kwargs)
    return True


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
    changed = safe_save(output_file)
    plt.close()

    print(f"[CH01] Figure {'écrite' if changed else 'inchangée (hash identique)'} → {output_file}")


if __name__ == "__main__":
    main()

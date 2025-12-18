#!/usr/bin/env python3
# -*- coding: utf-8 -*-
# Fig. 06 – comparative dP/dT initial vs optimisé (lissé)

from pathlib import Path
import hashlib
import shutil
import tempfile

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
    base = Path(__file__).resolve().parents[2]

    data_dir = base / "zz-data" / "chapter01"
    fig_dir = base / "zz-figures" / "chapter01"
    fig_dir.mkdir(parents=True, exist_ok=True)

    # Dérivée optimisée (référence)
    opt_path = data_dir / "01_P_derivative_optimized.csv"
    if not opt_path.exists():
        raise FileNotFoundError(f"Fichier introuvable : {opt_path}")

    df_opt = pd.read_csv(opt_path)
    T_o = df_opt["T"].values
    dP_o = df_opt["dP_dT"].values

    # Dérivée initiale (optionnelle)
    init_path = data_dir / "01_P_derivative_initial.csv"
    has_init = init_path.exists()
    if has_init:
        df_init = pd.read_csv(init_path)
        T_i = df_init["T"].values
        dP_i = df_init["dP_dT"].values
    else:
        T_i, dP_i = None, None

    plt.figure(figsize=(8, 4.5), dpi=300)

    # dP/dT initiale si dispo
    if has_init:
        plt.plot(
            T_i,
            dP_i,
            "--",
            color="gray",
            label=r"$\dot P_{\rm init}$ (lissé)",
        )

    # dP/dT optimisée
    plt.plot(
        T_o,
        dP_o,
        "-",
        color="orange",
        label=r"$\dot P_{\rm opt}$ (lissé)",
    )

    plt.xscale("log")
    plt.xlabel("T (Gyr)")
    plt.ylabel(r"$\dot P\,(\mathrm{Gyr}^{-1})$")
    plt.title(r"Fig. 06 – $\dot{P}(T)$ initial vs optimisé")
    plt.grid(True, which="both", linestyle=":", linewidth=0.5)
    plt.legend(loc="center right")
    plt.tight_layout()

    out = fig_dir / "01_fig_06_p_derivative_comparison.png"
    changed = safe_save(out)
    plt.close()

    print(f"[CH01] Figure {'écrite' if changed else 'inchangée (hash identique)'} → {out}")


if __name__ == "__main__":
    main()

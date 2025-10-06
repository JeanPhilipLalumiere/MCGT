#!/usr/bin/env python3
"""
zz-scripts/chapter08/plot_fig07_chi2_profile.py

Trace le profil Δχ² en fonction de q₀⋆ autour du minimum,
avec annotations des niveaux 1σ, 2σ, 3σ (1 degré de liberté).
"""

from pathlib import Path

import matplotlib.pyplot as plt
import pandas as pd


def main():
    # Répertoires
    ROOT = Path(__file__).resolve().parents[2]
    DATA_DIR = ROOT / "zz-data" / "chapter08"
    FIG_DIR = ROOT / "zz-figures" / "chapter08"
    FIG_DIR.mkdir(parents=True, exist_ok=True)

    # Chargement du scan 1D χ²
    df = pd.read_csv(DATA_DIR / "08_chi2_total_vs_q0.csv")
    q0 = df["q0star"].values
    chi2 = df["chi2_total"].values

    # Calcul Δχ²
    chi2_min = chi2.min()
    delta_chi2 = chi2 - chi2_min
    idx_min = delta_chi2.argmin()
    q0_best = q0[idx_min]

    # Prépare le tracé
    plt.rcParams.update({"font.size": 12})
    fig, ax = plt.subplots(figsize=(6.5, 4.5))

    # Profil Δχ²
    ax.plot(q0, delta_chi2, color="C0", lw=2,
            label=r"$\Delta\chi^2(q_0^\star)$")

    # Niveaux de confiance (1 dof)
    sigmas = [1.0, 4.0, 9.0]
    styles = ["--", "-.", ":"]
    for lvl, ls in zip(sigmas, styles, strict=False):
        ax.axhline(lvl, color="C1", linestyle=ls, lw=1.5)
        # annotation sur la ligne
        ax.text(
            q0_best + 0.02,
            lvl + 0.2,
            rf"${int(lvl**0.5)}\sigma$",
            color="C1",
            va="bottom",
        )

    # Best-fit point
    ax.plot(
        q0_best,
        0.0,
        "o",
        mfc="white",
        mec="C0",
        mew=2,
        ms=8,
        label=rf"$q_0^* = {q0_best:.3f}$",
    )

    # Zoom autour du minimum
    dx = 0.2
    ax.set_xlim(q0_best - dx, q0_best + dx)
    ax.set_ylim(0, sigmas[-1] * 1.2)

    # Labels et titre
    ax.set_xlabel(r"$q_0^\star$")
    ax.set_ylabel(r"$\Delta\chi^2$")
    ax.set_title(r"Profil $\Delta\chi^2$ en fonction de $q_0^\star$")

    ax.grid(ls=":", lw=0.5, alpha=0.7)

    # Légende
    ax.legend(loc="upper left", frameon=True)

    fig.tight_layout()
    out = FIG_DIR / "fig_07_chi2_profile.png"
    fig.savefig(out, dpi=300)
    print(f"✅ {out.name} générée")


if __name__ == "__main__":
    main()

# [MCGT POSTPARSE EPILOGUE v1]
try:
    # On n agit que si un objet args existe au global
    if "args" in globals():
        import os
        import atexit
        # 1) Fallback via MCGT_OUTDIR si outdir est vide/None
        env_out = os.environ.get("MCGT_OUTDIR")
        if getattr(args, "outdir", None) in (None, "", False) and env_out:
            args.outdir = env_out
        # 2) Création sûre du répertoire s il est défini
        if getattr(args, "outdir", None):
            try:
                os.makedirs(args.outdir, exist_ok=True)
            except Exception:
                pass
        # 3) rcParams savefig si des attributs existent
        try:
            import matplotlib
            _rc = {}
            if hasattr(args, "dpi") and args.dpi:
                _rc["savefig.dpi"] = args.dpi
            if hasattr(args, "fmt") and args.fmt:
                _rc["savefig.format"] = args.fmt
            if hasattr(args, "transparent"):
                _rc["savefig.transparent"] = bool(args.transparent)
            if _rc:
                matplotlib.rcParams.update(_rc)
        except Exception:
            pass
        # 4) Copier automatiquement le dernier PNG vers outdir à la fin

        def _smoke_copy_latest():
            try:
                if not getattr(args, "outdir", None):
                    return
                import glob
                import os
                import shutil
                _ch = os.path.basename(os.path.dirname(__file__))
                _repo = os.path.abspath(
                    os.path.join(
                        os.path.dirname(__file__),
                        "..",
                        ".."))
                _default_dir = os.path.join(_repo, "zz-figures", _ch)
                pngs = sorted(
                    glob.glob(os.path.join(_default_dir, "*.png")),
                    key=os.path.getmtime,
                    reverse=True,
                )
                for _p in pngs:
                    if os.path.exists(_p):
                        _dst = os.path.join(args.outdir, os.path.basename(_p))
                        if not os.path.exists(_dst):
                            shutil.copy2(_p, _dst)
                        break
            except Exception:
                pass
        atexit.register(_smoke_copy_latest)
except Exception:
    # épilogue best-effort — ne doit jamais casser le script principal
    pass

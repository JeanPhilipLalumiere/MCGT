#!/usr/bin/env python3
# plot_fig02_dv_vs_z.py
# ---------------------------------------------------------------
# zz-scripts/chapter08/plot_fig02_dv_vs_z.py
# Figure 02 – Comparison D_V^obs vs D_V^th for Chapter 08
# BAO errorbars, legend bottom-right
# ---------------------------------------------------------------

import json
from pathlib import Path

import matplotlib.pyplot as plt
import pandas as pd


def main():
    # --- Directories (translated to English names) ---
    ROOT = Path(__file__).resolve().parents[2]
    DATA_DIR = ROOT / "zz-data" / "chapter08"
    FIG_DIR = ROOT / "zz-figures" / "chapter08"
    FIG_DIR.mkdir(parents=True, exist_ok=True)

    # --- Load BAO observations, theoretical curve and χ² scan ---
    # Filenames translated to English:
    # 08_bao_data.csv
    # 08_dv_theory_z.csv
    # 08_chi2_total_vs_q0.csv
    bao = pd.read_csv(DATA_DIR / "08_bao_data.csv", encoding="utf-8")
    theo = pd.read_csv(DATA_DIR / "08_dv_theory_z.csv", encoding="utf-8")
    chi2 = pd.read_csv(DATA_DIR / "08_chi2_total_vs_q0.csv", encoding="utf-8")

    # --- Extract optimal q0* ---
    # (was 08_params_couplage.json)
    params_path = DATA_DIR / "08_params_coupling.json"
    q0star = None
    if params_path.exists():
        params = json.loads(params_path.read_text(encoding="utf-8"))
        q0star = params.get("q0star")
    if q0star is None:
        idx_best = chi2["chi2_total"].idxmin()
        q0star = float(chi2.loc[idx_best, "q0star"])

    # --- Plot ---
    fig, ax = plt.subplots(figsize=(8, 5))

    # 1) BAO observations with error bars
    ax.errorbar(
        bao["z"],
        bao["DV_obs"],
        yerr=bao["sigma_DV"],
        fmt="o",
        capsize=4,
        mec="k",
        mfc="C0",
        ms=6,
        label="BAO observations",
    )

    # 2) Theoretical curve for optimal q0*
    ax.plot(
        theo["z"],
        theo["DV_calc"],
        linewidth=2.0,
        color="C1",
        label=rf"$D_V^{{\rm th}}(z;\,q_0^*)\,,\;q_0^*={q0star:.3f}$",
    )

    # --- Formatting ---
    ax.set_xscale("log")
    ax.set_xlabel("Redshift $z$")
    ax.set_ylabel(r"$D_V$ (Mpc)")
    ax.set_title(r"Comparison $D_V^{\rm obs}$ vs $D_V^{\rm th}$")
    ax.grid(which="both", linestyle="--", linewidth=0.5, alpha=0.7)

    # Legend bottom-right inside the plot
    ax.legend(loc="lower right", frameon=False)

    plt.tight_layout()

    # Save
    out_file = FIG_DIR / "fig_02_dv_vs_z.png"
    plt.savefig(out_file, dpi=300)
    print(f"✅ Figure saved : {out_file}")


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

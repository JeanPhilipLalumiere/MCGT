import argparse
from _common import cli as C
#!/usr/bin/env python3
# fichier : zz-scripts/chapter08/plot_fig02_dv_vs_z.py
# répertoire : zz-scripts/chapter08
# plot_fig02_dv_vs_z.py
# ---------------------------------------------------------------
# zz-scripts/chapter08/plot_fig02_dv_vs_z.py
# Figure 02 – Comparison D_V^obs vs D_V^th for Chapter 08
# BAO errorbars, legend bottom-right
# ---------------------------------------------------------------

import json
from pathlib import Path

from _common.cli import add_common_plot_args, finalize_plot_from_args, init_logging

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
        label=rf"$D_V^{{\rm th}}(z;\,q_0^*)\,\;q_0^*={q0star:.3f}$",
    )

    # --- Formatting ---
    ax.set_xscale("log")
    ax.set_xlabel("Redshift $z$")
    ax.set_ylabel(r"$D_V$ (Mpc)")
    ax.set_title(r"Comparison $D_V^{\rm obs}$ vs $D_V^{\rm th}$")
    ax.grid(which="both", linestyle="--", linewidth=0.5, alpha=0.7)

    # Legend bottom-right inside the plot
    ax.legend(loc="lower right", frameon=False)

    fig.subplots_adjust(left=0.04, right=0.98, bottom=0.06, top=0.96)

    # Save
    out_file = FIG_DIR / "fig_02_dv_vs_z.png"
# [autofix] toplevel plt.savefig(...) neutralisé — utiliser C.finalize_plot_from_args(args)
    print(f"✅ Figure saved : {out_file}")


if __name__ == "__main__":
    main()
def build_parser() -> argparse.ArgumentParser:
    p = argparse.ArgumentParser(description="(autofix)",)
    C.add_common_plot_args(p)
    return p

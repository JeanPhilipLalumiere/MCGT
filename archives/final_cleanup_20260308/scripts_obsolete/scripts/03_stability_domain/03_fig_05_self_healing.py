#!/usr/bin/env python3
from __future__ import annotations

import json
from pathlib import Path

import matplotlib.pyplot as plt
import numpy as np
import pandas as pd


ROOT = Path(__file__).resolve().parents[2]
DATA_DIR = ROOT / "assets" / "zz-data" / "03_stability_domain"
FIG_DIR = ROOT / "assets" / "zz-figures" / "03_stability_domain"
OUT = FIG_DIR / "03_fig_05_self_healing.png"


def main() -> None:
    FIG_DIR.mkdir(parents=True, exist_ok=True)

    raw = pd.read_csv(DATA_DIR / "03_fR_stability_raw.csv")
    corr = pd.read_csv(DATA_DIR / "03_fR_stability_data.csv")
    traj = pd.read_csv(DATA_DIR / "03_ricci_fR_vs_z.csv")
    meta = json.loads((DATA_DIR / "03_fR_stability_meta.json").read_text(encoding="utf-8"))
    diag = meta.get("diagnostics", {})

    z_break = diag.get("raw_break_z")
    z_phantom = diag.get("phantom_crossing_z")
    raw_traj_ms2 = np.interp(
        traj["R_over_R0"].to_numpy(dtype=float),
        raw["R_over_R0"].to_numpy(dtype=float),
        raw["m_s2_over_R0"].to_numpy(dtype=float),
    )

    fig, axes = plt.subplots(2, 1, figsize=(8.5, 8.2))

    axes[0].plot(traj["z"], traj["m_s2_over_R0"], color="#08519c", lw=2.0, label="Corrected trajectory")
    axes[0].plot(traj["z"], raw_traj_ms2, color="#cb181d", lw=1.5, alpha=0.7, label="Raw trajectory")
    axes[0].axhline(0.0, color="#444444", ls="--", lw=1.0)
    if z_phantom is not None:
        axes[0].axvline(z_phantom, color="#6a3d9a", ls=":", lw=1.2, label=f"Phantom crossing z={z_phantom:.2f}")
    if z_break is not None:
        axes[0].axvline(z_break, color="#e6550d", ls="--", lw=1.2, label=f"Raw break z={z_break:.2f}")
    axes[0].set_xscale("log")
    axes[0].set_yscale("symlog", linthresh=1.0)
    axes[0].set_ylabel(r"$m_s^2/R_0$")
    axes[0].set_title("Figure 5 - Self-Healing of the PsiTMG Stability Trajectory")
    axes[0].grid(True, which="both", alpha=0.25)
    axes[0].legend(frameon=False, loc="best")

    axes[1].plot(raw["R_over_R0"], 1.0 + raw["f_R"], color="#cb181d", lw=1.5, alpha=0.7, label="Raw")
    axes[1].plot(corr["R_over_R0"], 1.0 + corr["f_R"], color="#08519c", lw=2.0, label="Corrected")
    axes[1].axhline(0.0, color="#444444", ls="--", lw=1.0)
    axes[1].set_xscale("log")
    axes[1].set_ylabel(r"$1 + f_R$")
    axes[1].set_xlabel(r"$R/R_0$")
    axes[1].grid(True, which="both", alpha=0.25)
    axes[1].legend(frameon=False, loc="best")
    axes[1].text(
        0.03,
        0.05,
        (
            f"phantom crossing z = {z_phantom:.3f}\n"
            f"raw break z = {z_break:.3f}\n"
            f"stabilized negative rows = {diag.get('stabilized_negative_rows')}\n"
            f"min corrected H_ham = {traj['hamiltonian_energy_proxy'].min():.3e}"
        ),
        transform=axes[1].transAxes,
        fontsize=10,
        bbox={"facecolor": "white", "alpha": 0.9, "edgecolor": "#999999"},
    )

    fig.tight_layout()
    fig.savefig(OUT, dpi=300)
    plt.close(fig)
    print(f"Wrote {OUT}")


if __name__ == "__main__":
    main()

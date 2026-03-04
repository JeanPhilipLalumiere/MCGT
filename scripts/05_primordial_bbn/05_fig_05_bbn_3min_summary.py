#!/usr/bin/env python3
from __future__ import annotations

import json
from pathlib import Path

import matplotlib.pyplot as plt
import pandas as pd


ROOT = Path(__file__).resolve().parents[2]
DATA_DIR = ROOT / "assets" / "zz-data" / "05_primordial_bbn"
FIG_DIR = ROOT / "assets" / "zz-figures" / "05_primordial_bbn"


def main() -> None:
    FIG_DIR.mkdir(parents=True, exist_ok=True)

    preds = pd.read_csv(DATA_DIR / "05_bbn_data.csv")
    milestones = pd.read_csv(DATA_DIR / "05_bbn_milestones.csv")
    summary = json.loads((DATA_DIR / "05_bbn_convergence_summary.json").read_text(encoding="utf-8"))

    t_3min = float(summary["target_time_gyr_3min"])
    early = milestones.sort_values("T_Gyr").iloc[0]
    pred_3min = preds.iloc[(preds["T_Gyr"] - t_3min).abs().argmin()]

    fig, axes = plt.subplots(1, 2, figsize=(10.2, 4.8), dpi=300)

    # D/H panel
    ax = axes[0]
    ax.plot(preds["T_Gyr"], preds["DH_calc"], color="#b85c38", lw=2.0, label="PsiTMG")
    ax.axhline(early["DH_obs"], color="#1f4b99", ls="--", lw=1.4, label="Observed mean")
    ax.axhspan(
        early["DH_obs"] - early["sigma_DH"],
        early["DH_obs"] + early["sigma_DH"],
        color="#1f4b99",
        alpha=0.15,
        label=r"$1\sigma$ band",
    )
    ax.axvline(t_3min, color="#444444", ls=":", lw=1.2)
    ax.scatter([pred_3min["T_Gyr"]], [pred_3min["DH_calc"]], color="#b85c38", s=35, zorder=3)
    ax.set_xscale("log")
    ax.set_xlabel("Cosmic time [Gyr]")
    ax.set_ylabel("D/H")
    ax.set_title(r"BBN check at $t \approx 3$ min: Deuterium")
    ax.grid(True, which="both", alpha=0.25)
    ax.legend(frameon=False, loc="best")

    # Y_p panel
    ax = axes[1]
    ax.plot(preds["T_Gyr"], preds["Yp_calc"], color="#2c7a7b", lw=2.0, label="PsiTMG")
    ax.axhline(early["Yp_obs"], color="#1f4b99", ls="--", lw=1.4, label="Observed mean")
    ax.axhspan(
        early["Yp_obs"] - early["sigma_Yp"],
        early["Yp_obs"] + early["sigma_Yp"],
        color="#1f4b99",
        alpha=0.15,
        label=r"$1\sigma$ band",
    )
    ax.axvline(t_3min, color="#444444", ls=":", lw=1.2)
    ax.scatter([pred_3min["T_Gyr"]], [pred_3min["Yp_calc"]], color="#2c7a7b", s=35, zorder=3)
    ax.set_xscale("log")
    ax.set_xlabel("Cosmic time [Gyr]")
    ax.set_ylabel(r"$Y_p$")
    ax.set_title(r"BBN check at $t \approx 3$ min: Helium-4")
    ax.grid(True, which="both", alpha=0.25)
    ax.legend(frameon=False, loc="best")

    fig.suptitle("Figure 8. Primordial abundances remain GR-compatible in the hot regime", y=1.02)
    fig.tight_layout()

    for ext in ("png", "pdf"):
        out = FIG_DIR / f"05_fig_05_bbn_3min_summary.{ext}"
        fig.savefig(out, dpi=300)
    plt.close(fig)


if __name__ == "__main__":
    main()

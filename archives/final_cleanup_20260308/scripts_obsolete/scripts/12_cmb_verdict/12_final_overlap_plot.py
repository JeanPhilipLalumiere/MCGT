#!/usr/bin/env python3
"""Chapter 12: final overlap plot for the MCGT verdict."""

from __future__ import annotations

import argparse
import configparser
from pathlib import Path

import numpy as np
import pandas as pd


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description="Plot the final overlap between LIGO exclusions and the S8 target band."
    )
    parser.add_argument(
        "--ligo-csv",
        default="assets/zz-data/10_global_scan/10_exclusion_constraints.csv",
    )
    parser.add_argument(
        "--k-rescue-csv",
        default="assets/zz-data/11_lss_s8_tension/11_k_dependent_rescue.csv",
    )
    parser.add_argument("--config", default="config/mcgt-global-config.ini")
    parser.add_argument(
        "--out",
        default="assets/zz-figures/12_cmb_verdict/12_final_overlap_constraints.png",
    )
    parser.add_argument(
        "--note-out",
        default="assets/zz-data/12_cmb_verdict/12_final_verdict_note.md",
    )
    return parser.parse_args()


def load_alpha(config_path: Path) -> float:
    cfg = configparser.ConfigParser(
        interpolation=None, inline_comment_prefixes=("#", ";")
    )
    if not cfg.read(config_path, encoding="utf-8"):
        raise FileNotFoundError(f"Cannot read config: {config_path}")
    return cfg["perturbations"].getfloat("alpha")


def main() -> int:
    args = parse_args()
    ligo_df = pd.read_csv(args.ligo_csv)
    rescue_df = pd.read_csv(args.k_rescue_csv)

    alpha_grid = np.concatenate(
        [
            ligo_df["alpha_lo"].to_numpy(),
            [ligo_df["alpha_hi"].iloc[-1]],
        ]
    )
    q0_limits = np.concatenate(
        [
            ligo_df["q0_abs_max_survivor"].to_numpy(),
            [ligo_df["q0_abs_max_survivor"].iloc[-1]],
        ]
    )

    alpha_match = load_alpha(Path(args.config))
    q0_local = float(rescue_df["q0_gw"].iloc[0])
    q0_cosmo = float(rescue_df["q0_lss"].iloc[0])
    s8_target_band = (-3.0e-3, -1.0e-3)

    overlap_exists = abs(q0_cosmo) <= np.interp(
        alpha_match,
        ligo_df["alpha_mean"].to_numpy(),
        ligo_df["q0_abs_max_survivor"].to_numpy(),
        left=ligo_df["q0_abs_max_survivor"].iloc[0],
        right=ligo_df["q0_abs_max_survivor"].iloc[-1],
    )

    try:
        import matplotlib.pyplot as plt
    except ImportError as exc:
        raise SystemExit(f"matplotlib missing: {exc}") from exc

    out_path = Path(args.out)
    out_path.parent.mkdir(parents=True, exist_ok=True)

    fig, ax = plt.subplots(figsize=(7.2, 5.0))

    ax.fill_between(
        alpha_grid,
        q0_limits,
        3.5e-3,
        color="tab:red",
        alpha=0.22,
        step="post",
        label="Excluded by LIGO (positive branch)",
    )
    ax.fill_between(
        alpha_grid,
        -3.5e-3,
        -q0_limits,
        color="tab:red",
        alpha=0.22,
        step="post",
        label="Excluded by LIGO (negative branch)",
    )
    ax.step(alpha_grid, q0_limits, where="post", color="tab:red", lw=1.6)
    ax.step(alpha_grid, -q0_limits, where="post", color="tab:red", lw=1.6)

    ax.axhspan(
        s8_target_band[0],
        s8_target_band[1],
        color="tab:blue",
        alpha=0.18,
        label=r"S$_8$-solving band ($q_0^* \sim -10^{-3}$ to $-3\times10^{-3}$)",
    )

    ax.scatter(
        [alpha_match, alpha_match],
        [q0_local, q0_cosmo],
        color="gold",
        edgecolor="black",
        zorder=4,
        s=90,
    )
    ax.plot([alpha_match, alpha_match], [q0_local, q0_cosmo], color="goldenrod", lw=2.0, zorder=3)
    ax.annotate(
        "Golden Match\n(scale split)",
        xy=(alpha_match, 0.5 * (q0_local + q0_cosmo)),
        xytext=(alpha_match + 0.08, -1.5e-3),
        arrowprops={"arrowstyle": "->", "lw": 1.2, "color": "black"},
        fontsize=9,
        ha="left",
    )

    ax.text(
        0.02,
        0.97,
        "\n".join(
            [
                rf"$\alpha_{{match}} \approx {alpha_match:.2f}$",
                rf"$q_0^*(k \to \infty) \approx {q0_local:.1e}$",
                rf"$q_0^*(k \to 0) \approx {q0_cosmo:.1e}$",
            ]
        ),
        transform=ax.transAxes,
        va="top",
        fontsize=9,
    )

    ax.set_xlim(float(ligo_df["alpha_lo"].min()), float(ligo_df["alpha_hi"].max()))
    ax.set_ylim(-3.2e-3, 3.2e-3)
    ax.set_xlabel(r"$\alpha$")
    ax.set_ylabel(r"$q_0^*$")
    ax.set_title("Final overlap of LIGO exclusions and the LSS rescue band")
    ax.grid(True, alpha=0.25)
    ax.legend(frameon=False, loc="upper right")
    fig.subplots_adjust(left=0.12, right=0.98, bottom=0.13, top=0.91)
    fig.savefig(out_path, dpi=180)

    note = Path(args.note_out)
    note.parent.mkdir(parents=True, exist_ok=True)
    lines = [
        "# La MCGT est-elle sauvee ?",
        "",
        "Verdict:",
        (
            "Il n'existe pas d'espace de parametres commun dans le plan "
            r"`(\alpha, q_0^*)` pour un couplage universel unique : la bande "
            "cosmologique requise pour `S8 ~ 0.77` tombe dans la zone exclue par LIGO."
        ),
        (
            "La survie phenomenologique de la MCGT apparait uniquement sous la forme "
            "d'une bifurcation en echelle, ou la meme valeur de `alpha` supporte deux "
            "branches effectives : `q0* ~ 10^-6` pour les modes locaux/GW et "
            "`q0* ~ -2 x 10^-3` pour les modes cosmologiques/LSS."
        ),
        (
            f"Au point de correspondance retenu, on obtient `alpha ~ {alpha_match:.2f}`, "
            f"`q0*(k->infty) ~ {q0_local:.2e}` et `q0*(k->0) ~ {q0_cosmo:.2e}`."
        ),
        (
            "Conclusion : la MCGT n'est pas sauvee en tant que theorie a couplage global "
            "unique, mais elle reste phenomenologiquement viable dans un schema explicitement "
            "k-dependant."
        ),
        "",
        f"Overlap universel present: `{overlap_exists}`.",
        "",
    ]
    note.write_text("\n".join(lines), encoding="utf-8")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())

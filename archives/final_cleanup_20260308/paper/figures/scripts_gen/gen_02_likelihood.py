#!/usr/bin/env python3
"""Figure generator for ΨTMG Manuscript v4.0.0 - arXiv Preprint Ready"""

from __future__ import annotations

import argparse
import json
import sys
from pathlib import Path

import matplotlib.pyplot as plt
import numpy as np
from scipy.optimize import minimize
from mpl_toolkits.axes_grid1.inset_locator import inset_axes

REPO_ROOT = Path(__file__).resolve().parents[3]
if str(REPO_ROOT) not in sys.path:
    sys.path.insert(0, str(REPO_ROOT))

from core_physics import PsiTMGCosmology
from likelihoods import LikelihoodEvaluator
from perturbations import StructureFormation

DEFAULT_OUT = Path(__file__).resolve().parents[1] / "02_fig_likelihood.pdf"
DEFAULT_CSV = Path(__file__).resolve().parents[1] / "02_fig_likelihood_scan.csv"
DEFAULT_JSON = Path(__file__).resolve().parents[1] / "02_fig_likelihood_summary.json"


def _nll_fixed_h0(theta: np.ndarray, h0_fixed: float, sigma8: float, like: LikelihoodEvaluator) -> float:
    omega_m, w0, wa = map(float, theta)
    cosmo = PsiTMGCosmology(H_0=float(h0_fixed), Omega_m=omega_m, w_0=w0, w_a=wa, sigma_8=float(sigma8))
    structure = StructureFormation(cosmo)
    lnL = like.compute_total_lnL(
        cosmo,
        structure=structure,
        use_sne=True,
        use_cmb=True,
        use_bao=True,
        use_bao_aniso=False,
        use_cc=False,
        use_rsd=True,
    )
    return 1.0e30 if not np.isfinite(lnL) else -float(lnL)


def _nll_global(theta: np.ndarray, sigma8: float, like: LikelihoodEvaluator) -> float:
    h0, omega_m, w0, wa = map(float, theta)
    cosmo = PsiTMGCosmology(H_0=h0, Omega_m=omega_m, w_0=w0, w_a=wa, sigma_8=float(sigma8))
    structure = StructureFormation(cosmo)
    lnL = like.compute_total_lnL(
        cosmo,
        structure=structure,
        use_sne=True,
        use_cmb=True,
        use_bao=True,
        use_bao_aniso=False,
        use_cc=False,
        use_rsd=True,
    )
    return 1.0e30 if not np.isfinite(lnL) else -float(lnL)


def build_parser() -> argparse.ArgumentParser:
    p = argparse.ArgumentParser(description="Generate profile likelihood PDF for paper/figures.")
    p.add_argument("--h0-min", type=float, default=66.0)
    p.add_argument("--h0-max", type=float, default=78.0)
    p.add_argument("--h0-step", type=float, default=0.4)
    p.add_argument("--sigma8", type=float, default=0.862)
    p.add_argument("--omega-m-init", type=float, default=0.226)
    p.add_argument("--w0-init", type=float, default=-1.48)
    p.add_argument("--wa-init", type=float, default=0.45)
    p.add_argument("--omega-m-min", type=float, default=0.15)
    p.add_argument("--omega-m-max", type=float, default=0.35)
    p.add_argument("--w0-min", type=float, default=-1.52)
    p.add_argument("--w0-max", type=float, default=-1.44)
    p.add_argument("--wa-min", type=float, default=0.40)
    p.add_argument("--wa-max", type=float, default=0.50)
    p.add_argument("--out", type=Path, default=DEFAULT_OUT)
    p.add_argument("--out-csv", type=Path, default=DEFAULT_CSV)
    p.add_argument("--out-json", type=Path, default=DEFAULT_JSON)
    return p


def main() -> int:
    args = build_parser().parse_args()
    h0_grid = np.arange(args.h0_min, args.h0_max + 0.5 * args.h0_step, args.h0_step, dtype=float)

    like = LikelihoodEvaluator()

    global_bounds = [
        (50.0, 90.0),
        (args.omega_m_min, args.omega_m_max),
        (args.w0_min, args.w0_max),
        (args.wa_min, args.wa_max),
    ]
    global_start = np.array([74.2, args.omega_m_init, args.w0_init, args.wa_init], dtype=float)
    g = minimize(_nll_global, x0=global_start, args=(args.sigma8, like), method="L-BFGS-B", bounds=global_bounds)
    nll_global = float(g.fun)

    theta = np.array([g.x[1], g.x[2], g.x[3]], dtype=float)
    bounds = [(args.omega_m_min, args.omega_m_max), (args.w0_min, args.w0_max), (args.wa_min, args.wa_max)]

    rows = []
    for h0 in h0_grid:
        r = minimize(_nll_fixed_h0, x0=theta, args=(float(h0), args.sigma8, like), method="L-BFGS-B", bounds=bounds)
        theta = np.asarray(r.x, dtype=float)
        nll = float(_nll_fixed_h0(theta, float(h0), args.sigma8, like))
        dchi2 = 2.0 * (nll - nll_global)
        rows.append([float(h0), float(theta[0]), float(theta[1]), float(theta[2]), nll, dchi2])

    arr = np.array(rows, dtype=float)
    args.out.parent.mkdir(parents=True, exist_ok=True)
    args.out_csv.parent.mkdir(parents=True, exist_ok=True)
    args.out_json.parent.mkdir(parents=True, exist_ok=True)

    np.savetxt(
        args.out_csv,
        arr,
        delimiter=",",
        header="H0_fixed,Omega_m_best,w0_best,wa_best,nll_profile,delta_chi2",
        comments="",
    )

    fig, ax = plt.subplots(figsize=(8.2, 4.8), constrained_layout=True)
    ax.plot(arr[:, 0], arr[:, 5], color="#1565c0", lw=2.2, label=r"$\Psi$TMG likelihood")
    ax.axvspan(66.9, 67.9, color="gray", alpha=0.12, zorder=0)
    ax.axvline(67.4, color="gray", lw=1.0, ls="--")
    ax.text(
        67.52,
        12.0,
        r"Planck18 ($\Lambda$CDM)",
        color="#666666",
        fontsize=9,
        rotation=90,
        va="center",
        ha="left",
    )
    for y, sig in [(1.0, "1\\sigma"), (4.0, "2\\sigma"), (9.0, "3\\sigma")]:
        ax.axhline(y, color="gray", lw=0.5, ls="--", alpha=0.85, label=rf"$\Delta\chi^2={int(y)}\ ({sig})$")
    ax.set_xlabel(r"$H_0$ [km s$^{-1}$ Mpc$^{-1}$]")
    ax.set_ylabel(r"$\Delta\chi^2$")
    ax.set_title("Frequentist profile likelihood for $H_0$")
    ax.set_xlim(66.0, 78.0)
    ax.grid(True, alpha=0.25)
    handles, labels = ax.get_legend_handles_labels()
    uniq = dict(zip(labels, handles))
    ax.legend(uniq.values(), uniq.keys(), frameon=False, fontsize=9, loc="lower right")

    # Inset zoom near the parabola minimum for direct sigma-line readability.
    axins = inset_axes(
        ax,
        width="44%",
        height="48%",
        loc="upper center",
        bbox_to_anchor=(0.0, 0.0, 1.0, 1.0),
        bbox_transform=ax.transAxes,
        borderpad=1.0,
    )
    axins.plot(arr[:, 0], arr[:, 5], color="#1565c0", lw=2.0)
    inset_lines = [
        (1.0, "#6abf69", r"$1\sigma$"),
        (4.0, "#f39c12", r"$2\sigma$"),
        (9.0, "#d62728", r"$3\sigma$"),
    ]
    for y, c, txt in inset_lines:
        axins.axhline(y, color=c, lw=0.9, ls="--", alpha=0.95)
        axins.annotate(
            txt,
            xy=(74.95, y),
            xytext=(74.95, y + 0.35),
            color=c,
            fontsize=8.5,
            ha="right",
            va="bottom",
        )
    axins.set_xlim(73.5, 75.0)
    axins.set_ylim(0.0, 15.0)
    axins.set_xticks([73.5, 74.0, 74.5, 75.0])
    axins.set_yticks([0, 5, 10, 15])
    axins.tick_params(labelsize=8)
    axins.grid(True, alpha=0.2)

    fig.savefig(args.out)
    fig.savefig(args.out.with_suffix(".png"), dpi=300)
    plt.close(fig)

    args.out_json.write_text(
        json.dumps(
            {
                "h0_grid_min": float(h0_grid.min()),
                "h0_grid_max": float(h0_grid.max()),
                "h0_step": float(args.h0_step),
                "global_best": {
                    "H0": float(g.x[0]),
                    "Omega_m": float(g.x[1]),
                    "w0": float(g.x[2]),
                    "wa": float(g.x[3]),
                },
                "nll_global": nll_global,
            },
            indent=2,
        ),
        encoding="utf-8",
    )

    print(f"[ok] wrote {args.out}")
    print(f"[ok] wrote {args.out_csv}")
    print(f"[ok] wrote {args.out_json}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())

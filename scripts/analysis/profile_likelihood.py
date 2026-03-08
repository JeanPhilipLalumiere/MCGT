#!/usr/bin/env python3
"""Frequentist profile-likelihood scan versus fixed H0."""

from __future__ import annotations

import argparse
import json
import sys
from pathlib import Path

import matplotlib.pyplot as plt
import numpy as np
from scipy.optimize import minimize

ROOT = Path(__file__).resolve().parents[2]
if str(ROOT) not in sys.path:
    sys.path.insert(0, str(ROOT))

from core_physics import PsiTMGCosmology
from likelihoods import LikelihoodEvaluator
from perturbations import StructureFormation


def _nll_total(
    theta: np.ndarray,
    h0_fixed: float,
    sigma8: float,
    like: LikelihoodEvaluator,
) -> float:
    omega_m, w0, wa = map(float, theta)
    cosmo = PsiTMGCosmology(
        H_0=float(h0_fixed),
        Omega_m=omega_m,
        w_0=w0,
        w_a=wa,
        sigma_8=float(sigma8),
    )
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
    if not np.isfinite(lnL):
        return 1.0e30
    return -float(lnL)


def _nll_global(
    theta: np.ndarray,
    sigma8: float,
    like: LikelihoodEvaluator,
) -> float:
    h0, omega_m, w0, wa = map(float, theta)
    cosmo = PsiTMGCosmology(
        H_0=h0,
        Omega_m=omega_m,
        w_0=w0,
        w_a=wa,
        sigma_8=float(sigma8),
    )
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
    if not np.isfinite(lnL):
        return 1.0e30
    return -float(lnL)


def main() -> int:
    parser = argparse.ArgumentParser(description="Profile-likelihood scan in fixed H0.")
    parser.add_argument("--h0-min", type=float, default=70.0)
    parser.add_argument("--h0-max", type=float, default=78.0)
    parser.add_argument("--h0-step", type=float, default=0.4)
    parser.add_argument("--sigma8", type=float, default=0.862, help="Fixed sigma8 during profile scan.")
    parser.add_argument("--omega-m-init", type=float, default=0.226, help="Initial Omega_m for optimization.")
    parser.add_argument("--w0-init", type=float, default=-1.48, help="Initial w0 for optimization.")
    parser.add_argument("--wa-init", type=float, default=0.45, help="Initial wa for optimization.")
    parser.add_argument("--omega-m-min", type=float, default=0.15, help="Lower bound for Omega_m.")
    parser.add_argument("--omega-m-max", type=float, default=0.35, help="Upper bound for Omega_m.")
    parser.add_argument("--w0-min", type=float, default=-1.52, help="Lower bound for w0.")
    parser.add_argument("--w0-max", type=float, default=-1.44, help="Upper bound for w0.")
    parser.add_argument("--wa-min", type=float, default=0.40, help="Lower bound for wa.")
    parser.add_argument("--wa-max", type=float, default=0.50, help="Upper bound for wa.")
    parser.add_argument(
        "--optimizer",
        choices=("L-BFGS-B", "Nelder-Mead"),
        default="L-BFGS-B",
    )
    parser.add_argument(
        "--out-csv",
        type=Path,
        default=Path("output/profile_likelihood_h0.csv"),
    )
    parser.add_argument(
        "--out-plot",
        type=Path,
        default=Path("output/profile_likelihood_h0.png"),
    )
    parser.add_argument(
        "--out-json",
        type=Path,
        default=Path("output/profile_likelihood_h0_summary.json"),
    )
    args = parser.parse_args()

    if args.h0_step <= 0.0:
        raise ValueError("--h0-step must be > 0")
    if args.h0_max <= args.h0_min:
        raise ValueError("--h0-max must be > --h0-min")

    h0_grid = np.arange(args.h0_min, args.h0_max + 0.5 * args.h0_step, args.h0_step, dtype=float)
    like = LikelihoodEvaluator()

    # Compute a global best-fit NLL (unconstrained H0) for Delta chi2 reference.
    global_bounds = [
        (50.0, 90.0),
        (args.omega_m_min, args.omega_m_max),
        (args.w0_min, args.w0_max),
        (args.wa_min, args.wa_max),
    ]
    global_start = np.array([74.2, args.omega_m_init, args.w0_init, args.wa_init], dtype=float)
    global_res = minimize(
        fun=_nll_global,
        x0=global_start,
        args=(args.sigma8, like),
        method="L-BFGS-B",
        bounds=global_bounds,
        options={"maxiter": 300, "ftol": 1e-9},
    )
    nll_global = float(global_res.fun)

    rows: list[dict[str, float]] = []
    # Warm start profile optimization with the global solution projected to free params.
    theta0 = np.array([global_res.x[1], global_res.x[2], global_res.x[3]], dtype=float)
    bounds = [
        (args.omega_m_min, args.omega_m_max),
        (args.w0_min, args.w0_max),
        (args.wa_min, args.wa_max),
    ]

    for h0 in h0_grid:
        if args.optimizer == "L-BFGS-B":
            res = minimize(
                fun=_nll_total,
                x0=theta0,
                args=(float(h0), args.sigma8, like),
                method="L-BFGS-B",
                bounds=bounds,
                options={"maxiter": 250, "ftol": 1e-9},
            )
        else:
            # Nelder-Mead with soft box clipping through objective start point control.
            res = minimize(
                fun=_nll_total,
                x0=theta0,
                args=(float(h0), args.sigma8, like),
                method="Nelder-Mead",
                options={"maxiter": 500, "xatol": 1e-4, "fatol": 1e-4},
            )

        theta = np.asarray(res.x, dtype=float)
        # Clip for safety when using Nelder-Mead.
        theta[0] = np.clip(theta[0], bounds[0][0], bounds[0][1])
        theta[1] = np.clip(theta[1], bounds[1][0], bounds[1][1])
        theta[2] = np.clip(theta[2], bounds[2][0], bounds[2][1])
        nll_prof = float(_nll_total(theta, float(h0), args.sigma8, like))
        delta_chi2 = 2.0 * (nll_prof - nll_global)
        rows.append(
            {
                "H0_fixed": float(h0),
                "Omega_m_best": float(theta[0]),
                "w0_best": float(theta[1]),
                "wa_best": float(theta[2]),
                "nll_profile": nll_prof,
                "delta_chi2": float(delta_chi2),
            }
        )
        theta0 = theta

    args.out_csv.parent.mkdir(parents=True, exist_ok=True)
    args.out_plot.parent.mkdir(parents=True, exist_ok=True)
    args.out_json.parent.mkdir(parents=True, exist_ok=True)

    arr = np.array(
        [
            [
                r["H0_fixed"],
                r["Omega_m_best"],
                r["w0_best"],
                r["wa_best"],
                r["nll_profile"],
                r["delta_chi2"],
            ]
            for r in rows
        ],
        dtype=float,
    )
    np.savetxt(
        args.out_csv,
        arr,
        delimiter=",",
        header="H0_fixed,Omega_m_best,w0_best,wa_best,nll_profile,delta_chi2",
        comments="",
    )

    fig, ax = plt.subplots(figsize=(8.2, 4.8))
    ax.plot(arr[:, 0], arr[:, 5], color="#1565c0", lw=2.2)
    for y, lbl in [(1.0, "1σ"), (4.0, "2σ"), (9.0, "3σ")]:
        ax.axhline(y, color="gray", lw=1.2, ls="--", alpha=0.85, label=f"Δχ²={int(y)} ({lbl})")
    ax.set_xlabel(r"$H_0$ [km s$^{-1}$ Mpc$^{-1}$]")
    ax.set_ylabel(r"$\Delta\chi^2$")
    ax.set_title("Profile Likelihood vs Fixed H0")
    ax.grid(True, alpha=0.25)
    handles, labels = ax.get_legend_handles_labels()
    uniq = dict(zip(labels, handles))
    ax.legend(uniq.values(), uniq.keys(), frameon=False, fontsize=9)
    fig.tight_layout()
    fig.savefig(args.out_plot, dpi=180)
    plt.close(fig)

    summary = {
        "optimizer": args.optimizer,
        "sigma8_fixed": float(args.sigma8),
        "h0_grid_min": float(h0_grid.min()),
        "h0_grid_max": float(h0_grid.max()),
        "h0_step": float(args.h0_step),
        "nll_global": nll_global,
        "global_best": {
            "H0": float(global_res.x[0]),
            "Omega_m": float(global_res.x[1]),
            "w0": float(global_res.x[2]),
            "wa": float(global_res.x[3]),
        },
        "outputs": {
            "csv": str(args.out_csv),
            "plot": str(args.out_plot),
        },
    }
    args.out_json.write_text(json.dumps(summary, indent=2), encoding="utf-8")

    print(f"Global best-fit: H0={global_res.x[0]:.4f}, Omega_m={global_res.x[1]:.5f}, w0={global_res.x[2]:.5f}, wa={global_res.x[3]:.5f}")
    print(f"Global NLL: {nll_global:.6f}")
    print(f"Wrote CSV: {args.out_csv}")
    print(f"Wrote plot: {args.out_plot}")
    print(f"Wrote summary: {args.out_json}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())

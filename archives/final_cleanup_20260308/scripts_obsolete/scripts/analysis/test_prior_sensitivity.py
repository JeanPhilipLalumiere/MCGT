#!/usr/bin/env python3
"""Prior-sensitivity audit for (Omega_m, H0) best-fit stability.

This script runs a fast optimization-based fit over three prior boxes to test
whether the preferred solution remains data-driven around:
    Omega_m ~ 0.226, H0 ~ 74.2
"""

from __future__ import annotations

import argparse
import importlib.util
import sys
from dataclasses import dataclass
from pathlib import Path

import numpy as np
from scipy.optimize import minimize

ROOT = Path(__file__).resolve().parents[2]
if str(ROOT) not in sys.path:
    sys.path.insert(0, str(ROOT))

from core_physics import PsiTMGCosmology
from likelihoods import LikelihoodEvaluator
from perturbations import StructureFormation


@dataclass(frozen=True)
class PriorBox:
    name: str
    omega_m: tuple[float, float]
    h0: tuple[float, float]


def _objective(
    theta: np.ndarray,
    like: LikelihoodEvaluator,
    w0: float,
    wa: float,
    sigma8: float,
) -> float:
    omega_m, h0 = float(theta[0]), float(theta[1])
    cosmo = PsiTMGCosmology(H_0=h0, Omega_m=omega_m, w_0=w0, w_a=wa, sigma_8=sigma8)
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


def _loglike(
    theta: np.ndarray,
    like: LikelihoodEvaluator,
    w0: float,
    wa: float,
    sigma8: float,
) -> float:
    omega_m, h0 = float(theta[0]), float(theta[1])
    cosmo = PsiTMGCosmology(H_0=h0, Omega_m=omega_m, w_0=w0, w_a=wa, sigma_8=sigma8)
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
    return float(lnL) if np.isfinite(lnL) else -1.0e300


def fit_prior_box(
    box: PriorBox,
    like: LikelihoodEvaluator,
    w0: float,
    wa: float,
    sigma8: float,
    restarts: int = 5,
    seed: int = 1234,
) -> tuple[np.ndarray, float]:
    rng = np.random.default_rng(seed)
    bounds = [box.omega_m, box.h0]

    center = np.array(
        [
            0.5 * (box.omega_m[0] + box.omega_m[1]),
            0.5 * (box.h0[0] + box.h0[1]),
        ],
        dtype=float,
    )
    starts = [center]
    for _ in range(max(0, restarts - 1)):
        starts.append(
            np.array(
                [
                    rng.uniform(*box.omega_m),
                    rng.uniform(*box.h0),
                ],
                dtype=float,
            )
        )

    best_x = center.copy()
    best_fun = float("inf")
    for x0 in starts:
        res = minimize(
            fun=_objective,
            x0=x0,
            args=(like, w0, wa, sigma8),
            method="L-BFGS-B",
            bounds=bounds,
            options={"maxiter": 200, "ftol": 1e-9},
        )
        if np.isfinite(res.fun) and float(res.fun) < best_fun:
            best_fun = float(res.fun)
            best_x = np.asarray(res.x, dtype=float)

    return best_x, -best_fun


def fit_prior_box_dynesty(
    box: PriorBox,
    like: LikelihoodEvaluator,
    w0: float,
    wa: float,
    sigma8: float,
    nlive: int = 100,
    dlogz: float = 0.5,
    seed: int = 1234,
) -> tuple[np.ndarray, float, float]:
    if importlib.util.find_spec("dynesty") is None:
        raise RuntimeError("dynesty is not installed. Use --engine minimize or install dynesty.")

    import dynesty

    rng = np.random.default_rng(seed)

    def prior_transform(u: np.ndarray) -> np.ndarray:
        om = box.omega_m[0] + (box.omega_m[1] - box.omega_m[0]) * float(u[0])
        h0 = box.h0[0] + (box.h0[1] - box.h0[0]) * float(u[1])
        return np.array([om, h0], dtype=float)

    sampler = dynesty.NestedSampler(
        loglikelihood=lambda th: _loglike(th, like, w0, wa, sigma8),
        prior_transform=prior_transform,
        ndim=2,
        nlive=nlive,
        rstate=rng,
    )
    sampler.run_nested(dlogz=dlogz, print_progress=False)
    res = sampler.results

    best_idx = int(np.argmax(res.logl))
    best_x = np.asarray(res.samples[best_idx], dtype=float)
    best_lnL = float(res.logl[best_idx])
    best_logz = float(res.logz[-1])
    return best_x, best_lnL, best_logz


def main() -> int:
    parser = argparse.ArgumentParser(description="Test Omega_m/H0 prior sensitivity with minimize or dynesty.")
    parser.add_argument("--engine", choices=("minimize", "dynesty"), default="minimize")
    parser.add_argument("--w0", type=float, default=-1.477, help="Fixed w0 value.")
    parser.add_argument("--wa", type=float, default=0.446, help="Fixed wa value.")
    parser.add_argument("--sigma8", type=float, default=0.862, help="Fixed sigma8 value.")
    parser.add_argument("--restarts", type=int, default=5, help="Number of random restarts per prior box.")
    parser.add_argument("--nlive", type=int, default=100, help="Dynesty live points.")
    parser.add_argument("--dlogz", type=float, default=0.5, help="Dynesty stopping criterion.")
    parser.add_argument("--seed", type=int, default=1234, help="RNG seed for restart initialization.")
    args = parser.parse_args()

    boxes = [
        PriorBox(name="Narrow", omega_m=(0.2, 0.3), h0=(70.0, 76.0)),
        PriorBox(name="Standard", omega_m=(0.1, 0.5), h0=(60.0, 80.0)),
        PriorBox(name="Wide", omega_m=(0.05, 0.6), h0=(50.0, 90.0)),
    ]
    target_om = 0.226
    target_h0 = 74.2

    like = LikelihoodEvaluator()

    print("Prior Sensitivity Audit (Omega_m, H0)")
    print(f"Engine: {args.engine}")
    print(f"Fixed params: w0={args.w0:.6f}, wa={args.wa:.6f}, sigma8={args.sigma8:.6f}")
    print("-" * 78)
    if args.engine == "minimize":
        print(f"{'Prior':<10} {'Omega_m*':>10} {'H0*':>10} {'lnL*':>14} {'dOmega_m':>12} {'dH0':>10}")
    else:
        print(
            f"{'Prior':<10} {'Omega_m*':>10} {'H0*':>10} {'lnL*':>14} "
            f"{'logZ':>12} {'dlogZ':>10} {'dOmega_m':>10} {'dH0':>8}"
        )
    print("-" * 78)

    logz_values: list[float] = []
    rows: list[tuple[str, float, float, float, float]] = []
    for i, box in enumerate(boxes):
        if args.engine == "minimize":
            best_x, best_lnL = fit_prior_box(
                box=box,
                like=like,
                w0=args.w0,
                wa=args.wa,
                sigma8=args.sigma8,
                restarts=args.restarts,
                seed=args.seed + i,
            )
            d_om = float(best_x[0] - target_om)
            d_h0 = float(best_x[1] - target_h0)
            print(f"{box.name:<10} {best_x[0]:10.5f} {best_x[1]:10.3f} {best_lnL:14.6f} {d_om:12.5f} {d_h0:10.3f}")
        else:
            best_x, best_lnL, best_logz = fit_prior_box_dynesty(
                box=box,
                like=like,
                w0=args.w0,
                wa=args.wa,
                sigma8=args.sigma8,
                nlive=args.nlive,
                dlogz=args.dlogz,
                seed=args.seed + i,
            )
            rows.append((box.name, float(best_x[0]), float(best_x[1]), best_lnL, best_logz))
            logz_values.append(best_logz)

    if args.engine == "dynesty":
        ref = max(logz_values) if logz_values else 0.0
        for name, om, h0, lnL, logz in rows:
            dlogz = logz - ref
            d_om = om - target_om
            d_h0 = h0 - target_h0
            print(f"{name:<10} {om:10.5f} {h0:10.3f} {lnL:14.6f} {logz:12.4f} {dlogz:10.4f} {d_om:10.5f} {d_h0:8.3f}")

    print("-" * 78)
    print("Interpretation: stable (Omega_m*, H0*) and close logZ across priors indicate a data-driven result.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())

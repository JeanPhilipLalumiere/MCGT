#!/usr/bin/env python3
"""Quick Sentinel likelihood benchmark for a fresh BHS deployment."""

import time

import numpy as np

import run_mcmc


def benchmark() -> None:
    print("--- Benchmark de performance Sentinel (BHS) ---")
    theta = np.array([0.25, 73.0, -1.0, 0.0, 0.72], dtype=float)

    start = time.time()
    res = run_mcmc.evaluate_chi2_components(theta, eos_model="cpl")
    end = time.time()

    print(f"Calcul Likelihood terminé en : {end - start:.4f} secondes")
    print(f"Total Chi2 : {res['chi2_total']:.3f}")

    if res["chi2_total"] < 1000:
        print("STABILITÉ : OK")
    else:
        print("STABILITÉ : ERREUR (vérifier les priors)")


if __name__ == "__main__":
    benchmark()

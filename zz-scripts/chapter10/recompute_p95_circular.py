#!/usr/bin/env python3
"""
recompute_p95_circular.py
Recalcule p95_20_300 en utilisant la distance angulaire minimale (circular diff).
Input: results.csv et samples.csv et grille de référence.
Output: results.{suffix}.csv (par défaut suffix='circ') et manifeste JSON.
Usage:
  python zz-scripts/chapter10/recompute_p95_circular.py \
    --results zz-data/chapter10/10_mc_results.csv \
    --samples zz-data/chapter10/10_mc_samples.csv \
    --ref-grid zz-data/chapter09/09_phases_imrphenom.csv \
    --out zz-data/chapter10/10_mc_results.circ.csv
"""

from __future__ import annotations

import argparse
import json
import os

import numpy as np
import pandas as pd

from zz_tools import common_io as ci

from mcgt.backends.ref_phase import compute_phi_ref
from mcgt.phase import phi_mcgt


def circ_diff(a, b):
    d = (a - b) % (2 * np.pi)
    d = np.where(d > np.pi, d - 2 * np.pi, d)
    return d


def main(argv=None):
    parser = argparse.ArgumentParser()
    parser.add_argument("--results", required=True)
    parser.add_argument("--samples", required=True)
    parser.add_argument("--ref-grid", required=True)
    parser.add_argument("--out", default=None)
    args = parser.parse_args(argv)

    df_res = pd.read_csv(args.results)
    df_samp = pd.read_csv(args.samples)
    fgrid = np.loadtxt(args.ref_grid, delimiter=",", skiprows=1, usecols=[0])

    mask = (fgrid >= 20.0) & (fgrid <= 300.0)

    # prepare output df copy
    df_out = df_res.copy()
    new_p95 = []
    for idx, row in df_out.iterrows():
        id_ = int(row["id"])
        samp = df_samp.loc[df_samp["id"] == id_].squeeze()
        if samp.empty:
            new_p95.append(np.nan)
            continue
        theta = {
            k: float(samp[k])
            for k in ["m1", "m2", "q0star", "alpha", "phi0", "tc", "dist", "incl"]
            if k in samp.index
        }
        phi_ref = compute_phi_ref(fgrid, float(samp["m1"]), float(samp["m2"]))
        phi_m = phi_mcgt(fgrid, theta)
        circ = np.abs(circ_diff(phi_ref, phi_m))
        p95 = float(np.percentile(circ[mask], 95))
        new_p95.append(p95)

    df_out["p95_20_300_circ"] = new_p95
    # optionally replace existing column:
    df_out["p95_20_300_recalc"] = df_out["p95_20_300_circ"]

    outpath = args.out or args.results.replace(".csv", ".circ.csv")
    df_out.to_csv(outpath, index=False)
    # petit manifeste
    man = {
        "src_results": os.path.abspath(args.results),
        "src_samples": os.path.abspath(args.samples),
        "ref_grid": os.path.abspath(args.ref_grid),
        "out_results": os.path.abspath(outpath),
        "n_rows": int(len(df_out)),
    }
    with open(outpath + ".manifest.json", "w", encoding="utf-8") as f:
        json.dump(man, f, indent=2)
    print("Écrit:", outpath)
    print("Manifeste:", outpath + ".manifest.json")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())

# === MCGT:CLI-SHIM-BEGIN ===
# Idempotent. Expose: --out/--dpi/--format/--transparent/--style/--verbose
# Ne modifie pas la logique existante : parse_known_args() au module-scope.
def _mcgt_cli_shim_parse_known():
    import argparse, sys
    p = argparse.ArgumentParser(add_help=False)
    p.add_argument("--out", type=str, default=None)
    p.add_argument("--dpi", type=int, default=None)
    p.add_argument("--format", type=str, default=None, choices=["png","pdf","svg"])
    p.add_argument("--transparent", action="store_true")
    p.add_argument("--style", type=str, default=None)
    p.add_argument("--verbose", action="store_true")
    args, _ = p.parse_known_args(sys.argv[1:])
    try:
        import matplotlib as _mpl
        if args.style:
            import matplotlib.pyplot as _plt  # init si besoin
            _mpl.style.use(args.style)
        if args.dpi and hasattr(_mpl, "rcParams"):
            _mpl.rcParams["figure.dpi"] = int(args.dpi)
    except Exception:
        # Surtout ne rien casser si l'environnement matplotlib n'est pas prêt
        pass
    return args
try:
    MCGT_CLI = _mcgt_cli_shim_parse_known()
except Exception:
    MCGT_CLI = None
# === MCGT:CLI-SHIM-END ===

#!/usr/bin/env python3
"""
generate_data_chapter01.py

Pipeline Chapitre 1 - génération des données
- Lecture robuste des jalons
- Interpolation PCHIP
- Lissage Savitzky–Golay pour P_opt et dérivée initiale
- Export complet des CSV/DAT
"""

import argparse
import pathlib
from math import log10

import numpy as np
import pandas as pd
from scipy.interpolate import PchipInterpolator, interp1d
from scipy.signal import savgol_filter


def read_jalons(path):
    df = pd.read_csv(path)
    if "T_i" in df.columns and "T" not in df.columns:
        df = df.rename(columns={"T_i": "T"})
    if "Pref" in df.columns and "P_ref" not in df.columns:
        df = df.rename(columns={"Pref": "P_ref"})
    if not set(["T", "P_ref"]).issubset(df.columns):
        df = pd.read_csv(path, header=None, names=["T", "P_ref"])
    df["T"] = pd.to_numeric(df["T"], errors="coerce")
    df["P_ref"] = pd.to_numeric(df["P_ref"], errors="coerce")
    df = df.dropna().sort_values("T")
    return df["T"].values, df["P_ref"].values


def build_grid(tmin, tmax, step, spacing):
    if spacing == "log":
        n = int((log10(tmax) - log10(tmin)) / step) + 1
        return 10 ** np.linspace(log10(tmin), log10(tmax), n)
    else:
        n = int((tmax - tmin) / step) + 1
        return np.linspace(tmin, tmax, n)


def compute_p(T_j, P_j, T_grid):
    logT = np.log10(T_j)
    logP = np.log10(P_j)
    pchip = PchipInterpolator(logT, logP)
    logTg = np.log10(T_grid)
    logPg = pchip(logTg)
    Pg = 10**logPg
    dPg = np.gradient(Pg, T_grid)
    return Pg, dPg


def main():
    parser = argparse.ArgumentParser(description="Chap1 data gen")
    parser.add_argument(
        "--csv",
        type=pathlib.Path,
        default=pathlib.Path(__file__).resolve().parents[2]
        / "zz-data"
        / "chapter01"
        / "01_timeline_milestones.csv",
    )
    parser.add_argument("--tmin", type=float, default=1e-6)
    parser.add_argument("--tmax", type=float, default=14.0)
    parser.add_argument("--step", type=float, default=0.01)
    parser.add_argument("--grid", choices=["log", "lin"], default="log")
    parser.add_argument("--window", type=int, default=21)
    parser.add_argument("--poly", type=int, default=3)
    args = parser.parse_args()

    base = args.csv.parent
    # Lecture des jalons
    T_j, P_ref = read_jalons(args.csv)

    # Lecture P_init et dérivée initiale lissée
    init_dat = np.loadtxt(base / "01_initial_grid_data.dat")
    T_init, P_init = init_dat[:, 0], init_dat[:, 1]
    dP_raw = np.gradient(P_init, T_init)
    dP_init = savgol_filter(dP_raw, window_length=args.window, polyorder=args.poly)
    pd.DataFrame({"T": T_init, "dP_dT": dP_init}).to_csv(
        base / "01_P_derivative_initial.csv", index=False
    )

    # Grille et interpolation optimisée
    T_grid = build_grid(args.tmin, args.tmax, args.step, args.grid)
    P_opt, dP_opt_raw = compute_p(T_j, P_ref, T_grid)
    dP_opt = savgol_filter(dP_opt_raw, window_length=args.window, polyorder=args.poly)

    # Exports
    pd.DataFrame({"T": T_grid, "P_calc": P_opt}).to_csv(
        base / "01_optimized_data.csv", index=False
    )
    pd.DataFrame({"T": T_grid, "dP_dT": dP_opt}).to_csv(
        base / "01_P_derivative_optimized.csv", index=False
    )
    pd.DataFrame({"T": T_grid, "P_calc": P_opt, "dP_dT": dP_opt}).to_csv(
        base / "01_optimized_data_and_derivatives.csv", index=False
    )

    # Écarts relatifs
    eps = (interp1d(T_grid, P_opt, fill_value="extrapolate")(T_j) - P_ref) / P_ref
    pd.DataFrame({"T": T_j, "epsilon": eps}).to_csv(
        base / "01_relative_error_timeline.csv", index=False
    )

    # Invariants
    pd.DataFrame({"T": T_grid, "I1": P_opt / T_grid}).to_csv(
        base / "01_dimensionless_invariants.csv", index=False
    )

    print("Chap1 data regenerated.")


if __name__ == "__main__":
    main()



# === MCGT:CLI-SHIM-BEGIN ===
# Idempotent. Expose: --out/--dpi/--format/--transparent/--style/--verbose
# Ne modifie pas la logique existante : parse_known_args() au module-scope.

def _mcgt_cli_shim_parse_known():
    import argparse, sys
    p = argparse.ArgumentParser(add_help=False)
    p.add_argument("--out", type=str, default=None, help="Chemin de sortie (optionnel).")
    p.add_argument("--dpi", type=int, default=None, help="DPI de sortie (optionnel).")
    p.add_argument("--format", type=str, default=None, choices=["png","pdf","svg"], help="Format de sortie.")
    p.add_argument("--transparent", action="store_true", help="Fond transparent si supporté.")
    p.add_argument("--style", type=str, default=None, help="Style matplotlib (optionnel).")
    p.add_argument("--verbose", action="store_true", help="Verbosité accrue.")
    args, _ = p.parse_known_args(sys.argv[1:])
    try:
        import matplotlib as _mpl
        if args.style:
            import matplotlib.pyplot as _plt  # force init si besoin
            _mpl.style.use(args.style)
        if args.dpi and hasattr(_mpl, "rcParams"):
            _mpl.rcParams["figure.dpi"] = int(args.dpi)
    except Exception:
        # Ne jamais casser le producteur si style/DPI échoue.
        pass
    return args

try:
    MCGT_CLI = _mcgt_cli_shim_parse_known()
except Exception:
    MCGT_CLI = None
# === MCGT:CLI-SHIM-END ===


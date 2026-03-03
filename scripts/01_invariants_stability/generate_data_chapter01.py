#!/usr/bin/env python
# -*- coding: utf-8 -*-
# Pipeline Chapter 1 - génération des données
# - Lecture robuste des jalons
# - Interpolation PCHIP log-log
# - Lissage Savitzky–Golay pour les dérivées
# - Export des tables normalisées CH01

import argparse
import configparser
from pathlib import Path
from math import log10

import numpy as np
import pandas as pd
import matplotlib.pyplot as plt
from scipy.interpolate import PchipInterpolator, interp1d
from scipy.signal import savgol_filter
from scipy.integrate import solve_ivp

plt.rcParams.update(
    {
        "figure.autolayout": True,
        "figure.figsize": (10, 6),
        "axes.titlesize": 14,
        "axes.titlepad": 20,
        "axes.labelsize": 12,
        "axes.labelpad": 12,
        "savefig.bbox": "tight",
        "savefig.pad_inches": 0.2,
        "font.family": "serif",
    }
)


def read_jalons(path: Path):
    """
    Lecture robuste du fichier de jalons temporels CH01.

    Accepte plusieurs variantes d'en-têtes :
    - T_i / Pref
    - T / P_ref
    - fichier sans header (2 colonnes)
    """
    df = pd.read_csv(path)

    # Harmonisation des noms de colonnes
    if "T_i" in df.columns and "T" not in df.columns:
        df = df.rename(columns={"T_i": "T"})
    if "Pref" in df.columns and "P_ref" not in df.columns:
        df = df.rename(columns={"Pref": "P_ref"})

    # Si toujours pas les bonnes colonnes, on force un header standard
    if not {"T", "P_ref"}.issubset(df.columns):
        df = pd.read_csv(path, header=None, names=["T", "P_ref"])

    df["T"] = pd.to_numeric(df["T"], errors="coerce")
    df["P_ref"] = pd.to_numeric(df["P_ref"], errors="coerce")
    df = df.dropna().sort_values("T")

    return df["T"].values, df["P_ref"].values


def build_grid(tmin: float, tmax: float, step: float, spacing: str):
    """
    Construit une grille en T sur [tmin, tmax].

    - spacing="log" : pas constant en log10(T)
    - spacing="lin" : pas constant en T
    """
    if spacing == "log":
        n = int((log10(tmax) - log10(tmin)) / step) + 1
        return np.logspace(log10(tmin), log10(tmax), n)
    else:
        n = int((tmax - tmin) / step) + 1
        return np.linspace(tmin, tmax, n)


def compute_p(T_j, P_j, T_grid):
    """
    Interpolation PCHIP en log-log des jalons (T_j, P_j)
    vers la grille T_grid.
    """
    logT = np.log10(T_j)
    logP = np.log10(P_j)
    pchip = PchipInterpolator(logT, logP, extrapolate=True)
    return 10.0 ** pchip(np.log10(T_grid))


def _safe_savgol(y: np.ndarray, window: int, poly: int):
    """
    Savitzky–Golay robuste :
    - force une fenêtre impaire
    - adapte la fenêtre si elle dépasse la taille de y
    - si vraiment trop court, renvoie y tel quel
    """
    n = y.size
    if n == 0:
        return y

    # fenêtre impaire
    if window % 2 == 0:
        window += 1

    if window > n:
        window = n if n % 2 == 1 else n - 1

    if window <= poly + 1:
        # pas assez de points pour un filtrage stable
        return y

    return savgol_filter(y, window_length=window, polyorder=poly)


def load_background_params(config_path: Path) -> dict[str, float]:
    cfg = configparser.ConfigParser(
        interpolation=None, inline_comment_prefixes=("#", ";")
    )
    if not cfg.read(config_path, encoding="utf-8"):
        raise FileNotFoundError(f"Cannot read config: {config_path}")

    cmb = cfg["cmb"]
    de = cfg["dark_energy"]
    rad = cfg["radiation"] if "radiation" in cfg else None

    h0 = cmb.getfloat("H0")
    ombh2 = cmb.getfloat("ombh2")
    omch2 = cmb.getfloat("omch2")
    h = h0 / 100.0
    omega_m = (ombh2 + omch2) / (h * h)

    tcmb = 2.7255 if rad is None else rad.getfloat("Tcmb_K")
    neff = 3.046 if rad is None else rad.getfloat("Neff")
    omega_gamma_h2 = 2.469e-5 * (tcmb / 2.7255) ** 4
    omega_r_h2 = omega_gamma_h2 * (1.0 + 0.2271 * neff)
    omega_r = omega_r_h2 / (h * h)
    omega_tmg = 1.0 - omega_m - omega_r

    return {
        "H0": h0,
        "omega_m": omega_m,
        "omega_r": omega_r,
        "omega_tmg": omega_tmg,
        "w0": de.getfloat("w0"),
        "wa": de.getfloat("wa"),
    }


def w_of_z(z: np.ndarray | float, w0: float, wa: float) -> np.ndarray:
    z_arr = np.asarray(z, dtype=float)
    return w0 + wa * z_arr / (1.0 + z_arr)


def compute_hubble_invariant(params: dict[str, float]) -> pd.DataFrame:
    z_max = 67760.0
    z_grid = np.concatenate(([0.0], np.geomspace(1.0e-8, z_max, 2400)))

    def ode(z: float, y: np.ndarray) -> np.ndarray:
        w = float(w_of_z(z, params["w0"], params["wa"]))
        return np.array([3.0 * (1.0 + w) / (1.0 + z)], dtype=float)

    sol = solve_ivp(
        ode,
        t_span=(0.0, z_max),
        y0=np.array([0.0], dtype=float),
        t_eval=z_grid,
        method="DOP853",
        atol=1.0e-18,
        rtol=1.0e-16,
    )
    if not sol.success:
        raise RuntimeError(f"CH01 background solve_ivp failed: {sol.message}")

    F_zw = np.exp(sol.y[0])
    e2 = (
        params["omega_r"] * (1.0 + z_grid) ** 4
        + params["omega_m"] * (1.0 + z_grid) ** 3
        + params["omega_tmg"] * F_zw
    )
    h2 = params["H0"] ** 2 * e2
    invariant = np.abs(h2 / (params["H0"] ** 2 * e2) - 1.0)

    return pd.DataFrame(
        {
            "z": z_grid,
            "w_z": w_of_z(z_grid, params["w0"], params["wa"]),
            "F_zw": F_zw,
            "E2": e2,
            "H_km_s_Mpc": np.sqrt(h2),
            "I_H": invariant,
        }
    )


def main():
    repo_root = Path(__file__).resolve().parents[2]

    parser = argparse.ArgumentParser(
        description="Chapter 01 – génération des données (pipeline minimal)."
    )
    parser.add_argument(
        "--csv",
        type=Path,
        default=repo_root / "assets" / "zz-data" / "01_invariants_stability" / "01_timeline_milestones.csv",
        help="Fichier de jalons temporels (T, P_ref).",
    )
    parser.add_argument("--tmin", type=float, default=1e-6, help="T_min (Gyr)")
    parser.add_argument("--tmax", type=float, default=14.0, help="T_max (Gyr)")
    parser.add_argument(
        "--step",
        type=float,
        default=0.01,
        help="Pas en log10(T) si --grid=log, ou en T si --grid=lin.",
    )
    parser.add_argument(
        "--grid",
        choices=["log", "lin"],
        default="log",
        help="Type de grille temporelle (log ou lin).",
    )
    parser.add_argument(
        "--window",
        type=int,
        default=21,
        help="Longueur de fenêtre Savitzky–Golay (impair, ajusté si besoin).",
    )
    parser.add_argument(
        "--poly",
        type=int,
        default=3,
        help="Ordre du polynôme Savitzky–Golay.",
    )
    parser.add_argument(
        "--config",
        type=Path,
        default=repo_root / "config" / "mcgt-global-config.ini",
        help="Configuration centrale pour l invariant de Hubble.",
    )

    args = parser.parse_args()

    base = args.csv.parent

    print(f"[CH01] Lecture des jalons depuis: {args.csv}")
    T_j, P_ref = read_jalons(args.csv)

    # ------------------------------------------------------------------
    # 1) Dérivée initiale (optionnelle) à partir de 01_initial_grid_data.dat
    # ------------------------------------------------------------------
    init_path = base / "01_initial_grid_data.dat"
    if init_path.exists():
        print(f"[CH01] Lecture de la grille initiale: {init_path}")
        init_dat = np.loadtxt(init_path)
        T_init, P_init = init_dat[:, 0], init_dat[:, 1]

        dP_raw = np.gradient(P_init, T_init)
        dP_init = _safe_savgol(dP_raw, window=args.window, poly=args.poly)

        df_dinit = pd.DataFrame({"T": T_init, "dP_dT": dP_init})
        df_dinit.to_csv(base / "01_P_derivative_initial.csv", index=False)
    else:
        print(
            f"[CH01] Avertissement: {init_path} introuvable, "
            "01_P_derivative_initial.csv ne sera pas produit."
        )

    # ------------------------------------------------------------------
    # 2) Grille optimisée et interpolation de P(T)
    # ------------------------------------------------------------------
    print("[CH01] Construction de la grille temporelle optimisée…")
    T_grid = build_grid(args.tmin, args.tmax, args.step, args.grid)

    print("[CH01] Interpolation PCHIP log-log sur la grille…")
    P_opt = compute_p(T_j, P_ref, T_grid)

    print("[CH01] Calcul de la dérivée optimisée…")
    dP_opt_raw = np.gradient(P_opt, T_grid)
    dP_opt = _safe_savgol(dP_opt_raw, window=args.window, poly=args.poly)

    # ------------------------------------------------------------------
    # 3) Exports principaux (CSV + DAT)
    # ------------------------------------------------------------------
    print("[CH01] Export des tables principales…")

    df_opt = pd.DataFrame({"T": T_grid, "P_calc": P_opt})
    df_opt.to_csv(base / "01_optimized_data.csv", index=False)

    # Version DAT (grille optimisée)
    np.savetxt(
        base / "01_optimized_grid_data.dat",
        np.column_stack([T_grid, P_opt]),
    )

    # Dérivée optimisée seule
    pd.DataFrame({"T": T_grid, "dP_dT": dP_opt}).to_csv(
        base / "01_P_derivative_optimized.csv", index=False
    )

    # Données + dérivée
    pd.DataFrame({"T": T_grid, "P_calc": P_opt, "dP_dT": dP_opt}).to_csv(
        base / "01_optimized_data_and_derivatives.csv", index=False
    )

    # ------------------------------------------------------------------
    # 4) Écarts relatifs sur les jalons
    # ------------------------------------------------------------------
    print("[CH01] Calcul des écarts relatifs sur les jalons…")
    interp_P = interp1d(T_grid, P_opt, kind="linear", fill_value="extrapolate")
    eps = (interp_P(T_j) - P_ref) / P_ref

    pd.DataFrame({"T": T_j, "epsilon": eps}).to_csv(
        base / "01_relative_error_timeline.csv", index=False
    )

    # ------------------------------------------------------------------
    # 5) Invariant I1 = P / T
    # ------------------------------------------------------------------
    print("[CH01] Calcul des invariants adimensionnels…")
    I1 = P_opt / T_grid
    pd.DataFrame({"T": T_grid, "I1": I1}).to_csv(
        base / "01_dimensionless_invariants.csv", index=False
    )

    # ------------------------------------------------------------------
    # 6) Invariant de Hubble de Friedmann modifiée
    # ------------------------------------------------------------------
    print("[CH01] Calcul de l invariant de Hubble modifie…")
    background = load_background_params(args.config)
    df_hubble = compute_hubble_invariant(background)
    df_hubble.to_csv(base / "01_hubble_invariant.csv", index=False)

    print("[CH01] Données du chapitre 1 régénérées avec succès.")


if __name__ == "__main__":
    main()

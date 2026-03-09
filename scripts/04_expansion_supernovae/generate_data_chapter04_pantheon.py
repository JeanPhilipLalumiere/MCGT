#!/usr/bin/env python3
from __future__ import annotations

import configparser
import json
from pathlib import Path

import numpy as np
import pandas as pd
from scipy.integrate import cumulative_trapezoid


ROOT = Path(__file__).resolve().parents[2]
CONFIG = ROOT / "config" / "mcgt-global-config.ini"
PANTHEON = ROOT / "assets" / "zz-data" / "08_sound_horizon" / "08_pantheon_data.csv"
OUT_DIR = ROOT / "assets" / "zz-data" / "04_expansion_supernovae"


def load_background() -> dict[str, float]:
    cfg = configparser.ConfigParser(interpolation=None, inline_comment_prefixes=("#", ";"))
    if not cfg.read(CONFIG, encoding="utf-8"):
        raise FileNotFoundError(CONFIG)

    cmb = cfg["cmb"]
    de = cfg["dark_energy"]
    rad = cfg["radiation"]

    h0 = cmb.getfloat("h0")
    h = h0 / 100.0
    omega_m = (cmb.getfloat("ombh2") + cmb.getfloat("omch2")) / (h * h)
    tcmb = rad.getfloat("tcmb_k")
    neff = rad.getfloat("neff")
    omega_gamma_h2 = 2.469e-5 * (tcmb / 2.7255) ** 4
    omega_r_h2 = omega_gamma_h2 * (1.0 + 0.2271 * neff)
    omega_r = omega_r_h2 / (h * h)
    omega_de = 1.0 - omega_m - omega_r

    return {
        "H0": h0,
        "omega_m": omega_m,
        "omega_r": omega_r,
        "omega_de": omega_de,
        "w0": de.getfloat("w0"),
        "wa": de.getfloat("wa"),
    }


def e2_cpl(z: np.ndarray, pars: dict[str, float], *, lcdm: bool = False) -> np.ndarray:
    w0 = -1.0 if lcdm else pars["w0"]
    wa = 0.0 if lcdm else pars["wa"]
    a = 1.0 / (1.0 + z)
    f_de = a ** (-3.0 * (1.0 + w0 + wa)) * np.exp(-3.0 * wa * (1.0 - a))
    return pars["omega_r"] * (1.0 + z) ** 4 + pars["omega_m"] * (1.0 + z) ** 3 + pars["omega_de"] * f_de


def mu_theory(z: np.ndarray, pars: dict[str, float], *, lcdm: bool = False) -> np.ndarray:
    c_km_s = 299792.458
    z_grid = np.unique(np.concatenate(([0.0], np.asarray(z, dtype=float))))
    inv_e = 1.0 / np.sqrt(e2_cpl(z_grid, pars, lcdm=lcdm))
    d_c = (c_km_s / pars["H0"]) * cumulative_trapezoid(inv_e, z_grid, initial=0.0)
    d_l = (1.0 + z_grid) * d_c
    mu = np.full_like(d_l, np.nan, dtype=float)
    positive = d_l > 0.0
    mu[positive] = 5.0 * np.log10(d_l[positive]) + 25.0
    return np.interp(z, z_grid, mu)


def main() -> None:
    OUT_DIR.mkdir(parents=True, exist_ok=True)
    pars = load_background()
    pant = pd.read_csv(PANTHEON).sort_values("z")

    mu_mcgt = mu_theory(pant["z"].to_numpy(dtype=float), pars, lcdm=False)
    mu_lcdm = mu_theory(pant["z"].to_numpy(dtype=float), pars, lcdm=True)
    residual_mcgt = mu_mcgt - pant["mu_obs"].to_numpy(dtype=float)
    residual_lcdm = mu_lcdm - pant["mu_obs"].to_numpy(dtype=float)
    delta_mu_vs_lcdm = mu_mcgt - mu_lcdm

    df = pant.copy()
    df["mu_mcgt"] = mu_mcgt
    df["mu_lcdm"] = mu_lcdm
    df["residual_mcgt"] = residual_mcgt
    df["residual_lcdm"] = residual_lcdm
    df["delta_mu_vs_lcdm"] = delta_mu_vs_lcdm
    df.to_csv(OUT_DIR / "04_pantheon_residuals.csv", index=False)

    chi2_mcgt = float(np.sum((residual_mcgt / pant["sigma_mu"].to_numpy(dtype=float)) ** 2))
    chi2_lcdm = float(np.sum((residual_lcdm / pant["sigma_mu"].to_numpy(dtype=float)) ** 2))
    summary = {
        "n_snia": int(len(df)),
        "chi2_mcgt": chi2_mcgt,
        "chi2_lcdm": chi2_lcdm,
        "delta_chi2_mcgt_minus_lcdm": chi2_mcgt - chi2_lcdm,
        "mean_delta_mu_vs_lcdm": float(np.nanmean(delta_mu_vs_lcdm)),
        "fraction_lower_distance_than_lcdm": float(np.mean(delta_mu_vs_lcdm < 0.0)),
    }
    (OUT_DIR / "04_pantheon_summary.json").write_text(json.dumps(summary, indent=2), encoding="utf-8")
    print(json.dumps(summary, indent=2))


if __name__ == "__main__":
    main()

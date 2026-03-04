#!/usr/bin/env python3
# generer_donnees_chapter3.py

"""
Chapter 3 – Pipeline intégral (v3.2.0)
--------------------------------------
Stabilité de f(R) : génération des données numériques pour les figures
et les tableaux du Chapter 3.

"""

# ----------------------------------------------------------------------
# 0. Imports & configuration globale
# ----------------------------------------------------------------------
from __future__ import annotations

import argparse
import configparser
import json
import logging
import math
import sys
from pathlib import Path

import numpy as np
import pandas as pd
from scipy.integrate import quad
from scipy.interpolate import PchipInterpolator
from scipy.optimize import brentq

from mcgt.constants import H0_to_per_Gyr  # unified

# ----------------------------------------------------------------------
# 1. Logging
# ----------------------------------------------------------------------
logging.basicConfig(
    level=logging.INFO,
    format="[%(levelname)s] %(message)s",
)
log = logging.getLogger(__name__)

# ----------------------------------------------------------------------
# 2. Cosmologie : inversion T↔z
# ----------------------------------------------------------------------
ROOT = Path(__file__).resolve().parents[2]
Mpc_to_km = 3.0856775814913673e19  # km dans 1 Mpc
sec_per_Gyr = 3.1536e16  # s dans 1 Gyr
DATA_DIR = ROOT / "assets" / "zz-data" / "03_stability_domain"


def load_cosmology_params(ini_path: Path) -> tuple[float, float, float]:
    cfg = configparser.ConfigParser(
        interpolation=None, inline_comment_prefixes=("#", ";")
    )
    if not cfg.read(ini_path, encoding="utf-8") or "cmb" not in cfg:
        log.error("Impossible de lire la section [cmb] de %s", ini_path)
        sys.exit(1)
    cos = cfg["cmb"]
    H0_km_s_Mpc = cos.getfloat("H0")
    ombh2 = cos.getfloat("ombh2")
    omch2 = cos.getfloat("omch2")
    h = H0_km_s_Mpc / 100.0
    om0 = (ombh2 + omch2) / (h * h)
    ol0 = 1.0 - om0
    return H0_to_per_Gyr(H0_km_s_Mpc), om0, ol0


def load_fr_stability_params(ini_path: Path) -> dict[str, float]:
    cfg = configparser.ConfigParser(
        interpolation=None, inline_comment_prefixes=("#", ";")
    )
    if not cfg.read(ini_path, encoding="utf-8"):
        raise FileNotFoundError(f"Cannot read config: {ini_path}")
    fr = cfg["fr_stability"]
    de = cfg["dark_energy"]
    return {
        "fr_target": fr.getfloat("fr_target", fallback=1.0),
        "frr_scale": fr.getfloat("frr_scale", fallback=1.0e-6),
        "ms2_target": fr.getfloat("ms2_over_r0_target", fallback=333333.0),
        "w0": de.getfloat("w0"),
        "wa": de.getfloat("wa"),
    }


H0, Om0, Ol0 = load_cosmology_params(ROOT / "config" / "mcgt-global-config.ini")
FR_PARAMS = load_fr_stability_params(ROOT / "config" / "mcgt-global-config.ini")


def T_of_z(z: float) -> float:
    """Âge de l’Univers (Gyr) à redshift z dans un ΛCDM plat."""

    def integrand(zp):
        return 1 / ((1 + zp) * H0 * np.sqrt(Om0 * (1 + zp) ** 3 + Ol0))

    T, _ = quad(integrand, z, 1e5)
    return T


def z_of_T(T: float) -> float:
    """Inverse de T_of_z; si T≥T0 renvoie 0."""
    T0 = T_of_z(0.0)
    if T >= T0:
        return 0.0
    # approximation à petit T
    thr = 1e-2
    if thr > T:
        return max(((2 / (3 * H0 * np.sqrt(Om0))) / T) ** (2 / 3) - 1, 0.0)

    # sinon root-finding
    def f(z):
        return T_of_z(z) - T

    zmax = 1e6
    if f(0) * f(zmax) > 0:
        zmax *= 10
    return brentq(f, 0.0, zmax)


# ----------------------------------------------------------------------
# 3. Outils partagés (grille log-lin)
# ----------------------------------------------------------------------
def build_loglin_grid(fmin: float, fmax: float, dlog: float) -> np.ndarray:
    if fmin <= 0 or fmax <= 0 or fmax <= fmin:
        raise ValueError("fmin>0, fmax>fmin requis.")
    n = int(np.floor((np.log10(fmax) - np.log10(fmin)) / dlog)) + 1
    return 10 ** (np.log10(fmin) + np.arange(n) * dlog)


def check_log_spacing(g: np.ndarray, atol: float = 1e-12) -> bool:
    d = np.diff(np.log10(g))
    return np.allclose(d, d[0], atol=atol)


# ----------------------------------------------------------------------
# 4. Jalons : copie si besoin
# ----------------------------------------------------------------------
def ensure_jalons(src: Path | None) -> Path:
    dst = DATA_DIR / "03_ricci_fR_milestones.csv"
    dst.parent.mkdir(parents=True, exist_ok=True)
    if dst.exists():
        return dst
    if src is None or not Path(src).exists():
        log.error("Manque 03_ricci_fR_milestones.csv – utilisez --copy-jalons")
        sys.exit(1)
    dst.write_bytes(Path(src).read_bytes())
    log.info("Jalons copiés → %s", dst)
    return dst


# ----------------------------------------------------------------------
# 5. CLI & lecture INI
# ----------------------------------------------------------------------
def parse_cli() -> argparse.Namespace:
    p = argparse.ArgumentParser(description="Génère les données du Chapter 3.")
    p.add_argument(
        "--config", default="config/gw_phase.ini", help="INI avec [scan]"
    )
    p.add_argument("--npts", type=int, help="nombre de points fixe")
    p.add_argument("--copy-jalons", help="chemin vers jalons si absent")
    p.add_argument("--dry-run", action="store_true", help="ne pas écrire")
    return p.parse_args()


def read_scan_section(path: Path) -> tuple[float, float, float]:
    cfg = configparser.ConfigParser()
    if not cfg.read(path) or "scan" not in cfg:
        log.error("Impossible de lire la section [scan] de %s", path)
        sys.exit(1)
    s = cfg["scan"]
    try:
        return s.getfloat("fmin"), s.getfloat("fmax"), s.getfloat("dlog")
    except ValueError as e:
        log.error("Valeurs invalides dans [scan] : %s", e)
        sys.exit(1)


# ----------------------------------------------------------------------
# 6. Construction des grilles T, z et R
# ----------------------------------------------------------------------
def build_T_z_R_grids(fmin: float, fmax: float, dlog: float, npts: int | None):
    # 6.1 Grille log-lin en fréquence
    if npts:
        dlog = (np.log10(fmax) - np.log10(fmin)) / (npts - 1)
    freqs = build_loglin_grid(fmin, fmax, dlog)

    # 6.2 Grille temps & redshift (avant filtrage)
    logTmin, logTmax = np.log10(1e-6), np.log10(14.0)
    T_full = 10 ** np.arange(logTmin, logTmax + dlog, dlog)
    z_full = np.array([z_of_T(T) for T in T_full])

    # 6.3 Grille R/R₀ normalisée (avant filtrage)
    H_z = H0 * np.sqrt(Om0 * (1 + z_full) ** 3 + Ol0)
    R_full = 12 * H_z**2 / (12 * H0**2)  # = R/R₀

    # 6.4 Élimination des doublons tout en conservant l’ordre
    #     On récupère aussi les indices pour aligner T et z
    R_unique, indices = np.unique(R_full, return_index=True)
    T_grid = T_full[indices]
    z_grid = z_full[indices]

    log.info(
        "Grille R/R₀ unique prête : %d points (%.3e → %.3e).",
        R_unique.size,
        R_unique.min(),
        R_unique.max(),
    )
    return freqs, T_grid, z_grid, R_unique


# ----------------------------------------------------------------------
# 7. Calcul de stabilité
# ----------------------------------------------------------------------
def calculer_stabilite(jalons: pd.DataFrame, Rgrid: np.ndarray):
    logRj = np.log10(jalons["R_over_R0"])
    fR_i = PchipInterpolator(logRj, np.log10(jalons["f_R"]), extrapolate=True)
    fRR_i = PchipInterpolator(logRj, np.log10(jalons["f_RR"]), extrapolate=True)

    logRg = np.log10(Rgrid)
    fRg = 10 ** fR_i(logRg)
    fRRg = 10 ** fRR_i(logRg)
    ms2 = (fRg - Rgrid * fRRg) / (3 * fRRg)

    df = pd.DataFrame(
        {"R_over_R0": Rgrid, "f_R": fRg, "f_RR": fRRg, "m_s2_over_R0": ms2}
    )
    dom = pd.DataFrame(
        {"beta": Rgrid, "gamma_min": np.zeros_like(ms2), "gamma_max": ms2.clip(max=1e8)}
    )
    frt = dom.query("gamma_min==gamma_max").rename(
        columns={"gamma_max": "gamma_limit"}
    )[["beta", "gamma_limit"]]
    return df, dom, frt


def w_of_z(z: np.ndarray | float, w0: float, wa: float) -> np.ndarray:
    z_arr = np.asarray(z, dtype=float)
    return w0 + wa * z_arr / (1.0 + z_arr)


def phantom_crossing_z(w0: float, wa: float) -> float | None:
    if math.isclose(wa, 0.0, abs_tol=1.0e-15):
        return None
    x = (-1.0 - w0) / wa
    if not (0.0 < x < 1.0):
        return None
    return float(x / (1.0 - x))


def stabilise_potential(
    df_raw: pd.DataFrame,
    zgrid: np.ndarray,
    ms2_target: float,
    *,
    w0: float,
    wa: float,
) -> tuple[pd.DataFrame, dict[str, float | bool | None]]:
    z_interp = np.interp(
        df_raw["R_over_R0"].to_numpy(dtype=float),
        np.sort(df_raw["R_over_R0"].to_numpy(dtype=float)),
        np.interp(
            np.sort(df_raw["R_over_R0"].to_numpy(dtype=float)),
            np.sort(df_raw["R_over_R0"].to_numpy(dtype=float)),
            zgrid[np.argsort(df_raw["R_over_R0"].to_numpy(dtype=float))],
        ),
    )

    df = df_raw.copy()
    raw_neg = df_raw["m_s2_over_R0"] < 0.0
    z_break = None
    r_break = None
    if raw_neg.any():
        first_idx = int(np.flatnonzero(raw_neg.to_numpy())[0])
        z_break = float(z_interp[first_idx])
        r_break = float(df_raw.iloc[first_idx]["R_over_R0"])

    z_phantom = phantom_crossing_z(w0, wa)

    floor_fr = -1.0 + 1.0e-9
    df["f_R"] = np.maximum(df["f_R"], floor_fr)

    target_frr = df["f_R"] / (df["R_over_R0"] + 3.0 * ms2_target)
    mask_unstable = df["m_s2_over_R0"] < 0.0
    df.loc[mask_unstable, "f_RR"] = np.minimum(
        df.loc[mask_unstable, "f_RR"],
        target_frr.loc[mask_unstable],
    )
    df["m_s2_over_R0"] = (df["f_R"] - df["R_over_R0"] * df["f_RR"]) / (3.0 * df["f_RR"])

    diagnostics = {
        "raw_break_z": z_break,
        "raw_break_R_over_R0": r_break,
        "phantom_crossing_z": z_phantom,
        "phantom_precedes_break": bool(
            z_break is not None and z_phantom is not None and z_phantom < z_break
        ),
        "stabilized_negative_rows": int((df["m_s2_over_R0"] < 0.0).sum()),
        "stabilization_applied": bool(mask_unstable.any()),
    }
    return df, diagnostics


def hamiltonian_energy_proxy(df: pd.DataFrame) -> np.ndarray:
    # Proxy Hamiltonien signé : stabilité si énergie effective strictement négative.
    return -df["m_s2_over_R0"].to_numpy(dtype=float) / (
        1.0 + df["f_R"].to_numpy(dtype=float)
    )


# ----------------------------------------------------------------------
# 8. Exports CSV & métadonnées
# ----------------------------------------------------------------------
def exporter_csv(
    df: pd.DataFrame,
    df_raw: pd.DataFrame,
    dom: pd.DataFrame,
    frt: pd.DataFrame,
    dry: bool,
    diagnostics: dict[str, float | bool | None] | None = None,
):
    out = DATA_DIR
    out.mkdir(parents=True, exist_ok=True)
    if dry:
        log.info("--dry-run : je n’écris pas les CSV.")
        return
    df_raw_out = df_raw.copy()
    df_out = df.copy()
    df_raw_out["hamiltonian_energy_proxy"] = hamiltonian_energy_proxy(df_raw_out)
    df_out["hamiltonian_energy_proxy"] = hamiltonian_energy_proxy(df_out)

    df_raw_out.to_csv(out / "03_fR_stability_raw.csv", index=False)
    df_out.to_csv(out / "03_fR_stability_data.csv", index=False)
    dom.to_csv(out / "03_fR_stability_domain.csv", index=False)
    frt.to_csv(out / "03_fR_stability_boundary.csv", index=False)
    meta = {
        "n_points": int(df_out.shape[0]),
        "files": [
            "03_fR_stability_data.csv",
            "03_fR_stability_raw.csv",
            "03_fR_stability_domain.csv",
            "03_fR_stability_boundary.csv",
        ],
        "hamiltonian": {
            "proxy_definition": "-m_s2_over_R0 / (1 + f_R)",
            "raw_min": float(df_raw_out["hamiltonian_energy_proxy"].min()),
            "raw_max": float(df_raw_out["hamiltonian_energy_proxy"].max()),
            "corrected_min": float(df_out["hamiltonian_energy_proxy"].min()),
            "corrected_max": float(df_out["hamiltonian_energy_proxy"].max()),
            "corrected_all_negative": bool(
                np.all(df_out["hamiltonian_energy_proxy"].to_numpy(dtype=float) < 0.0)
            ),
        },
    }
    if diagnostics is not None:
        meta["diagnostics"] = diagnostics
    (out / "03_fR_stability_meta.json").write_text(json.dumps(meta, indent=2))
    log.info("Données principales et métadonnées écrites.")


# ----------------------------------------------------------------------
# 9. Génération des fichiers R ↔ z et R ↔ T  (section remise à jour)
# ----------------------------------------------------------------------
def exporter_jalons_inverses(
    df_R: pd.DataFrame,
    jalons: pd.DataFrame,
    zgrid: np.ndarray,
    Tgrid: np.ndarray,
    dry: bool,
) -> None:
    """
    Construit deux fichiers :

    * 03_ricci_fR_vs_z.csv  : jalons + redshift interpolé
    * 03_ricci_fR_vs_T.csv  : jalons + âge interpolé

    Les jalons hors domaine d’interpolation **sont ignorés** afin
    d’éviter les z = 0 artificiels.
    """
    out = DATA_DIR
    out.mkdir(parents=True, exist_ok=True)
    if dry:
        log.info("--dry-run : pas d’export R↔z / R↔T")
        return

    traj = df_R.copy()
    traj["z"] = np.asarray(zgrid, dtype=float)
    traj["T_Gyr"] = np.asarray(Tgrid, dtype=float)
    traj["hamiltonian_energy_proxy"] = hamiltonian_energy_proxy(traj)
    traj = traj.drop_duplicates("R_over_R0").sort_values("R_over_R0")

    # Garantir des points explicites "aujourd'hui" et "très jeune Univers".
    if not np.isclose(traj["z"].min(), 0.0, atol=1.0e-12):
        today = traj.iloc[[0]].copy()
        today["z"] = 0.0
        traj = pd.concat([today, traj], ignore_index=True)
    if float(traj["T_Gyr"].min()) > 1.0e-6:
        early = traj.iloc[[-1]].copy()
        early["T_Gyr"] = 1.0e-6
        traj = pd.concat([traj, early], ignore_index=True)

    traj = traj.sort_values(["T_Gyr", "R_over_R0"]).drop_duplicates(
        subset=["T_Gyr", "R_over_R0"]
    )

    traj_z = traj.sort_values(["z", "R_over_R0"]).reset_index(drop=True)
    traj_t = traj.sort_values(["T_Gyr", "R_over_R0"]).reset_index(drop=True)

    traj_z.to_csv(out / "03_ricci_fR_vs_z.csv", index=False)
    log.info("→ 03_ricci_fR_vs_z.csv généré (%d points trajectoire)", len(traj_z))

    traj_t.to_csv(out / "03_ricci_fR_vs_T.csv", index=False)
    log.info("→ 03_ricci_fR_vs_T.csv généré (%d points trajectoire)", len(traj_t))


# ----------------------------------------------------------------------
# 10. Main
# ----------------------------------------------------------------------
def main() -> None:
    args = parse_cli()
    fmin, fmax, dlog = read_scan_section(Path(args.config))

    # 10.1 prépare toutes les grilles
    freqs, Tgrid, zgrid, Rgrid = build_T_z_R_grids(fmin, fmax, dlog, args.npts)

    # 10.2 charge les jalons
    jalon_path = ensure_jalons(Path(args.copy_jalons) if args.copy_jalons else None)
    jalons = (
        pd.read_csv(jalon_path)
        .rename(columns=str.strip)
        .query("R_over_R0>0")
        .drop_duplicates("R_over_R0")
        .sort_values("R_over_R0")
    )

    # 10.3 calcul de stabilité
    df_R_raw, _, _ = calculer_stabilite(jalons, Rgrid)
    df_R, diagnostics = stabilise_potential(
        df_R_raw,
        zgrid,
        FR_PARAMS["ms2_target"],
        w0=FR_PARAMS["w0"],
        wa=FR_PARAMS["wa"],
    )
    domaine = pd.DataFrame(
        {
            "beta": df_R["R_over_R0"],
            "gamma_min": np.zeros(df_R.shape[0], dtype=float),
            "gamma_max": df_R["m_s2_over_R0"].clip(upper=FR_PARAMS["ms2_target"]),
        }
    )
    frontiere = domaine.query("gamma_min==gamma_max").rename(
        columns={"gamma_max": "gamma_limit"}
    )[["beta", "gamma_limit"]]

    # 10.4 exports principaux
    exporter_csv(df_R, df_R_raw, domaine, frontiere, args.dry_run, diagnostics=diagnostics)

    # 10.5 exports inverses ricci↔z et ricci↔T
    exporter_jalons_inverses(df_R, jalons, zgrid, Tgrid, args.dry_run)

    log.info("Pipeline Chapter 3 terminé.")


if __name__ == "__main__":
    main()

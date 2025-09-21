#!/usr/bin/env python3
# ---IMPORTS & CONFIGURATION---

import argparse
import logging
from pathlib import Path
import json
import numpy as np
import pandas as pd
import camb

# Configuration du logging
logging.basicConfig(level=logging.INFO, format="[%(levelname)s] %(message)s")

# Parser CLI
parser = argparse.ArgumentParser(
    description="Pipeline Chapitre 6 : génération des spectres CMB MCGT"
)
parser.add_argument(
    "--alpha", type=float, default=0.0, help="Amplitude de modulation α"
)
parser.add_argument(
    "--q0star",
    type=float,
    default=0.0,
    help="Paramètre de courbure effectif q0star (Ω_k)",
)
parser.add_argument(
    "--export-derivative", action="store_true", help="Exporter la dérivée Δχ²/Δℓ"
)
args = parser.parse_args()

ALPHA = args.alpha
Q0STAR = args.q0star

# Répertoire racine du projet
ROOT = Path(__file__).resolve().parents[2]

# Répertoires de configuration et de données
CONF_DIR = ROOT / "zz-configuration"
DATA_DIR = ROOT / "zz-data" / "chapitre6"
INI_DIR = ROOT / "06-rayonnement-cmb"
DATA_DIR.mkdir(parents=True, exist_ok=True)

# ---CHARGEMENT DES COEFFICIENTS DU CHAPITRE 2---

SPEC2_FILE = ROOT / "zz-data" / "chapitre2" / "02_spec_spectre.json"
with open(SPEC2_FILE, "r", encoding="utf-8") as f:
    spec2 = json.load(f)

A_S0 = spec2["constantes"]["A_s0"]
NS0 = spec2["constantes"]["ns0"]
C1 = spec2["coefficients"]["c1"]
C2 = spec2["coefficients"]["c2"]

logging.info(f"Spectre Chap2 chargé : A_s0={A_S0}, ns0={NS0}, c1={C1}, c2={C2}")
logging.info(f"Paramètres MCGT : alpha={ALPHA}, q0star={Q0STAR}")

# ---EXPORT OPTIONNEL : A_s(α) et n_s(α) sur la grille α---

alpha_vals = np.arange(-0.1, 0.1001, 0.01)
df_alpha = pd.DataFrame(
    {
        "alpha": alpha_vals,
        "A_s": A_S0 * (1 + C1 * alpha_vals),
        "n_s": NS0 + C2 * alpha_vals,
    }
)
OUT_ALPHA = DATA_DIR / "06_alpha_evolution.csv"
df_alpha.to_csv(OUT_ALPHA, index=False)
logging.info(f"06_alpha_evolution.csv généré → {OUT_ALPHA}")

# ---CONSTANTES CMB---

ELL_MIN = 2
ELL_MAX = 3000
PK_KMAX = 10.0
DERIV_WINDOW = 7
DERIV_POLYORDER = 3

# Paramètres cosmologiques de base (Planck 2018)
cosmo_params = {
    "H0": 67.36,
    "ombh2": 0.02237,
    "omch2": 0.1200,
    "tau": 0.0544,
    "omk": 0.0,
    "mnu": 0.06,
}

# Fichiers de sortie
CLS_LCDM_DAT = DATA_DIR / "06_cls_lcdm_spectre.dat"
CLS_MCGT_DAT = DATA_DIR / "06_cls_spectre.dat"
DELTA_CLS_CSV = DATA_DIR / "06_delta_cls.csv"
DELTA_CLS_REL_CSV = DATA_DIR / "06_delta_cls_relative.csv"
JSON_PARAMS = DATA_DIR / "06_params_cmb.json"
CSV_RS_SCAN = DATA_DIR / "06_delta_rs_scan.csv"
CSV_RS_SCAN_FULL = DATA_DIR / "06_delta_rs_scan2D.csv"
CSV_CHI2_2D = DATA_DIR / "06_cmb_chi2_scan2D.csv"

# ---FONCTION D'INJECTION PHYSIQUE MCGT DANS CAMB---


def tweak_for_mcgt(pars, alpha, q0star):
    """
    Modifie CAMBparams 'pars' selon la déformation MCGT :
      • Spectre primordial : A_s = A_S0*(1 + c1*α), ns = ns0 + c2*α
      • Courbure : Ω_k = q0star
      • (Optionnel) injection de ΔT_m(k)
    """
    # 1) Spectre primordial modulé
    pars.InitPower.set_params(As=A_S0 * (1 + C1 * alpha), ns=NS0 + C2 * alpha)

    # 2) Mise à jour de la courbure
    pars.set_cosmology(
        H0=cosmo_params["H0"],
        ombh2=cosmo_params["ombh2"],
        omch2=cosmo_params["omch2"],
        tau=cosmo_params["tau"],
        omk=q0star,
        mnu=cosmo_params["mnu"],
    )

    # 3) (Optionnel) post‑processing du transfert matière ΔT_m(k)
    def post_process(results):
        tm_obj = results.get_matter_transfer_data()
        k_vals = tm_obj.q
        tm_data = tm_obj.transfer_data[0, :, 0]
        path = DATA_DIR / "06_delta_Tm_scan.csv"
        if path.exists():
            delta_k, dTm = np.loadtxt(path, delimiter=",", skiprows=1, unpack=True)
            tm_data += np.interp(k_vals, delta_k, dTm)
            tm_obj.transfer_data[0, :, 0] = tm_data
            if hasattr(results, "replace_transfer"):
                results.replace_transfer(0, tm_data)
        return results

    pars.post_process = post_process


# ---1. CHARGEMENT pdot_plateau_z---
PDOT_FILE = CONF_DIR / "pdot_plateau_z.dat"
logging.info("1) Lecture de pdot_plateau_z.dat …")
z_h, pdot = np.loadtxt(PDOT_FILE, unpack=True)
if z_h.size == 0 or pdot.size == 0:
    raise ValueError(f"Fichier invalide : {PDOT_FILE}")

z_grid = np.linspace(0, 50, 100)  # grille redshift pour matter_power

# ---2. SPECTRE Cℓ ΛCDM (CAMB)---
logging.info("2) Calcul spectre ΛCDM …")
pars0 = camb.CAMBparams()
pars0.set_for_lmax(ELL_MAX, max_eta_k=40000)
pars0.set_cosmology(
    H0=cosmo_params["H0"],
    ombh2=cosmo_params["ombh2"],
    omch2=cosmo_params["omch2"],
    tau=cosmo_params["tau"],
    omk=cosmo_params["omk"],
    mnu=cosmo_params["mnu"],
)
pars0.InitPower.set_params(As=A_S0, ns=NS0)
res0 = camb.get_results(pars0)
cmb0 = res0.get_cmb_power_spectra(pars0, lmax=ELL_MAX)["total"][:, 0]
cls0 = cmb0[: ELL_MAX + 1]
ells = np.arange(cls0.size)
np.savetxt(
    CLS_LCDM_DAT,
    np.column_stack([ells, cls0]),
    header="# ell   Cl_LCDM",
    comments="",
    fmt="%d %.6e",
)
logging.info(f"Spectre ΛCDM enregistré → {CLS_LCDM_DAT}")

# ---3. SPECTRE Cℓ MCGT (α, q0*)---
logging.info("3) Calcul spectre MCGT …")
pars1 = camb.CAMBparams()
pars1.set_for_lmax(ELL_MAX, max_eta_k=40000)
# Injection MCGT avec alpha et q0star spécifiés
tweak_for_mcgt(pars1, alpha=ALPHA, q0star=Q0STAR)
# Configuration du matter power pour MCGT
pars1.set_matter_power(redshifts=z_grid, kmax=PK_KMAX)
res1 = camb.get_results(pars1)
if hasattr(pars1, "post_process"):
    res1 = pars1.post_process(res1)
cmb1 = res1.get_cmb_power_spectra(pars1, lmax=ELL_MAX)["total"][:, 0]
cls1 = cmb1[: ells.size]
np.savetxt(
    CLS_MCGT_DAT,
    np.column_stack([ells, cls1]),
    header="# ell   Cl_MCGT",
    comments="",
    fmt="%d %.6e",
)
logging.info(f"Spectre MCGT enregistré → {CLS_MCGT_DAT}")

# ---4. ΔCℓ & ΔCℓ_rel---
logging.info("4) Calcul ΔCℓ …")
delta = cls1 - cls0
delta_rel = np.divide(delta, cls0, out=np.zeros_like(delta), where=cls0 > 0)
dfd = pd.DataFrame({"ell": ells, "delta_Cl": delta, "delta_Cl_rel": delta_rel})
dfd[["ell", "delta_Cl"]].to_csv(DELTA_CLS_CSV, index=False)
dfd[["ell", "delta_Cl_rel"]].to_csv(DELTA_CLS_REL_CSV, index=False)
logging.info(f"ΔCℓ → {DELTA_CLS_CSV}, {DELTA_CLS_REL_CSV}")

# ---5. SAUVEGARDE DES PARAMÈTRES---
logging.info("5) Sauvegarde des paramètres …")
params_out = {
    "alpha": ALPHA,
    "q0star": Q0STAR,
    "ell_min": ELL_MIN,
    "ell_max": ELL_MAX,
    "n_points": int(len(ells)),
    "thresholds": {"primary": 0.01, "order2": 0.10},
    "derivative_window": DERIV_WINDOW,
    "derivative_polyorder": DERIV_POLYORDER,
    **{k: cosmo_params[k] for k in ["H0", "ombh2", "omch2", "tau", "mnu"]},
    "As0": A_S0,
    "ns0": NS0,
    "c1": C1,
    "c2": C2,
    "max_delta_Cl_rel": float(np.nanmax(np.abs(delta_rel))),
}
with open(JSON_PARAMS, "w") as f:
    json.dump(params_out, f, indent=2)
logging.info(f"JSON paramètres → {JSON_PARAMS}")

# ---6. SCAN Δr_s EN FONCTION DE q0*---
logging.info("6) Scan Δr_s …")


def compute_rs(alpha, q0star):
    p = camb.CAMBparams()
    p.set_for_lmax(ELL_MAX, max_eta_k=40000)
    # Injecte à la fois la modulation primordial (α) et la courbure (q0star)
    tweak_for_mcgt(p, alpha=alpha, q0star=q0star)
    return camb.get_results(p).get_derived_params()["rdrag"]


# calcul de référence au couple (α, q0*)
rs_ref = compute_rs(ALPHA, Q0STAR)

q0_grid = np.linspace(-0.1, 0.1, 41)
rows_rs = []
for q0 in q0_grid:
    rs_i = compute_rs(ALPHA, q0)
    rows_rs.append(
        {"q0star": q0, "r_s": rs_i, "delta_rs_rel": (rs_i - rs_ref) / rs_ref}
    )
df_rs = pd.DataFrame(rows_rs)
df_rs[["q0star", "delta_rs_rel"]].to_csv(CSV_RS_SCAN, index=False)
df_rs.to_csv(CSV_RS_SCAN_FULL, index=False)
logging.info(f"Δr_s scan (1D)     → {CSV_RS_SCAN}")
logging.info(f"Δr_s scan complet → {CSV_RS_SCAN_FULL}")

# ---7. SCAN 2D (α, q0*) : VARIANCE COSMIQUE χ²---
logging.info("7) Scan 2D Δχ² (variance cosmique) …")


def compute_chi2_cv(alpha, q0star):
    p1 = camb.CAMBparams()
    p1.set_for_lmax(ELL_MAX, max_eta_k=40000)
    tweak_for_mcgt(p1, alpha=alpha, q0star=q0star)
    p1.set_matter_power(redshifts=z_grid, kmax=PK_KMAX)
    res_mcgt = camb.get_results(p1)
    if hasattr(p1, "post_process"):
        res_mcgt = p1.post_process(res_mcgt)
    cls_mcgt = res_mcgt.get_cmb_power_spectra(p1, lmax=ells.size - 1)["total"][:, 0]
    cls_mcgt = cls_mcgt[: ells.size]

    Δ = cls_mcgt - cls0
    var = 2.0 * cls0**2 / (2 * ells + 1)
    mask = (ells >= ELL_MIN) & (var > 0)
    chi2 = np.sum((Δ[mask] ** 2) / var[mask])
    return float(chi2)


alpha_grid = np.linspace(-0.1, 0.1, 21)
q0_grid2 = np.linspace(-0.1, 0.1, 21)
rows2d = []
for a in alpha_grid:
    for q in q0_grid2:
        rows2d.append({"alpha": a, "q0star": q, "chi2": compute_chi2_cv(a, q)})

df2d = pd.DataFrame(rows2d, columns=["alpha", "q0star", "chi2"])
df2d.to_csv(CSV_CHI2_2D, index=False)
logging.info(f"Scan 2D Δχ² → {CSV_CHI2_2D}")

# ---8. ΔT_m(k) ENTRE MCGT ET ΛCDM---

logging.info("8) Export ΔT_m(k) …")
# ΛCDM
pars0_tm = camb.CAMBparams()
pars0_tm.set_cosmology(
    H0=cosmo_params["H0"],
    ombh2=cosmo_params["ombh2"],
    omch2=cosmo_params["omch2"],
    tau=cosmo_params["tau"],
    omk=cosmo_params["omk"],
    mnu=cosmo_params["mnu"],
)
pars0_tm.InitPower.set_params(As=A_S0, ns=NS0)
pars0_tm.set_matter_power(redshifts=[0], kmax=PK_KMAX)
tm0_obj = camb.get_results(pars0_tm).get_matter_transfer_data()
k_vals = tm0_obj.q
tm0_data = tm0_obj.transfer_data[0, :, 0]

pars1_tm = camb.CAMBparams()
tweak_for_mcgt(pars1_tm, alpha=ALPHA, q0star=Q0STAR)
pars1_tm.set_matter_power(redshifts=[0], kmax=PK_KMAX)
if hasattr(pars1_tm, "post_process"):
    camb_results = pars1_tm.post_process(camb.get_results(pars1_tm))
else:
    camb_results = camb.get_results(pars1_tm)
tm1_obj = camb_results.get_matter_transfer_data()
k1 = tm1_obj.q
tm1_data = tm1_obj.transfer_data[0, :, 0]
tm1_data_interp = np.interp(k_vals, k1, tm1_data)

delta_Tm = tm1_data_interp - tm0_data

OUT_TMDAT = DATA_DIR / "06_delta_Tm_scan.csv"
with open(OUT_TMDAT, "w") as f:
    f.write("# k, delta_Tm\n")
    for k, dTm in zip(k_vals, delta_Tm):
        f.write(f"{k:.6e}, {dTm:.6e}\n")
logging.info(f"ΔT_m(k) exporté → {OUT_TMDAT}")

# ---9. (Optionnel) DUPLICAT α‑EVOLUTION---
# Conservé pour compatibilité ; génère le même fichier que plus haut
logging.info("9) (Optionnel) Regénération de 06_alpha_evolution.csv …")
df_alpha.to_csv(OUT_ALPHA, index=False)
logging.info(f"06_alpha_evolution.csv écrasé → {OUT_ALPHA}")

logging.info("=== Génération Chapitre 6 terminée ===")

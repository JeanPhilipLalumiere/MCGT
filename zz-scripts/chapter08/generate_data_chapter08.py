#!/usr/bin/env python3
# ---------------------------------------------------------------
# zz-scripts/chapter08/generer_donnees_chapitre8.py
# Pipeline de génération des données – Chapitre 8 (Couplage sombre)
# Scan 1D et 2D χ² (axe param2 « fantôme » pour la heatmap)
# ---------------------------------------------------------------

import sys
import json
import argparse
import numpy as np
import pandas as pd
from pathlib import Path
from scipy.signal import savgol_filter

# --- Permet d’importer cosmo.py depuis utils ---
ROOT  = Path(__file__).resolve().parents[2]
UTILS = ROOT / "zz-scripts" / "chapitre8" / "utils"
sys.path.insert(0, str(UTILS))
from cosmo import DV, distance_modulus, Omega_m0, Omega_lambda0

def parse_args():
    p = argparse.ArgumentParser(
        description="Génère les données du Chapitre 8 (Couplage sombre)")
    p.add_argument("--q0star_min", type=float, required=True,
                   help="Valeur minimale de q0⋆")
    p.add_argument("--q0star_max", type=float, required=True,
                   help="Valeur maximale de q0⋆")
    p.add_argument("--n_points",   type=int,   required=True,
                   help="Nombre de points dans la grille q0⋆")
    p.add_argument("--export_derivative", "--export-derivative",
                   dest="export_derivative", action="store_true",
                   help="Exporter la dérivée lissée dχ²/dq0⋆")
    p.add_argument("--export_heatmap", "--export-heatmap",
                   dest="export_heatmap", action="store_true",
                   help="Exporter le scan 2D χ²")
    p.add_argument("--param2_min", type=float,
                   help="Valeur minimale du 2ᵈ paramètre (avec --export-heatmap)")
    p.add_argument("--param2_max", type=float,
                   help="Valeur maximale du 2ᵈ paramètre (avec --export-heatmap)")
    p.add_argument("--n_param2",   type=int, default=50,
                   help="Nombre de points pour le 2ᵈ paramètre")
    return p.parse_args()

def load_or_init_params(path: Path, args):
    if path.exists():
        params = json.loads(path.read_text(encoding="utf-8"))
    else:
        params = {
            "thresholds": {"primary":0.01, "order2":0.10},
            "max_epsilon_primary": None,
            "max_epsilon_order2": None
        }
    params.update({
        "q0star_min": args.q0star_min,
        "q0star_max": args.q0star_max,
        "n_points":   args.n_points
    })
    if args.export_heatmap:
        if args.param2_min is None or args.param2_max is None:
            sys.exit("❌ --param2_min & --param2_max requis avec --export-heatmap")
        params.update({
            "param2_min": args.param2_min,
            "param2_max": args.param2_max,
            "n_param2":   args.n_param2
        })
    return params

def save_params(path: Path, params: dict):
    out = {
        "thresholds":          params["thresholds"],
        "max_epsilon_primary": params["max_epsilon_primary"],
        "max_epsilon_order2":  params["max_epsilon_order2"]
    }
    if "param2_min" in params:
        out.update({
            "param2_min": params["param2_min"],
            "param2_max": params["param2_max"],
            "n_param2":   params["n_param2"]
        })
    path.write_text(json.dumps(out, indent=2), encoding="utf-8")

def build_grid(xmin, xmax, n):
    return np.linspace(xmin, xmax, num=n)

def main():
    # Prépare les dossiers
    DATA_DIR = ROOT / "zz-data" / "chapitre8"
    FIG_DIR  = ROOT / "zz-figures" / "chapitre8"
    DATA_DIR.mkdir(parents=True, exist_ok=True)
    FIG_DIR.mkdir(parents=True, exist_ok=True)

    args        = parse_args()
    params_file = DATA_DIR / "08_params_couplage.json"
    params      = load_or_init_params(params_file, args)

    # Charge les données observées
    bao    = pd.read_csv(DATA_DIR/"08_donnees_bao.csv",    encoding="utf-8")
    pant   = pd.read_csv(DATA_DIR/"08_donnees_pantheon.csv",encoding="utf-8")
    jalons = pd.read_csv(DATA_DIR/"08_jalons_couplage.csv",encoding="utf-8")

    # Nettoyage
    bao  = bao[bao.z>0].drop_duplicates("z").sort_values("z")
    pant = pant[pant.z>0].drop_duplicates("z").sort_values("z")

    # Filtre physique sur q0⋆
    zs    = np.unique(np.concatenate([bao.z.values, pant.z.values]))
    bound = - (Omega_m0*(1+zs)**3 + Omega_lambda0) / (1+zs)**2
    q_phys_min = bound.max()
    print(f">>> Domaine physique : q0⋆ ≥ {q_phys_min:.4f}")

    # Grille q0⋆
    q0 = build_grid(params["q0star_min"], params["q0star_max"], params["n_points"])
    q0 = q0[q0>=q_phys_min]
    print(f">>> q0_grid filtré : {q0[0]:.3f} → {q0[-1]:.3f} ({len(q0)} pts)")

    # Scan 1D χ²
    chi2 = []
    for q in q0:
        dv = np.array([DV(z, q) for z in bao.z])
        mu = np.array([distance_modulus(z, q) for z in pant.z])
        cb = ((dv - bao.DV_obs)/bao.sigma_DV)**2
        cs = ((mu - pant.mu_obs)/pant.sigma_mu)**2
        chi2.append(cb.sum() + cs.sum())
    chi2 = np.array(chi2)

    # q0⋆ optimal
    iopt  = np.argmin(chi2)
    qbest = q0[iopt]
    print(f">>> q0⋆ optimal = {qbest:.4f}")

    # Export DV_th(z)
    zbao = bao.z.values
    dvb  = np.array([DV(z, qbest) for z in zbao])
    pd.DataFrame({"z":zbao, "DV_calc":dvb})\
      .to_csv(DATA_DIR/"08_dv_theorie_z.csv", index=False)
    print(">>> Exporté 08_dv_theorie_z.csv")

    # Export mu_th(z)
    zsn  = pant.z.values
    mub  = np.array([distance_modulus(z, qbest) for z in zsn])
    pd.DataFrame({"z":zsn, "mu_calc":mub})\
      .to_csv(DATA_DIR/"08_mu_theorie_z.csv", index=False)
    print(">>> Exporté 08_mu_theorie_z.csv")

    # Export scan 1D
    pd.DataFrame({
        "q0star":     q0,
        "chi2_total": chi2,
        "chi2_err":   0.10*chi2
    }).to_csv(DATA_DIR/"08_chi2_total_vs_q0.csv", index=False)
    print(">>> Exporté 08_chi2_total_vs_q0.csv")

    # Dérivée lissée
    if args.export_derivative:
        d1 = np.gradient(chi2, q0)
        w  = min(7, 2*(len(d1)//2)+1)
        ds = savgol_filter(d1, w, polyorder=3, mode="interp")
        pd.DataFrame({"q0star":q0, "dchi2_smooth":ds})\
          .to_csv(DATA_DIR/"08_derivee_chi2.csv", index=False)
        print(">>> Exporté 08_derivee_chi2.csv")

    # Scan 2D χ²
    if args.export_heatmap:
        p2 = build_grid(params["param2_min"], params["param2_max"], params["n_param2"])
        rows = []
        for q in q0:
            for val in p2:
                # val n'est pas utilisé dans DV/μ
                dv = np.array([DV(z, q) for z in bao.z])
                mu = np.array([distance_modulus(z, q) for z in pant.z])
                cb = ((dv - bao.DV_obs)/bao.sigma_DV)**2
                cs = ((mu - pant.mu_obs)/pant.sigma_mu)**2
                rows.append({"q0star":q, "param2":val, "chi2":float(cb.sum()+cs.sum())})
        pd.DataFrame(rows)\
          .to_csv(DATA_DIR/"08_chi2_scan2D.csv", index=False)
        print(">>> Exporté 08_chi2_scan2D.csv")

    # Écarts ε
    eps = []
    for _,r in jalons.iterrows():
        pred = DV(r.z,0.0) if r.jalon.startswith("BAO") else distance_modulus(r.z,0.0)
        eps.append(abs(pred - r.obs)/r.obs)
    jalons["epsilon"] = eps
    params["max_epsilon_primary"] = float(jalons.query("classe=='primaire'")["epsilon"].max())
    params["max_epsilon_order2"]  = float(jalons.query("classe=='ordre2'")["epsilon"].max())
    save_params(params_file, params)

    print("✅ Données Chapitre 8 générées avec succès")

if __name__ == "__main__":
    main()

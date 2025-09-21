import json
import numpy as np
import pandas as pd
from scipy.interpolate import PchipInterpolator
from scipy.signal import savgol_filter
from pathlib import Path

# — Répertoires —
ROOT = Path(__file__).resolve().parents[2]
DATA_DIR = ROOT / "zz-data" / "chapitre5"
DATA_DIR.mkdir(parents=True, exist_ok=True)

# — Fichiers d’entrée et de sortie —
JALONS_FILE = DATA_DIR / "05_jalons_nucleosynthese.csv"
GRILLE_FILE = DATA_DIR / "05_grille_nucleosynthese.csv"
PRED_FILE = DATA_DIR / "05_donnees_nucleosynthese.csv"
CHI2_FILE = DATA_DIR / "05_chi2_nucleosynthese_contre_T.csv"
DERIV_FILE = DATA_DIR / "05_derivee_chi2.csv"
PARAMS_FILE = DATA_DIR / "05_parametres_nucleosynthese.json"

# Seuils de classification (relative error)
THRESHOLDS = {"primary": 0.01, "order2": 0.10}

# 1) Chargement des jalons
jalons = pd.read_csv(JALONS_FILE)
jalons_DH = jalons.dropna(subset=["DH_obs"])
jalons_Yp = jalons.dropna(subset=["Yp_obs"])

# 2) Construction de la grille logarithmique en T [Gyr]
t_min, t_max = 1e-6, 14.0
log_min, log_max = np.log10(t_min), np.log10(t_max)
step = 0.01
num = int(round((log_max - log_min) / step)) + 1
T = np.logspace(log_min, log_max, num=num)
pd.DataFrame({"T_Gyr": T}).to_csv(GRILLE_FILE, index=False)

# 3) Interpolations monotones (PCHIP) en log–log
# Deutérium
interp_DH = PchipInterpolator(
    np.log10(jalons_DH["T_Gyr"]), np.log10(jalons_DH["DH_obs"]), extrapolate=True
)
DH_calc = 10 ** interp_DH(np.log10(T))

# Hélium-4
if len(jalons_Yp) > 1:
    interp_Yp = PchipInterpolator(
        np.log10(jalons_Yp["T_Gyr"]), np.log10(jalons_Yp["Yp_obs"]), extrapolate=True
    )
    Yp_calc = 10 ** interp_Yp(np.log10(T))
else:
    # Si un seul point, on met une constante
    Yp_calc = np.full_like(T, jalons_Yp["Yp_obs"].iloc[0])

# 4) Sauvegarde des prédictions
df_pred = pd.DataFrame({"T_Gyr": T, "DH_calc": DH_calc, "Yp_calc": Yp_calc})
df_pred.to_csv(PRED_FILE, index=False)

# 5) Calcul du χ² total (DH + Yp)
chi2_vals = []
for dh_c, yp_c in zip(DH_calc, Yp_calc):
    c1 = ((dh_c - jalons_DH["DH_obs"]) ** 2 / jalons_DH["sigma_DH"] ** 2).sum()
    c2 = ((yp_c - jalons_Yp["Yp_obs"]) ** 2 / jalons_Yp["sigma_Yp"] ** 2).sum()
    chi2_vals.append(c1 + c2)

pd.DataFrame({"T_Gyr": T, "chi2_nucleosynthese": chi2_vals}).to_csv(
    CHI2_FILE, index=False
)

# 6) Dérivée et lissage de χ²
dchi2_raw = np.gradient(chi2_vals, T)
# Fenêtre impair ≤ 21 pour éviter oversmoothing
win = min(21, (len(dchi2_raw) // 2) * 2 + 1)
dchi2_smooth = savgol_filter(dchi2_raw, win, polyorder=3, mode="interp")
pd.DataFrame({"T_Gyr": T, "dchi2_smooth": dchi2_smooth}).to_csv(DERIV_FILE, index=False)

# 7) Calcul des tolérances ε = |pred–obs|/obs
eps_records = []
# pour chaque jalon (DH et Yp)
for _, row in jalons.iterrows():
    if pd.notna(row["DH_obs"]):
        dh_pred = 10 ** interp_DH(np.log10(row["T_Gyr"]))
        eps = abs(dh_pred - row["DH_obs"]) / row["DH_obs"]
        eps_records.append(
            {"epsilon": eps, "sigma_rel": row["sigma_DH"] / row["DH_obs"]}
        )
    if pd.notna(row["Yp_obs"]):
        if len(jalons_Yp) > 1:
            yp_pred = 10 ** interp_Yp(np.log10(row["T_Gyr"]))
        else:
            yp_pred = jalons_Yp["Yp_obs"].iloc[0]
        eps = abs(yp_pred - row["Yp_obs"]) / row["Yp_obs"]
        eps_records.append(
            {"epsilon": eps, "sigma_rel": row["sigma_Yp"] / row["Yp_obs"]}
        )

df_eps = pd.DataFrame(eps_records)
max_e1 = df_eps[df_eps["sigma_rel"] <= THRESHOLDS["primary"]]["epsilon"].max()
max_e2 = df_eps[
    (df_eps["sigma_rel"] > THRESHOLDS["primary"])
    & (df_eps["sigma_rel"] <= THRESHOLDS["order2"])
]["epsilon"].max()

# 8) Sauvegarde des paramètres
with open(PARAMS_FILE, "w") as f:
    json.dump(
        {"max_epsilon_primary": float(max_e1), "max_epsilon_order2": float(max_e2)},
        f,
        indent=2,
    )

print("✓ Chapitre 5 : données générées avec succès.")

#!/usr/bin/env bash
set -Eeuo pipefail

trap 'code=$?;
  echo;
  echo "[ERREUR] CH08 pipeline interrompu (code $code)";
  echo "[ASTUCE] Vérifie le log ci-dessus pour identifier l étape qui a échoué.";
  exit $code' ERR

echo "== CH08 – PIPELINE MINIMAL : couplage-sombre =="

echo
echo "[INFO] Détermination automatique de la grille q0*…"

CLI_ARGS=$(python - << 'PYEOF'
from pathlib import Path
import numpy as np

path = Path("assets/zz-data/08_sound_horizon/08_chi2_total_vs_q0.csv")

# Valeurs de repli si on ne peut pas déduire proprement la grille
fallback = "--q0star_min -0.5 --q0star_max 0.5 --n_points 101"

if not path.exists():
    print(fallback)
else:
    try:
        arr = np.loadtxt(path, delimiter=",", skiprows=1)
        if arr.ndim == 1:
            qvals = np.array([float(arr[0])], dtype=float)
        else:
            qvals = arr[:, 0].astype(float)

        uq = np.unique(qvals)
        qmin = float(uq.min())
        qmax = float(uq.max())
        npts = int(uq.size)

        print(f"--q0star_min {qmin} --q0star_max {qmax} --n_points {npts}")
    except Exception:
        print(fallback)
PYEOF
)

echo "[INFO] Arguments pour generate_data_chapter08.py : ${CLI_ARGS}"

echo
echo "[1/2] Génération des données..."
python scripts/08_sound_horizon/generate_data_chapter08.py \
  ${CLI_ARGS} \
  --export_derivative

echo
echo "✅ Génération Chapter 8 OK"

echo
echo "[2/2] Génération des figures..."
python scripts/08_sound_horizon/plot_fig01_chi2_total_vs_q0.py
python scripts/08_sound_horizon/plot_fig02_dv_vs_z.py
python scripts/08_sound_horizon/plot_fig03_mu_vs_z.py
python scripts/08_sound_horizon/plot_fig04_chi2_heatmap.py
python scripts/08_sound_horizon/plot_fig05_residuals.py
python scripts/08_sound_horizon/plot_fig06_normalized_residuals_distribution.py
python scripts/08_sound_horizon/plot_fig07_chi2_profile.py

echo
echo "[OK] CH08 pipeline minimal terminé sans erreur."

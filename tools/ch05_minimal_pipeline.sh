#!/usr/bin/env bash
# Chapitre 05 – Pipeline minimal : nucléosynthèse primordiale (BBN)

set -Eeuo pipefail

echo "== CH05 – PIPELINE MINIMAL : nucleosynthese-primordiale =="
echo

###############################################################################
# 1) Génération des données BBN
###############################################################################
echo "[1/3] Génération des données..."
echo "[INFO] Script de données : zz-scripts/chapter05/generate_data_chapter05.py"
python zz-scripts/chapter05/generate_data_chapter05.py
echo "✅ Génération Chapitre 5 OK"
echo

###############################################################################
# 2) Génération des figures principales CH05
###############################################################################
echo "[2/3] Génération des figures..."

echo "[INFO] Fig. 01 – réseau de réactions BBN"
python zz-scripts/chapter05/plot_fig01_bbn_reaction_network.py
if [ -f zz-figures/chapter05/05_fig_01_bbn_reaction_network.png ]; then
  echo "Figure 01 enregistrée → zz-figures/chapter05/05_fig_01_bbn_reaction_network.png"
else
  echo "[WARN] Figure 01 introuvable après exécution du script."
fi

echo "[INFO] Fig. 02 – D/H : modèle vs observations"
python zz-scripts/chapter05/plot_fig02_dh_model_vs_obs.py
if [ -f zz-figures/chapter05/05_fig_02_dh_model_vs_obs.png ]; then
  echo "Figure 02 enregistrée → zz-figures/chapter05/05_fig_02_dh_model_vs_obs.png"
else
  echo "[WARN] Figure 02 introuvable après exécution du script."
fi

echo "[INFO] Fig. 03 – Y_p : modèle vs observations"
python zz-scripts/chapter05/plot_fig03_yp_model_vs_obs.py
if [ -f zz-figures/chapter05/05_fig_03_yp_model_vs_obs.png ]; then
  echo "Figure 03 enregistrée → zz-figures/chapter05/05_fig_03_yp_model_vs_obs.png"
else
  echo "[WARN] Figure 03 introuvable après exécution du script."
fi

echo "[INFO] Fig. 04 – χ² global en fonction de T"
python zz-scripts/chapter05/plot_fig04_chi2_vs_T.py
if [ -f zz-figures/chapter05/05_fig_04_chi2_vs_T.png ]; then
  echo "Figure 04 enregistrée → zz-figures/chapter05/05_fig_04_chi2_vs_T.png"
else
  echo "[WARN] Figure 04 introuvable après exécution du script."
fi

echo "✅ Génération des figures CH05 terminée."
echo

###############################################################################
# 3) Vérification des manifests (publication + master)
###############################################################################
echo "[3/3] Vérification des manifests (publication + master)..."
bash tools/run_diag_manifests.sh

echo
echo "[OK] CH05 pipeline minimal terminé sans erreur (données + 4 figures + manifests)."

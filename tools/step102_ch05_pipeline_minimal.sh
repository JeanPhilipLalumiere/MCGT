#!/usr/bin/env bash
set -Eeuo pipefail

# STEP102 – Pipeline minimal Chapter 05 (BBN)

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$ROOT"

mkdir -p assets/zz-data/05_primordial_bbn assets/zz-figures/05_primordial_bbn zz-logs

{
  echo "# STEP102 – Pipeline minimal Chapter 05 (BBN)"
  echo "# Root : $ROOT"
  echo

  echo "## 1) generate_data_chapter05.py"
  python scripts/05_primordial_bbn/generate_data_chapter05.py \
    || echo "[ERREUR] generate_data_chapter05.py a échoué (voir trace ci-dessus)."

  echo
  echo "## 2) plot_fig01_bbn_reaction_network.py"
  python scripts/05_primordial_bbn/plot_fig01_bbn_reaction_network.py \
    || echo "[ERREUR] plot_fig01_bbn_reaction_network.py a échoué"

  echo
  echo "## 3) plot_fig02_dh_model_vs_obs.py"
  python scripts/05_primordial_bbn/plot_fig02_dh_model_vs_obs.py \
    || echo "[ERREUR] plot_fig02_dh_model_vs_obs.py a échoué"

  echo
  echo "## 4) plot_fig03_yp_model_vs_obs.py"
  python scripts/05_primordial_bbn/plot_fig03_yp_model_vs_obs.py \
    || echo "[ERREUR] plot_fig03_yp_model_vs_obs.py a échoué"

  echo
  echo "## 5) plot_fig04_chi2_vs_T.py"
  python scripts/05_primordial_bbn/plot_fig04_chi2_vs_T.py \
    || echo "[ERREUR] plot_fig04_chi2_vs_T.py a échoué"

  echo
  echo "## 6) Inventaire rapide des outputs CH05"
  echo
  echo "### assets/zz-data/05_primordial_bbn/"
  ls -1 assets/zz-data/05_primordial_bbn || echo "[WARN] assets/zz-data/05_primordial_bbn introuvable"

  echo
  echo "### assets/zz-figures/05_primordial_bbn/"
  ls -1 assets/zz-figures/05_primordial_bbn || echo "[WARN] assets/zz-figures/05_primordial_bbn introuvable"

} | tee zz-logs/STEP102_ch05_pipeline_minimal.txt


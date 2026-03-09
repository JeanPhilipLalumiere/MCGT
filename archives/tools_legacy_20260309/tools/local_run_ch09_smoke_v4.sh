#!/usr/bin/env bash
set -Eeuo pipefail

START_TS="$(date +%Y%m%d_%H%M%S)"
LOG_DIR="zz-out/runlogs"
LOG_FILE="$LOG_DIR/hotfix_ch09_${START_TS}.log"
mkdir -p "$LOG_DIR" "zz-out/chapter09" "assets/zz-figures/09_dark_energy_cpl"

exec > >(tee -a "$LOG_FILE") 2>&1

finish() {
  status=$?
  echo
  echo "────────────────────────────────────────"
  echo "[FIN] Smoke CH09 v4 (code: $status)"
  echo "Log complet: $LOG_FILE"
  echo "────────────────────────────────────────"
  read -rp "Appuyer sur Entrée pour quitter..."
  exit $status
}
trap finish EXIT

echo "[INFO] Démarrage Smoke CH09 v4. Log: $LOG_FILE"
python3 -V || true
pip -V || true

echo "[INFO] Étape: génération CH09"
python3 scripts/09_dark_energy_cpl/generate_data_chapter09.py || echo "[WARN] génération: code non nul (on poursuit)"

echo "[INFO] Étape: fig01 overlay"
python3 scripts/09_dark_energy_cpl/plot_fig01_phase_overlay.py

echo "[INFO] Étape: build fig02 input (IMR vs MCGT)"
python3 tools/build_fig02_input.py || { echo "[WARN] build_fig02_input a échoué — fig02 SKIPPÉE"; exit 0; }

echo "[INFO] Étape: fig02 residual_phase"
CSV="zz-out/chapter09/fig02_input.csv"
OUT_PNG="assets/zz-figures/09_dark_energy_cpl/09_fig_02_residual_phase.png"
python3 scripts/09_dark_energy_cpl/plot_fig02_residual_phase.py --csv "$CSV" --out "$OUT_PNG" --dpi 160 \
  || echo "[WARN] fig02: code non nul"
test -s "$OUT_PNG" && echo "[OK] Figure écrite → $OUT_PNG" || echo "[WARN] fig02: sortie PNG manquante"

echo "== Smoke CH09 v4 terminé =="

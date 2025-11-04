#!/usr/bin/env bash
set -Eeuo pipefail

START_TS="$(date +%Y%m%d_%H%M%S)"
LOG_DIR="zz-out/runlogs"
LOG_FILE="$LOG_DIR/ch09_e2e_${START_TS}.log"
mkdir -p "$LOG_DIR" "zz-out/chapter09" "zz-figures/chapter09"

# Capturer tout dans le log ET à l'écran
exec > >(tee -a "$LOG_FILE") 2>&1

finish() {
  status=$?
  echo
  echo "────────────────────────────────────────"
  echo "[FIN] CH09 E2E (code: $status)"
  echo "Log complet: $LOG_FILE"
  echo "────────────────────────────────────────"
  read -rp "Appuyer sur Entrée pour quitter..."
  exit $status
}
trap finish EXIT

echo "[INFO] Démarrage CH09 E2E. Log: $LOG_FILE"
python3 -V || true
pip -V || true

# 1) Génération des données CH09 (robuste aux None/vides grâce aux patchs appliqués)
echo "[INFO] Étape 1/4: generate_data_chapter09.py"
python3 zz-scripts/chapter09/generate_data_chapter09.py || echo "[WARN] generate_data a renvoyé un code non nul (on continue pour diagnostiquer)"

# 2) fig01 overlay (après patch meta guard)
echo "[INFO] Étape 2/4: fig01 overlay"
python3 zz-scripts/chapter09/plot_fig01_phase_overlay.py || echo "[WARN] fig01 a renvoyé un code non nul"

# 3) Builder fig02 input (détecte colonnes IMR/MCGT, aligne fréquences)
echo "[INFO] Étape 3/4: build fig02 input"
python3 zz-tools/build_fig02_input.py

# 4) fig02 residual phase
echo "[INFO] Étape 4/4: fig02 residual_phase"
CSV="zz-out/chapter09/fig02_input.csv"
OUT_PNG="zz-figures/chapter09/09_fig_02_residual_phase.png"
python3 zz-scripts/chapter09/plot_fig02_residual_phase.py --csv "$CSV" --out "$OUT_PNG" --dpi 160 || echo "[WARN] fig02 a renvoyé un code non nul"
test -s "$OUT_PNG" && echo "[OK] Figure écrite → $OUT_PNG" || echo "[WARN] fig02: sortie PNG manquante"

echo "== CH09 E2E terminé =="

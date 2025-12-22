#!/usr/bin/env bash
set -Eeuo pipefail

START_TS="$(date +%Y%m%d_%H%M%S)"
LOG_DIR="zz-out/runlogs"
LOG_FILE="$LOG_DIR/hotfix_ch09_${START_TS}.log"
mkdir -p "$LOG_DIR"

exec > >(tee -a "$LOG_FILE") 2>&1

finish() {
  status=$?
  echo
  echo "────────────────────────────────────────"
  echo "[FIN] Smoke CH09 (code: $status)"
  echo "Log complet: $LOG_FILE"
  echo "────────────────────────────────────────"
  read -rp "Appuyer sur Entrée pour quitter..."
  exit $status
}
trap finish EXIT

echo "[INFO] Démarrage Smoke CH09. Log: $LOG_FILE"
python3 -V || true
pip -V || true

# Génération (robuste même si certains champs cfg sont None)
if ! python3 scripts/09_dark_energy_cpl/generate_data_chapter09.py; then
  echo "[WARN] generate_data_chapter09.py a renvoyé un code non nul (on continue pour collecter le contexte)"
fi

# Figure 01 (cette étape fonctionne déjà chez toi)
python3 scripts/09_dark_energy_cpl/plot_fig01_phase_overlay.py || echo "[WARN] fig01 a signalé une erreur"

# Figure 02 nécessite --csv/--out → on tente auto-détection, sinon on skippe proprement
CSV_CANDIDATE="$(ls -t zz-out/chapter09/*.csv 2>/dev/null | head -n1 || true)"
OUT_PNG="assets/zz-figures/chapter09/09_fig_02_residual_phase.png"
if [[ -n "${CSV_CANDIDATE:-}" ]]; then
  echo "[INFO] CSV détecté pour fig02: $CSV_CANDIDATE"
  mkdir -p "$(dirname "$OUT_PNG")"
  python3 scripts/09_dark_energy_cpl/plot_fig02_residual_phase.py --csv "$CSV_CANDIDATE" --out "$OUT_PNG" || echo "[WARN] fig02 a signalé une erreur"
else
  echo "[INFO] Aucun CSV détecté pour fig02 dans zz-out/chapter09/ → étape fig02 SKIPPÉE"
fi

echo "== Smoke CH09 terminé =="

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
  echo "[FIN] Smoke CH09 v2 (code: $status)"
  echo "Log complet: $LOG_FILE"
  echo "────────────────────────────────────────"
  read -rp "Appuyer sur Entrée pour quitter..."
  exit $status
}
trap finish EXIT

echo "[INFO] Démarrage Smoke CH09 v2. Log: $LOG_FILE"
python3 -V || true
pip -V || true

# 1) (Re)génération : tenter --overwrite si supporté
echo "[INFO] Étape: génération des données CH09"
if python3 scripts/09_dark_energy_cpl/generate_data_chapter09.py --help 2>/dev/null | grep -qi overwrite; then
  python3 scripts/09_dark_energy_cpl/generate_data_chapter09.py --overwrite || echo "[WARN] generate_data_chapter09: code non nul"
else
  python3 scripts/09_dark_energy_cpl/generate_data_chapter09.py || echo "[WARN] generate_data_chapter09: code non nul"
fi

# 2) Localisation des CSV utiles
CSV_DIFF=""
for p in \
  "assets/zz-data/09_dark_energy_cpl/09_phase_diff.csv" \
  "assets/zz-data/09_dark_energy_cpl/09_phase_diff_active.csv" \
  "zz-out/chapter09/09_phase_diff.csv" \
  "zz-out/chapter09/09_phase_diff_active.csv"
do
  if [ -f "$p" ]; then CSV_DIFF="$p"; break; fi
done

if [ -z "$CSV_DIFF" ]; then
  echo "[WARN] Aucun CSV Δφ trouvé pour fig02 (attendu: 09_phase_diff*.csv). Étape fig02 SKIPPÉE."
else
  echo "[INFO] CSV Δφ détecté: $CSV_DIFF"
fi

# 3) Figures clés
echo "[INFO] Étape: fig01 overlay"
python3 scripts/09_dark_energy_cpl/plot_fig01_phase_overlay.py || echo "[WARN] fig01: code non nul"

echo "[INFO] Étape: fig02 residual_phase"
if [ -n "$CSV_DIFF" ]; then
  OUT_PNG="assets/zz-figures/09_dark_energy_cpl/09_fig_02_residual_phase.png"
  python3 scripts/09_dark_energy_cpl/plot_fig02_residual_phase.py \
      --csv "$CSV_DIFF" \
      --out "$OUT_PNG" \
      --dpi 160 || echo "[WARN] fig02: code non nul"
  [ -f "$OUT_PNG" ] && echo "[INFO] Figure écrite → $OUT_PNG" || echo "[WARN] fig02: sortie PNG manquante"
else
  echo "[INFO] fig02 SKIPPÉE (pas de CSV)."
fi

echo "== Smoke CH09 v2 terminé =="

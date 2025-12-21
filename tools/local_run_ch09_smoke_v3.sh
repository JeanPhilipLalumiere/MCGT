#!/usr/bin/env bash
set -Eeuo pipefail

START_TS="$(date +%Y%m%d_%H%M%S)"
LOG_DIR="zz-out/runlogs"
LOG_FILE="$LOG_DIR/hotfix_ch09_${START_TS}.log"
mkdir -p "$LOG_DIR" "zz-out/chapter09" "assets/zz-figures/chapter09"

exec > >(tee -a "$LOG_FILE") 2>&1
finish() {
  status=$?
  echo
  echo "────────────────────────────────────────"
  echo "[FIN] Smoke CH09 v3 (code: $status)"
  echo "Log complet: $LOG_FILE"
  echo "────────────────────────────────────────"
  read -rp "Appuyer sur Entrée pour quitter..."
  exit $status
}
trap finish EXIT

echo "[INFO] Démarrage Smoke CH09 v3. Log: $LOG_FILE"
python3 -V || true
pip -V || true

echo "[INFO] Étape: génération CH09"
if python3 scripts/chapter09/generate_data_chapter09.py --help 2>/dev/null | grep -qi overwrite; then
  python3 scripts/chapter09/generate_data_chapter09.py --overwrite || echo "[WARN] generate: code non nul"
else
  python3 scripts/chapter09/generate_data_chapter09.py || echo "[WARN] generate: code non nul"
fi

# Localiser un CSV Δφ plausible
CSV_RAW=""
for p in \
  "assets/zz-data/chapter09/09_phase_diff.csv" \
  "assets/zz-data/chapter09/09_phase_diff_active.csv" \
  "zz-out/chapter09/09_phase_diff.csv" \
  "zz-out/chapter09/09_phase_diff_active.csv"
do
  if [ -f "$p" ]; then CSV_RAW="$p"; break; fi
done

if [ -z "$CSV_RAW" ]; then
  echo "[WARN] Aucun CSV Δφ trouvé → fig02 SKIPPÉE"
else
  echo "[INFO] CSV Δφ brut: $CSV_RAW"
  CSV_NORM="zz-out/chapter09/09_phase_diff.normalized.csv"
  python3 tools/normalize_phase_diff_csv.py "$CSV_RAW" "$CSV_NORM" || { echo "[WARN] Normalisation échouée → fig02 SKIPPÉE"; CSV_NORM=""; }
fi

echo "[INFO] Étape: fig01"
python3 scripts/chapter09/plot_fig01_phase_overlay.py || echo "[WARN] fig01: code non nul"

echo "[INFO] Étape: fig02"
if [ -n "${CSV_NORM:-}" ] && [ -f "$CSV_NORM" ]; then
  OUT_PNG="assets/zz-figures/chapter09/09_fig_02_residual_phase.png"
  python3 scripts/chapter09/plot_fig02_residual_phase.py \
    --csv "$CSV_NORM" \
    --out "$OUT_PNG" \
    --dpi 160 || echo "[WARN] fig02: code non nul"
  [ -f "$OUT_PNG" ] && echo "[INFO] Figure écrite → $OUT_PNG" || echo "[WARN] fig02: sortie PNG manquante"
else
  echo "[INFO] fig02 SKIPPÉE (pas de CSV normalisé)"
fi

echo "== Smoke CH09 v3 terminé =="

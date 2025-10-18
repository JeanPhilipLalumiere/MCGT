#!/usr/bin/env bash
# run_ch10_v5.sh — Relance chap.10 avec auto-flags détectés
set -Eeuo pipefail

pause_on_exit() {
  local status=$?
  echo
  echo "[DONE] Statut de sortie = $status"
  echo
  if [ -t 0 ]; then
    read -r -p "Appuyez sur Entrée pour fermer cette fenêtre (ou Ctrl+C)..." _
  else
    bash --noprofile --norc -i
  fi
}
trap pause_on_exit EXIT INT

cd ~/MCGT
conda activate mcgt-dev 2>/dev/null || source ~/miniforge3/bin/activate mcgt-dev || true

LOG=zz-manifests/last_orchestration_ch10_v5.log
mkdir -p zz-manifests
: > "$LOG"

# 0) Résolution du CSV --results
CSV_PRIO="${1:-}"
if [[ -n "$CSV_PRIO" && -r "$CSV_PRIO" ]]; then
  RESULTS="$CSV_PRIO"
else
  # auto-scan (prio chapter10/ puis zz-data/)
  RESULTS=""
  for c in \
    zz-data/chapter10/10_mc_results.circ.with_fpeak.csv \
    zz-data/chapter10/10_mc_results.circ.csv \
    zz-data/chapter10/10_mc_results.csv \
    zz-data/10_mc_results.circ.with_fpeak.csv \
    zz-data/10_mc_results.circ.csv \
    zz-data/10_mc_results.csv
  do
    if [[ -r "$c" ]]; then RESULTS="$c"; break; fi
  done
fi

if [[ -z "${RESULTS:-}" ]]; then
  echo "[ERR] Aucun CSV '10_mc_results*.csv' lisible trouvé (ni argument)."
  exit 2
fi
echo "[INFO] Using --results = $RESULTS" | tee -a "$LOG"

# 1) Générer les auto-flags
python3 tools/ch10_autoflags.py --results "$RESULTS" | tee -a "$LOG"
source zz-manifests/ch10_autoflags.env || true

# 2) Tableau des scripts chap.10
SCRIPTS=(
  "zz-scripts/chapter10/plot_fig02_scatter_phi_at_fpeak.py"
  "zz-scripts/chapter10/plot_fig03_convergence_p95_vs_n.py"
  "zz-scripts/chapter10/plot_fig03b_bootstrap_coverage_vs_n.py"
  "zz-scripts/chapter10/plot_fig04_scatter_p95_recalc_vs_orig.py"
  "zz-scripts/chapter10/plot_fig05_hist_cdf_metrics.py"
  "zz-scripts/chapter10/plot_fig06_residual_map.py"
)

# 3) Relance avec orchestrator + auto-flags
OK=0; KO=0
for s in "${SCRIPTS[@]}"; do
  base="$(basename "$s" .py)"
  var="ARGS_${base//[^A-Za-z0-9_]/_}"
  extra="${!var:-}"
  echo "[RUN] $s --results $RESULTS $extra" | tee -a "$LOG"
  if python3 tools/plot_orchestrator.py "$s" --dpi 300 --results "$RESULTS" $extra >>"$LOG" 2>&1; then
    echo "[OK ] $s" | tee -a "$LOG"
    OK=$((OK+1))
  else
    echo "[KO ] $s (voir $LOG)" | tee -a "$LOG"
    KO=$((KO+1))
  fi
done

echo
echo "=== Résumé chap.10 (v5) ==="
echo "OK : $OK"
echo "KO : $KO"
echo "Log: $LOG"

# 4) Manifeste
python3 tools/figure_manifest_builder.py | tee -a "$LOG" || true

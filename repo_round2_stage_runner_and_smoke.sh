# repo_round2_stage_runner_and_smoke.sh
set -Eeuo pipefail
TS="$(date +%Y%m%dT%H%M%S)"
LOG="/tmp/mcgt_round2_stage_runner_${TS}.log"
exec > >(tee -a "$LOG") 2>&1

_hold() {
  code=$?
  echo
  echo "[GUARD] Fin (exit=$code) — log: $LOG"
  echo "[GUARD] Appuie sur Entrée pour garder la fenêtre ouverte…"
  read -r _
}
trap _hold EXIT

echo "== CONTEXTE =="
pwd
git rev-parse --abbrev-ref HEAD || true

RUNNER="zz-scripts/chapter09/run_fig03_safe.py"

echo "== CHECK RUNNER =="
if [ ! -f "$RUNNER" ]; then
  echo "[ERR] Runner introuvable: $RUNNER"
  exit 2
fi
python -m py_compile "$RUNNER"
echo "[OK] py_compile: $RUNNER"

echo "== STAGE & COMMIT RUNNER =="
git add "$RUNNER"
git commit -m "round2: ch09/fig03 runner sûr (prefer --diff, fallback --csv; 20–300 Hz; x-log)" || echo "[NOTE] Rien à committer (peut déjà être à jour)"

echo "== MINI-SMOKE =="
set +e
PYOK=1
for f in \
  zz-scripts/chapter10/plot_fig01_iso_p95_maps.py \
  zz-scripts/chapter10/plot_fig02_scatter_phi_at_fpeak.py \
  zz-scripts/chapter10/plot_fig03_convergence_p95_vs_n.py \
  zz-scripts/chapter10/plot_fig04_scatter_p95_recalc_vs_orig.py \
  zz-scripts/chapter10/plot_fig05_hist_cdf_metrics.py \
  "$RUNNER"
do
  python -m py_compile "$f" || PYOK=0
done
set -e
[ "$PYOK" -eq 1 ] && echo "[OK] py_compile (6/6)" || echo "[WARN] py_compile: au moins un échec"

echo "== PROBE ROUND2 =="
if [ -x ./repo_probe_round2_consistency.sh ]; then
  bash ./repo_probe_round2_consistency.sh || true
else
  echo "[NOTE] repo_probe_round2_consistency.sh absent/exécutable: saut."
fi

echo "== TAG LOCAL (optionnel, sans push) =="
git tag -f v0.3.9-round2-safe-runner-${TS} || true

echo "== DONE =="

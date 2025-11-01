# repo_round2_probe_now_guarded.sh
set -Eeuo pipefail
TS="$(date +%Y%m%dT%H%M%S)"
LOG="/tmp/mcgt_round2_probe_${TS}.log"
exec > >(tee -a "$LOG") 2>&1

_guard() {
  code=$?
  echo
  echo "[GUARD] Fin (exit=$code) — log: $LOG"
  echo "[GUARD] Appuie sur Entrée pour garder la fenêtre ouverte…"
  read -r _
}
trap _guard EXIT

echo "== CONTEXTE =="
pwd
git rev-parse --abbrev-ref HEAD || true

PROBE="./repo_probe_round2_consistency.sh"

echo "== PREPARE PROBE =="
if [ ! -f "$PROBE" ]; then
  echo "[ERR] Probe absent: $PROBE"
  exit 2
fi
chmod +x "$PROBE" || true
ls -l "$PROBE" | sed 's/^/[PROBE] /'

echo "== RUN PROBE (Round2) =="
set +e
"$PROBE"
RC=$?
set -e

if [ $RC -ne 0 ]; then
  echo "[WARN] Probe a retourné $RC (affichage ci-dessus)."
else
  echo "[OK] Probe exécuté (attendu: ADD 20/20, REVIEW 16/16)."
fi

echo "== QUICK SANITY (producteurs et runner) =="
set +e
OK=1
for f in \
  zz-scripts/chapter10/plot_fig01_iso_p95_maps.py \
  zz-scripts/chapter10/plot_fig02_scatter_phi_at_fpeak.py \
  zz-scripts/chapter10/plot_fig03_convergence_p95_vs_n.py \
  zz-scripts/chapter10/plot_fig04_scatter_p95_recalc_vs_orig.py \
  zz-scripts/chapter10/plot_fig05_hist_cdf_metrics.py \
  zz-scripts/chapter09/run_fig03_safe.py
do
  python -m py_compile "$f" || OK=0
done
set -e
[ $OK -eq 1 ] && echo "[OK] py_compile (6/6)" || echo "[WARN] py_compile: au moins un échec"

echo "== DONE =="

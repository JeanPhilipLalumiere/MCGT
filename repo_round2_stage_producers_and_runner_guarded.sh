# repo_round2_stage_producers_and_runner_guarded.sh
set -Eeuo pipefail
TS="$(date +%Y%m%dT%H%M%S)"; LOG="/tmp/mcgt_round2_stage_${TS}.log"
exec > >(tee -a "$LOG") 2>&1
trap 'echo; echo "[GUARD] Fin (exit=$?) — log: $LOG"; echo "[GUARD] Entrée pour garder la fenêtre ouverte…"; read -r _' EXIT

echo "== CONTEXTE =="; pwd; git rev-parse --abbrev-ref HEAD

BR="$(git rev-parse --abbrev-ref HEAD)"
[ "$BR" = "fix/ch09-fig03-parse" ] || echo "[WARN] Branche=$BR (attendu: fix/ch09-fig03-parse)"

# Cibles probables (existence vérifiée dynamiquement)
CANDIDATES=(
  "zz-scripts/chapter09/run_fig03_safe.py"
  "zz-scripts/chapter10/plot_fig03_convergence_p95_vs_n.py"
  "zz-scripts/chapter10/plot_fig04_scatter_p95_recalc_vs_orig.py"
  "zz-scripts/chapter10/plot_fig05_hist_cdf_metrics.py"
)

TO_STAGE=()
for f in "${CANDIDATES[@]}"; do
  if [ -f "$f" ] && ! git diff --quiet -- "$f"; then
    TO_STAGE+=("$f")
  fi
done

if [ "${#TO_STAGE[@]}" -eq 0 ]; then
  echo "[NOTE] Rien à stager parmi les fichiers ciblés (déjà commit ou inchangés)."
  exit 0
fi

echo "== SANITY =="
for f in "${TO_STAGE[@]}"; do
  python -m py_compile "$f"
done
echo "[OK] py_compile sur cibles modifiées"

echo "== DIFF =="
git --no-pager diff --stat -- "${TO_STAGE[@]}"
git --no-pager diff -- "${TO_STAGE[@]}" | sed 's/^/DIFF /' | head -n 400

echo "== STAGE & COMMIT =="
git add -- "${TO_STAGE[@]}"
git commit -m "round2: stage producers ch10 modifiés + runner ch09/fig03 (safe); verrouille l’état de reproduction"

echo "== PUSH & PR NOTE =="
git push -u origin "$BR" || true

if command -v gh >/dev/null 2>&1; then
  gh pr comment "$BR" --body "Ajout: producers ch10 modifiés + runner ch09/fig03 (safe) — verrouillage Round-2."
else
  echo "[NOTE] gh non dispo — commentaire PR non posté."
fi

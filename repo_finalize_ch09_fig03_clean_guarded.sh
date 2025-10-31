# repo_finalize_ch09_fig03_clean_guarded.sh
set -Eeuo pipefail
TS="$(date +%Y%m%dT%H%M%S)"; LOG="/tmp/mcgt_finalize_ch09_fig03_${TS}.log"
exec > >(tee -a "$LOG") 2>&1
trap 'ec=$?; echo; echo "[GUARD] Fin (exit=${ec}) — log: ${LOG}"; echo "[GUARD] Appuie sur Entrée pour garder la fenêtre ouverte…"; read -r _' EXIT

echo "== CONTEXTE =="; pwd; BR="$(git rev-parse --abbrev-ref HEAD)"; echo "${BR}"
F="zz-scripts/chapter09/plot_fig03_hist_absdphi_20_300.py"

echo "== SANITY producteur =="
python -m py_compile "$F" && echo "[OK] py_compile producteur"

echo "== REGEN FIG (producteur clean) =="
OUT="zz-figures/chapter09/09_fig_03_hist_absdphi_20_300.png"
python "$F" \
  --diff zz-data/chapter09/09_phase_diff.csv \
  --out "$OUT" --dpi 150 --bins 80
ls -lh "$OUT" || true

echo "== STAGE & COMMIT producteur =="
git add "$F" || true
if git diff --cached --quiet; then
  echo "[NOTE] Rien à committer pour le producteur (inchangé)."
else
  git commit -m "ch09/fig03: producteur clean (prefer --diff, fallback --csv); fenêtre 20–300 Hz; X log"
  git push -u origin "$BR" || true
fi

echo "== PROBE Round-2 (contrôle) =="
if [[ -x ./repo_probe_round2_consistency.sh ]]; then
  bash ./repo_probe_round2_consistency.sh
else
  echo "[NOTE] Probe absente/non exécutable — saut."
fi

echo "== PR (info) =="
echo "PR en cours (attendue): https://github.com/JeanPhilipLalumiere/MCGT/pull/36"
if command -v gh >/dev/null 2>&1; then
  gh pr comment 36 --body "Producteur **clean** ch09/fig03 committé; figure régénérée; probe Round-2 OK ✅"
else
  echo "[NOTE] gh non dispo — commentaire PR non posté."
fi

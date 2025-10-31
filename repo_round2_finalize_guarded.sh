# repo_round2_finalize_guarded.sh
set -Eeuo pipefail
TS="$(date +%Y%m%dT%H%M%S)"; LOG="/tmp/mcgt_round2_finalize_${TS}.log"
exec > >(tee -a "$LOG") 2>&1
trap 'echo; echo "[GUARD] Fin (exit=$?) — log: $LOG"; echo "[GUARD] Entrée pour garder la fenêtre ouverte…"; read -r _' EXIT

echo "== CONTEXTE =="
pwd
git rev-parse --abbrev-ref HEAD || true

# 0) Paramètres
: "${TRACK_FIGS:=0}"   # 0 = ne pas versionner les PNG, 1 = les ajouter malgré .gitignore

# 1) Sanity: rendre probe exécutable
PROBE="./repo_probe_round2_consistency.sh"
[ -f "$PROBE" ] && chmod +x "$PROBE" || echo "[NOTE] Probe manquant (ok)."

# 2) S'assurer que le runner sûr est présent
RUNNER="zz-scripts/chapter09/run_fig03_safe.py"
if [ ! -f "$RUNNER" ]; then
  echo "[ERR] Runner absent: $RUNNER"; exit 2
fi
python -m py_compile "$RUNNER"

# 3) Staging minimal Round2
git add "$RUNNER" || true
git add "$PROBE" 2>/dev/null || true
# Stubs requirements déjà commités; on ne les retouche pas ici.

# 4) Option: suivre les figures (désactivé par défaut)
if [ "$TRACK_FIGS" = "1" ]; then
  # ATTENTION: .gitignore bloque peut-être; on force si souhaité.
  git add -f zz-figures/chapter09/09_fig_03_hist_absdphi_20_300.png 2>/dev/null || true
  git add -f zz-figures/chapter10/10_fig_0{1,2,3,4,5}_*.png 2>/dev/null || true
  echo "[INFO] Figures ajoutées en force (TRACK_FIGS=1)."
fi

# 5) Commit
if ! git diff --cached --quiet; then
  git commit -m "round2: lock état final (runner ch09/fig03 + probe exec); sans modifier le producteur historique"
else
  echo "[NOTE] Rien à committer (probablement déjà en place)."
fi

# 6) Probe final à nouveau (doit afficher 20/20 et 16/16)
[ -x "$PROBE" ] && "$PROBE" || echo "[NOTE] Probe non exécuté."

# 7) Tag local (optionnel, non poussé)
TAG="v0.3.9-round2-${TS}"
git tag -a "$TAG" -m "Round2 locked with safe runner ch09/fig03 (${TS})" || true
echo "[OK] Tag local: $TAG (push manuel si désiré)"

# 8) Conseils PR/push
echo
echo "== SUIVANT =="
echo "git push -u origin \$(git rev-parse --abbrev-ref HEAD) && git push origin \"$TAG\""
echo "Puis ouvre la PR vers main (titre: Round2 lock + safe-runner ch09/fig03)."

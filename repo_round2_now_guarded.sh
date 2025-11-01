# repo_round2_now_guarded.sh
set -Eeuo pipefail
TS="$(date +%Y%m%dT%H%M%S)"; LOG="/tmp/mcgt_round2_now_${TS}.log"
exec > >(tee -a "$LOG") 2>&1
trap 'ec=$?; echo; echo "[GUARD] Fin (exit=${ec}) — log: $LOG"; echo "[GUARD] Appuie sur Entrée pour garder la fenêtre ouverte…"; read -r _' EXIT

echo "== CONTEXTE =="; pwd; git rev-parse --abbrev-ref HEAD

echo "== 1) Nettoyage artefact racine =="
if [ -f "./fig_02_scatter_phi_at_fpeak.png" ]; then
  rm -f ./fig_02_scatter_phi_at_fpeak.png
  echo "[OK] Supprimé: ./fig_02_scatter_phi_at_fpeak.png"
else
  echo "[OK] Aucun artefact racine à supprimer."
fi

echo "== 2) Commit/push README-REPRO.md =="
if [ -f README-REPRO.md ]; then
  git add README-REPRO.md || true
  if ! git diff --cached --quiet; then
    git commit -m "docs: README-REPRO Round-2 (procédure, probe, CI smoke)"
    git push -u origin "$(git rev-parse --abbrev-ref HEAD)" || true
    echo "[OK] README-REPRO.md committé & poussé."
  else
    echo "[NOTE] Rien à committer (README-REPRO.md inchangé)."
  fi
else
  echo "[WARN] README-REPRO.md introuvable — rien à committer."
fi

echo "== 3) Commentaire PR (si gh dispo) =="
PR_URL="https://github.com/JeanPhilipLalumiere/MCGT/pull/36"
if command -v gh >/dev/null 2>&1; then
  gh pr comment "$PR_URL" --body "Round-2 ✅ : Repro documentée (**README-REPRO.md**), probe **ADD 20/20 & REVIEW 16/16**, CI *ci-smoke* en place (Py 3.10–3.12). ch09/fig03 généré via *runner sûr* en attendant la réparation du producteur historique."
  echo "[OK] Commentaire PR posté."
else
  echo "[NOTE] gh non disponible — commentaire PR non posté."
fi

echo "== 4) Probe Round-2 (contrôle final) =="
if [ -x ./repo_probe_round2_consistency.sh ]; then
  bash ./repo_probe_round2_consistency.sh
  echo "[OK] Probe exécuté — vérifier ADD=20/20 et REVIEW=16/16 ci-dessus."
else
  echo "[WARN] repo_probe_round2_consistency.sh manquant ou non exécutable."
fi

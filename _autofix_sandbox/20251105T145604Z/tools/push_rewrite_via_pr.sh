#!/usr/bin/env bash
# tools/push_rewrite_via_pr.sh
# Crée une branche "rewrite/…" à partir de HEAD et pousse vers origin.
# N'échoue pas la session ; messages explicites.

set -u  # pas de -e => never-fail
TS="$(date +%Y%m%dT%H%M%S)"
BASE_BRANCH="$(git symbolic-ref --short HEAD 2>/dev/null || echo main)"
NEW_BRANCH="rewrite/${BASE_BRANCH}-${TS}"
REPO_SSH="git@github.com:JeanPhilipLalumiere/MCGT.git"
REPO_HTTPS="https://github.com/JeanPhilipLalumiere/MCGT.git"

echo "[INFO] Branche locale actuelle : ${BASE_BRANCH}"
echo "[INFO] Création de la branche : ${NEW_BRANCH}"
git checkout -b "${NEW_BRANCH}" || { echo "[WARN] checkout -b a échoué (peut-être déjà dessus)"; }

if ! git remote get-url origin >/dev/null 2>&1; then
  echo "[INFO] Remote origin absent -> ajout (SSH) : $REPO_SSH"
  git remote add origin "$REPO_SSH" 2>/dev/null || true
fi

echo "[INFO] Remote :"
git remote -v || true

echo "[INFO] Push (SSH) --set-upstream --force-with-lease vers ${NEW_BRANCH}…"
if git push --set-upstream --force-with-lease origin "${NEW_BRANCH}"; then
  echo "[OK] Push SSH réussi sur ${NEW_BRANCH}."
else
  echo "[WARN] Push SSH échoué. Bascule HTTPS puis nouvel essai…"
  git remote set-url origin "$REPO_HTTPS" || true
  if git push --set-upstream --force-with-lease origin "${NEW_BRANCH}"; then
    echo "[OK] Push HTTPS réussi sur ${NEW_BRANCH}."
  else
    echo "[ERROR] Push échoué en SSH et HTTPS. Vérifie tes droits (SSH key / PAT)."
    echo "        Aide : 'ssh -T git@github.com'  |  'git remote -v'"
    exit 0
  fi
fi

cat <<EOF

──────────────── Next steps ────────────────
1) Ouvre une Pull Request vers 'main' depuis '${NEW_BRANCH}'.
2) Choisis 'Rebase and merge' ou 'Squash and merge' (pas de merge commit).
3) Après merge :
   - Informe l'équipe (reclone ou 'git fetch --all && git reset --hard origin/main').
   - Vérifie Settings ▸ Security : Secret Scanning + Push Protection.
────────────────────────────────────────────
EOF

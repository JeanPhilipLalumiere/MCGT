#!/usr/bin/env bash
# tools/push_after_rewrite_safe.sh
# Rétablit le remote si absent et pousse l'historique réécrit en --force-with-lease
# sans faire échouer le shell.

set -u  # pas de -e ici => never-fail
REPO_SSH="git@github.com:JeanPhilipLalumiere/MCGT.git"
REPO_HTTPS="https://github.com/JeanPhilipLalumiere/MCGT.git"
BRANCH="$(git symbolic-ref --short HEAD 2>/dev/null || echo main)"

echo "[INFO] Branche détectée: $BRANCH"

if ! git remote get-url origin >/dev/null 2>&1; then
  echo "[INFO] Remote 'origin' absent -> ajout (SSH) : $REPO_SSH"
  git remote add origin "$REPO_SSH" 2>/dev/null || true
fi

echo "[INFO] Remote actuel:"
git remote -v || true

echo "[INFO] Fetch origin (si dispo)…"
git fetch origin || echo "[WARN] fetch échoué (probablement origin inaccessible pour le moment)."

echo "[INFO] Tentative de push (SSH) --force-with-lease…"
if git push --force-with-lease origin "$BRANCH"; then
  echo "[OK] Push (SSH) réussi."
else
  echo "[WARN] Push SSH échoué. Bascule HTTPS et nouvel essai…"
  git remote set-url origin "$REPO_HTTPS" || true
  if git push --force-with-lease origin "$BRANCH"; then
    echo "[OK] Push (HTTPS) réussi."
  else
    echo "[ERROR] Push échoué en SSH et HTTPS. Vérifie tes droits et ton auth (SSH key / PAT)."
    echo "        Commandes utiles :"
    echo "          git remote -v"
    echo "          ssh -T git@github.com   # pour tester la clé SSH"
    echo "          git config --get user.name && git config --get user.email"
  fi
fi

# Conseils post-push (non bloquants)
echo "[NOTE] Après push: prévenir l'équipe de recloner ou 'git fetch --all && git reset --hard origin/$BRANCH'."
echo "[NOTE] Pense à vérifier GitHub ➝ Settings ➝ Security: Secret Scanning + Push Protection."

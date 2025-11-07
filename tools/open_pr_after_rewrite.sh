#!/usr/bin/env bash
# tools/open_pr_after_rewrite.sh
# Ouvre une PR vers main avec gh si dispo, sinon affiche l'URL.
set -u  # pas de -e => never-fail

BR="rewrite/main-20251026T134200"
TITLE="Rewrite history: purge *.log & redact PyPI patterns"
BODY=$'## Contexte\n- Réécriture de l’historique (git-filter-repo)\n  - Purge des *.log\n  - Rédaction des motifs PyPI\n- Mise en place des garde-fous (.gitattributes, hook pre-commit)\n\n## Vérifications à faire avant merge\n- [ ] CI passe ✅\n- [ ] Diff fonctionnel ok (pas de pertes de sources)\n- [ ] Choisir **Rebase and merge** ou **Squash and merge** (pas de merge commit)\n\n## Post-merge\n- [ ] Informer l’équipe (reclone ou `git fetch --all && git reset --hard origin/main`)\n- [ ] Vérifier *Settings ▸ Security*: Secret Scanning + Push Protection'
URL="https://github.com/JeanPhilipLalumiere/MCGT/pull/new/${BR}"

echo "[INFO] Cible de PR: ${BR} -> main"

if command -v gh >/dev/null 2>&1; then
  # s’assure d’être sur la branche source côté local
  git checkout "${BR}" >/dev/null 2>&1 || true
  echo "[INFO] Tentative d’ouverture de PR via gh…"
  if gh pr create --base main --head "${BR}" --title "${TITLE}" --body "${BODY}" ; then
    echo "[OK] PR créée avec gh."
  else
    echo "[WARN] gh pr create a échoué. Ouvre manuellement : ${URL}"
  fi
else
  echo "[INFO] gh non présent. Ouvre la PR manuellement :"
  echo "      ${URL}"
fi

cat <<'EOF'

──────── Rappels fusion ────────
• Sélectionner “Rebase and merge” ou “Squash and merge” (évite les merge commits).
• Vérifier que la CI est verte.
• Après merge : informer l’équipe et valider la sécurité (Secret Scanning + Push Protection).
───────────────────────────────
EOF

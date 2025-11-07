#!/usr/bin/env bash
set -euo pipefail
# Échoue si des fichiers marqués 'SAFE PLACEHOLDER' existent (sauf branches dev)
BRANCH="$(git rev-parse --abbrev-ref HEAD || echo HEAD)"
if [[ "${BRANCH}" =~ ^(main|release/|hotfix/) ]]; then
  if grep -RIl --include="*.py" "SAFE PLACEHOLDER (compilable)" . | grep -vE '^(_attic_untracked|_autofix_sandbox|_tmp|release_zenodo_codeonly|\.git)/' >/dev/null; then
    echo "❌ Placeholders détectés sur ${BRANCH} — remplace avant release."
    exit 1
  fi
fi
echo "✅ Aucun placeholder bloquant sur ${BRANCH}."

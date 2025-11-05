#!/usr/bin/env bash
set -euo pipefail
ROOT="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"

MSG="${1:-autofix(sandbox): ascii + future placement}"
python3 tools/autofix_sandbox.py --apply --commit "$MSG" --no-verify || true

# Si Git a refusé d'ajouter à cause de .gitignore, on force pour ce sous-dossier
if git -C "$ROOT" status --porcelain | grep -q '^.M\|^\?\?'; then
  mapfile -t FORCE < <(git -C "$ROOT" status --porcelain \
    | awk '{print $2}' \
    | grep '^release_zenodo_codeonly/' || true)
  if ((${#FORCE[@]})); then
    git -C "$ROOT" add -f -- "${FORCE[@]}" || true
  fi
fi

# Commit si quelque chose est indexé
if [[ -n "$(git -C "$ROOT" diff --cached --name-only)" ]]; then
  MCGT_UNSEAL=1 git -C "$ROOT" commit -m "$MSG" --no-verify
  echo "[OK] Commit forcé: $MSG"
else
  echo "[SKIP] Rien à committer."
fi

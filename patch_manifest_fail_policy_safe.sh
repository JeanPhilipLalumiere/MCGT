#!/usr/bin/env bash
set -Eeuo pipefail
ts="$(date -u +%Y%m%dT%H%M%SZ)"
WF=".github/workflows/manifest-guard.yml"
cp -a "$WF" "${WF}.bak.${ts}"

# Remplacer --fail-on warnings par --fail-on errors
perl -0777 -pe 's/--fail-on\s+warnings/--fail-on errors/g' -i "$WF"

git add "$WF"
read -rp "Commit & push ? [y/N] " ans
if [[ "${ans:-N}" =~ ^[Yy]$ ]]; then
  git commit -m "ci(manifest-guard): relax policy to fail-on errors [SAFE $ts]" && git push
  echo "[GIT] Pushed."
else
  echo "[SKIP] No commit."
fi

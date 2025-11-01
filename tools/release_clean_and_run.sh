#!/usr/bin/env bash
set -Eeuo pipefail

NEWVER="${1:-}"
[[ -n "$NEWVER" ]] || { echo "[ERR] Usage: $0 NEW_VERSION"; exit 2; }

ROOT="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"; cd "$ROOT"
echo "[INFO] repo=$ROOT  new_version=$NEWVER"

# Stash si sale (inclut non suivis)
STASHED=0
if ! git diff --quiet || ! git diff --cached --quiet; then
  echo "[WARN] Working tree non propre — stash temporaire."
  git stash push -u -m "pre-release-stash $(date -u +%Y%m%dT%H%M%SZ)" >/dev/null
  STASHED=1
fi

cleanup() {
  if [[ "${STASHED}" -eq 1 ]]; then
    echo "[INFO] Restauration du stash..."
    git stash pop >/dev/null || echo "[WARN] Rien à pop ou conflits à résoudre manuellement."
  fi
}
trap cleanup EXIT

# 1) Sécurité : smoke --help global si dispo
if [[ -x tools/smoke_help_repo.sh ]]; then
  bash tools/smoke_help_repo.sh
fi

# 2) Remise au propre stricte AVANT bump (neutralise diffs furtifs)
echo "[INFO] Remise au propre stricte (git reset --hard)"
git reset --hard HEAD

# 3) Double-check propreté
if ! git diff --quiet || ! git diff --cached --quiet; then
  echo "[WARN] Il reste des diffs, nouveau stash minimal."
  git stash push -u -m "pre-bump-extra $(date -u +%Y%m%dT%H%M%SZ)" >/dev/null
  STASHED=1
fi

# 4) Bump + tag + push (+ GH release)
bash tools/release_bump_and_publish.sh "${NEWVER}" 1

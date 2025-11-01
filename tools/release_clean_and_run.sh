#!/usr/bin/env bash
set -Eeuo pipefail

NEWVER="${1:-}"
[[ -n "$NEWVER" ]] || { echo "[ERR] Usage: $0 NEW_VERSION"; exit 2; }

ROOT="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"; cd "$ROOT"
echo "[INFO] repo=$ROOT  new_version=$NEWVER"

LAST_RPT="$(ls -1 _tmp/smoke_help_*/report.tsv 2>/dev/null | tail -n1 || true)"
LAST_LOG="$(ls -1 _tmp/smoke_help_*/run.log    2>/dev/null | tail -n1 || true)"

STASHED=0
cleanup() {
  if [[ "${STASHED}" -eq 1 ]]; then
    echo "[INFO] Restauration du stash..."
    if ! git stash pop >/dev/null; then
      echo "[WARN] Conflits ou stash déjà consommé — à résoudre manuellement."
    fi
  fi
}
trap cleanup EXIT

# Stash si working tree sale (incluant non suivis)
if ! git diff --quiet || ! git diff --cached --quiet; then
  echo "[WARN] Working tree non propre — stash temporaire pour figer la release."
  git stash push -u -m "pre-release-stash $(date -u +%Y%m%dT%H%M%SZ)" >/dev/null
  STASHED=1
fi

# Sécurité: smoke --help global si dispo
if [[ -x tools/smoke_help_repo.sh ]]; then
  bash tools/smoke_help_repo.sh
fi

# Bump+tag+push (+ GitHub release si possible)
bash tools/release_bump_and_publish.sh "${NEWVER}" 1

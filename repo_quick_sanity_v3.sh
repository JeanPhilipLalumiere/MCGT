#!/usr/bin/env bash
# repo_quick_sanity_v3.sh — snapshot court, non intrusif
set -euo pipefail
ROOT="$(git rev-parse --show-toplevel)"; cd "$ROOT"
mkdir -p _tmp _logs
TS="$(date -u +%Y%m%dT%H%M%SZ)"
OUT="_tmp/snapshot_${TS}"
mkdir -p "$OUT"

echo "[INFO] Snapshot protections → $OUT/protection.json"
gh api repos/:owner/:repo/branches/main/protection > "$OUT/protection.json" || true

echo "[INFO] Derniers runs CI (main) → $OUT/ci_runs.txt"
gh run list --branch main --limit 25 > "$OUT/ci_runs.txt" || true

echo "[INFO] Inventaire .bak (hors attic/) → $OUT/bak_outside_attic.txt"
{ git ls-files -z | tr '\0' '\n' | grep -E '\.bak($|\.)' || true; \
  git ls-files -o -z | tr '\0' '\n' | grep -E '\.bak($|\.)' || true; } \
  | grep -v '^attic/' | sort -u > "$OUT/bak_outside_attic.txt" || true

echo "[INFO] Untracked lourds (top) → $OUT/untracked_top.txt"
git status --porcelain | awk '$1=="??"{print $2}' | head -n 200 > "$OUT/untracked_top.txt" || true

echo "[DONE] Dossier: $OUT"
read -r -p $'Terminé. ENTER pour fermer…\n' _ </dev/tty || true

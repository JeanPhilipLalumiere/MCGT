#!/usr/bin/env bash
# purge_untracked_caches_guarded.sh — nettoie les restes non suivis (dry-run+confirm)
set -euo pipefail
REPO="$(git rev-parse --show-toplevel)"; cd "$REPO"
TS="$(date -u +%Y%m%dT%H%M%SZ)"
OUT="_tmp/untracked_scan_${TS}.txt"; mkdir -p _tmp

echo "[SCAN] Untracked _tmp/ & backups/"
: > "$OUT"
git clean -ndX | sed -n '1,200p' | tee -a "$OUT" || true
echo
read -r -p $'Purger réellement ces non-suivis (_tmp/, backups/)? [o/N] ' ans </dev/tty || true
[[ "${ans:-N}" =~ ^[oOyY]$ ]] || { echo "Abandon (dry-run seulement)."; exit 0; }

# On cible prudemment
git clean -fdX _tmp backups || true

# Checkpoint Round2 à jour
bash round2_checkpoint_robuste.sh || true

read -r -p $'Terminé. ENTER pour fermer…\n' _ </dev/tty || true

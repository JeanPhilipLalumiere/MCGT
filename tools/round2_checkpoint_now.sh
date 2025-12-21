#!/usr/bin/env bash
# round2_checkpoint_now.sh — inventaire TODO/FIXME/SAFE_DELETE, candidats attic/, delta manifeste (RO)
set -euo pipefail

ROOT="$(git rev-parse --show-toplevel)"; cd "$ROOT"
mkdir -p _tmp
TS="$(date -u +%Y%m%dT%H%M%SZ)"
OUTDIR="_tmp/round2_checkpoint_${TS}"; mkdir -p "$OUTDIR"

echo "[1/4] TODO/FIXME/SAFE_DELETE → $OUTDIR/todos.txt"
git ls-files | grep -Ev '^attic/' | xargs -I{} sh -c \
  'grep -En "(TODO|FIXME|SAFE_DELETE)" "{}" || true' > "$OUTDIR/todos.txt" || true

echo "[2/4] Candidats attic/ → $OUTDIR/attic_candidates.txt"
git ls-files | grep -Ev '^attic/' \
  | grep -Ei '\.(bak|old|orig|tmp|lock|log)$' \
  > "$OUTDIR/attic_candidates.txt" || true

echo "[3/4] Delta manifeste → $OUTDIR/manifest_delta.txt"
if [[ -f assets/zz-manifests/manifest_master.json ]]; then
  # fichiers suivis non listés dans le manifest
  git ls-files | grep -Ev '^attic/' \
    | awk '{print $0}' > "$OUTDIR/_tracked.txt"
  jq -r '..|.path? // empty' assets/zz-manifests/manifest_master.json \
    | sort -u > "$OUTDIR/_manifest_paths.txt"
  comm -23 <(sort "$OUTDIR/_tracked.txt") <(sort "$OUTDIR/_manifest_paths.txt") \
    > "$OUTDIR/manifest_delta.txt"
else
  echo "(absent) assets/zz-manifests/manifest_master.json" > "$OUTDIR/manifest_delta.txt"
fi

echo "[4/4] Synthèse:"
echo " - $OUTDIR/todos.txt"
echo " - $OUTDIR/attic_candidates.txt"
echo " - $OUTDIR/manifest_delta.txt"
read -r -p $'Terminé. ENTER pour fermer…\n' _ </dev/tty || true

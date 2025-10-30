#!/usr/bin/env bash
# round2_checkpoint_robuste.sh — rapports RO avec gestion espaces/UTF-8 et exclusions
set -euo pipefail
ROOT="$(git rev-parse --show-toplevel)"; cd "$ROOT"
mkdir -p _tmp
TS="$(date -u +%Y%m%dT%H%M%SZ)"
OUT="_tmp/round2_checkpoint_${TS}"; mkdir -p "$OUT"

echo "[1/4] TODO/FIXME/SAFE_DELETE → $OUT/todos.txt"
: > "$OUT/todos.txt"
git -c core.quotepath=false ls-files -z \
| while IFS= read -r -d '' f; do
  case "$f" in
    attic/*|_attic_untracked/*|_snapshots/*) continue;;
  esac
  # grep binaire-safe (-a), motif étendu, encodage tolérant
  LC_ALL=C.UTF-8 grep -aEn '(TODO|FIXME|SAFE_DELETE)' -- "$f" >> "$OUT/todos.txt" || true
done

echo "[2/4] Candidats attic/ → $OUT/attic_candidates.txt"
: > "$OUT/attic_candidates.txt"
git -c core.quotepath=false ls-files -z \
| while IFS= read -r -d '' f; do
  case "$f" in
    attic/*|_attic_untracked/*|_snapshots/*) continue;;
  esac
  if echo "$f" | grep -Eiq '\.(bak|old|orig|tmp|lock|log)$'; then
    echo "$f" >> "$OUT/attic_candidates.txt"
  fi
done

echo "[3/4] Delta manifeste → $OUT/manifest_delta.txt"
if [[ -f zz-manifests/manifest_master.json ]]; then
  git -c core.quotepath=false ls-files | grep -Ev '^attic/|^_attic_untracked/|^_snapshots/' \
    | sort -u > "$OUT/_tracked.txt"
  jq -r '..|.path? // empty' zz-manifests/manifest_master.json \
    | sort -u > "$OUT/_manifest_paths.txt"
  comm -23 "$OUT/_tracked.txt" "$OUT/_manifest_paths.txt" > "$OUT/manifest_delta.txt" || true
else
  echo "(absent) zz-manifests/manifest_master.json" > "$OUT/manifest_delta.txt"
fi

echo "[4/4] Synthèse:"
printf ' - %s\n - %s\n - %s\n' \
  "$OUT/todos.txt" "$OUT/attic_candidates.txt" "$OUT/manifest_delta.txt"

read -r -p $'Terminé. ENTER pour fermer…\n' _ </dev/tty || true

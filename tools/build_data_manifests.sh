#!/usr/bin/env bash
set -Eeuo pipefail
ROOT="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"; cd "$ROOT"
source tools/_lib_trap_exit.sh || true
TS="$(date -u +%Y%m%d_%H%M%S)"
LOG=".ci-logs/data_manifest_${TS}.log"
exec > >(tee -a "$LOG") 2>&1
mcgt_install_exit_trap "$LOG"

DATADIR="${DATADIR:-zz-data}"
OUT="${OUT:-zz-manifests/manifest_data.sha256sum}"
OUTMD="${OUTMD:-zz-manifests/data_per_chapter.md}"
drel="$(realpath --relative-to="$ROOT" "$DATADIR" 2>/dev/null || echo "$DATADIR")"
mkdir -p "$(dirname "$OUT")"
echo "== Build data manifest =="
if [ -d "$drel" ]; then
  LC_ALL=C find "$drel" -type f ! -path "$drel/_legacy_conflicts/*" '!' -name "*.bak*" '!' -name "*.lock*" '!' -name "*.tmp*" \
    \( -iname "*.csv" -o -iname "*.json" -o -iname "*.parquet" -o -iname "*.npz" -o -iname "*.npy" -o -iname "*.fits" \) -print0 \
  | LC_ALL=C sort -z \
  | xargs -0 -I{} sha256sum "{}" > "$OUT" || :
else
  : > "$OUT"
fi
[ -s "$OUT" ] || : > "$OUT"
echo "Manifest écrit: $OUT ($(wc -l < "$OUT") fichiers)"

echo "== Data per chapter =="
tmpc="/tmp/data_counts_${TS}.csv"
if [ -d "$drel" ]; then
  LC_ALL=C find "$drel" -type f -print \
  | awk -v d="$drel" '{p=$0; sub("^" d "/?", "", p); split(p,a,"/"); ch=a[1]; if (ch ~ /^chapter[0-9][0-9]$/) c[ch]++} END{for(k in c) printf "%s,%d\n",k,c[k]}' \
  | LC_ALL=C sort > "$tmpc"
else
  : > "$tmpc"
fi
{ printf "# Données par chapitre\n\n"; printf "| Chapitre | Fichiers |\\n|---|---|\\n";
  if [ -s "$tmpc" ]; then while IFS=, read -r ch n; do printf "| %s | %s |\\n" "$ch" "$n"; done < "$tmpc"; fi; } > "$OUTMD"
echo "Résumé écrit: $OUTMD"

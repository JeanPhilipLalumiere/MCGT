#!/usr/bin/env bash
set -euo pipefail

M="zz-manifests/manifest_master.json"
OUT="_tmp/manifest_audit.tsv"
MIN_SIZE=""
FILTER_PATHS=""
ALL=0

while [[ $# -gt 0 ]]; do
  case "$1" in
    --min-size) MIN_SIZE="$2"; shift 2 ;;
    --paths) FILTER_PATHS="$2"; shift 2 ;;
    --all) ALL=1; shift ;;
    *) shift ;;
  esac
done

mkdir -p _tmp

echo "Manifest: $M"
echo "Output TSV: $OUT"
echo "Filter: paths=${FILTER_PATHS}"
echo

# Prépare la sélection jq
if [[ -n "$FILTER_PATHS" ]]; then
  # valeurs séparées par virgules attendues
  JQ_FILTER=".entries | map(select(.path | IN(${FILTER_PATHS})))"
elif [[ -n "$MIN_SIZE" ]]; then
  JQ_FILTER=".entries | map(select((.size_bytes // 0) >= (${MIN_SIZE}|tonumber)))"
elif [[ "$ALL" == "1" ]]; then
  JQ_FILTER=".entries"
else
  JQ_FILTER=".entries | map(select((.size_bytes // 0) >= 100000))"
fi

jq -r "$JQ_FILTER | map([.path, (.sha256//\"\"), (.size_bytes//0), (.git_hash//\"\" )] | @tsv) | .[]" "$M" > _tmp/_manifest_rows.tsv || true

mapfile -t ROWS < _tmp/_manifest_rows.tsv || true
echo "Entries to check: ${#ROWS[@]}"
echo
printf "%0.s." $(seq 1 ${#ROWS[@]}); echo

{
  echo -e "path\tmanifest_sha256\tmanifest_size\tmanifest_git_hash\thead_blob_sha1\thead_blob_size\thead_blob_sha256\trecovered_sha256\trecovered_size\tstatus"
  n_bad=0
  for line in "${ROWS[@]}"; do
    path="$(printf '%s' "$line" | awk -F'\t' '{print $1}')"
    msha="$(printf '%s' "$line" | awk -F'\t' '{print $2}')"
    msize="$(printf '%s' "$line" | awk -F'\t' '{print $3}')"
    mgit="$(printf '%s' "$line" | awk -F'\t' '{print $4}')"

    head_sha1=""; head_size=""; head_sha256=""
    if git ls-files --error-unmatch -- "$path" >/dev/null 2>&1; then
      head_sha1="$(git ls-files -s -- "$path" | awk '{print $2}')"
      if [[ -n "$head_sha1" ]]; then
        head_size="$(git cat-file -s "$head_sha1" 2>/dev/null || echo "")"
        head_sha256="$(git cat-file -p "$head_sha1" 2>/dev/null | sha256sum | awk '{print $1}')"
      fi
    fi

    rec_sha=""; rec_size=""
    if [[ -n "$mgit" ]] && git cat-file -e "${mgit}:${path}" 2>/dev/null; then
      tmp="$(mktemp)"; git show "${mgit}:${path}" > "$tmp" || true
      rec_sha="$(sha256sum "$tmp" | awk '{print $1}')"
      rec_size="$(stat -c '%s' "$tmp")"
      rm -f "$tmp"
    fi

    status="OK"
    [[ -n "$head_sha256" && -n "$msha" && "$msha" != "$head_sha256" ]] && status="${status};MANIFEST!=HEAD_SHA"
    [[ -n "$head_size"  && -n "$msize" && "$msize" != "$head_size"   ]] && status="${status};MANIFEST!=HEAD_SIZE"
    [[ -n "$rec_sha"    && -n "$msha" && "$msha" != "$rec_sha"       ]] && status="${status};MANIFEST!=RECOVERED_SHA"
    [[ -n "$rec_size"   && -n "$msize" && "$msize" != "$rec_size"    ]] && status="${status};MANIFEST!=RECOVERED_SIZE"

    if [[ "$status" != "OK" ]]; then
      n_bad=$((n_bad+1))
    fi

    echo -e "${path}\t${msha}\t${msize}\t${mgit}\t${head_sha1}\t${head_size}\t${head_sha256}\t${rec_sha}\t${rec_size}\t${status}"
  done
} > "$OUT"

echo "Report written to: $OUT"
echo
echo "Résumé :"
echo "  lignes (hors header) : $(($(wc -l < "$OUT")-1))"
echo "  entrées avec différences (status != OK) : $n_bad"
echo
echo "Exemples d'entrées non-OK :"
awk -F'\t' 'NR>1 && $10 != "OK" {print $1"\n"$10; count++; if (count>=25) exit}' "$OUT" || true
echo
echo "Fin de l'audit."

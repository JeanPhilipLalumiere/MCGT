#!/usr/bin/env bash
# audit_bak_and_types.sh — scan des *.bak, mapping vers cibles, typage (script/figure/data)
set -euo pipefail

ROOT="$(git rev-parse --show-toplevel)"; cd "$ROOT"
TS="$(date -u +%Y%m%dT%H%M%SZ)"
OUT="_tmp/bak_audit_${TS}"; LOG="_logs/bak_audit_${TS}.log"
mkdir -p "$OUT" _logs

echo "[INFO] scanning for *.bak under $PWD" | tee "$LOG"
find . -type f -name "*.bak" -not -path "*/.git/*" -print | sort > "$OUT/bak_list.txt" || true

CNT=$(wc -l < "$OUT/bak_list.txt" 2>/dev/null || echo 0)
echo "[INFO] found $CNT .bak files" | tee -a "$LOG"

# Classifieur par extension/couloir
classify() {
  local path="$1"
  local base="${path%*.bak}"
  local ext="${base##*.}"
  local lower_ext="$(echo "$ext" | tr '[:upper:]' '[:lower:]')"
  case "$lower_ext" in
    py|sh) echo "script" ;;
    png|svg|pdf|eps|jpg|jpeg|tif|tiff) echo "figure" ;;
    csv|tsv|json|yaml|yml|txt|parquet|feather|h5|hdf5|npz|npy|pickle|pkl|orc|avro|fits) echo "data" ;;
    *)
      if [[ "$base" =~ (^|/)(zz-)?scripts?/ ]] || [[ "$base" =~ (^|/)tools?/ ]]; then echo "script"
      elif [[ "$base" =~ (^|/)(zz-)?figures?/ ]] || [[ "$base" =~ /chapter[0-9]+/.*fig ]]; then echo "figure"
      elif [[ "$base" =~ (^|/)(zz-)?data/ ]] || [[ "$base" =~ /chapter[0-9]+/.*data ]]; then echo "data"
      else echo "other"
      fi
      ;;
  esac
}

# mapping TSV: kind\tbak_path\ttarget_path\ttarget_exists(bool)
: > "$OUT/mapping.tsv"
while IFS= read -r f; do
  [[ -z "${f:-}" ]] && continue
  base="${f%*.bak}"
  kind="$(classify "$f")"
  exist="no"; [[ -e "$base" ]] && exist="yes"
  printf "%s\t%s\t%s\t%s\n" "$kind" "$f" "$base" "$exist" >> "$OUT/mapping.tsv"
done < "$OUT/bak_list.txt"

# Pré-crée les fichiers par type pour éviter les erreurs quand ils sont vides
: > "$OUT/scripts.tsv"; : > "$OUT/figures.tsv"; : > "$OUT/data.tsv"; : > "$OUT/other.tsv"

# Split par type
awk -F'\t' '$1=="script"{print $2"\t"$3"\t"$4}'  "$OUT/mapping.tsv" > "$OUT/scripts.tsv"
awk -F'\t' '$1=="figure"{print $2"\t"$3"\t"$4}'  "$OUT/mapping.tsv" > "$OUT/figures.tsv"
awk -F'\t' '$1=="data"{print $2"\t"$3"\t"$4}'    "$OUT/mapping.tsv" > "$OUT/data.tsv"
awk -F'\t' '$1=="other"{print $2"\t"$3"\t"$4}'   "$OUT/mapping.tsv" > "$OUT/other.tsv"

count_file() { [[ -f "$1" ]] && wc -l < "$1" || echo 0; }

{
  echo "total_bak	$CNT"
  echo -ne "scripts\t"; count_file "$OUT/scripts.tsv"
  echo -ne "figures\t"; count_file "$OUT/figures.tsv"
  echo -ne "data\t";    count_file "$OUT/data.tsv"
  echo -ne "other\t";   count_file "$OUT/other.tsv"
  echo ""
  echo "# Conflicts (target exists): kind  bak_path  target_path  target_exists"
  awk -F'\t' '$4=="yes"{print $0}' OFS='\t' "$OUT/mapping.tsv" || true
} > "$OUT/summary.txt"

echo "[DONE] Reports:"
echo " - $OUT/bak_list.txt"
echo " - $OUT/mapping.tsv  (kind, bak_path, target_path, target_exists)"
echo " - $OUT/scripts.tsv / $OUT/figures.tsv / $OUT/data.tsv / $OUT/other.tsv"
echo " - $OUT/summary.txt"
read -r -p $'ENTER pour fermer…\n' _ </dev/tty || true

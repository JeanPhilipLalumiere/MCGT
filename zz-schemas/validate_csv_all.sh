#!/usr/bin/env bash
set -euo pipefail

# Simpleur : valide quelques CSV-clés en se basant sur les paires schema→fichier connues.
# Adapte la liste si tu veux valider d'autres CSV.
ROOT="$(cd "$(dirname "$0")" && pwd)/.."
SCHEMA_DIR="$(cd "$(dirname "$0")" && pwd)"

# mapping schema -> csv
declare -A MAP
MAP["$SCHEMA_DIR/mc_results_table_schema.json"]="$ROOT/zz-data/chapter10/10_mc_results.csv"
MAP["$SCHEMA_DIR/comparison_milestones_table_schema.json"]="$ROOT/zz-data/chapter09/09_comparison_milestones.csv"
# ajoute d'autres couples si nécessaire

failed=0
for s in "${!MAP[@]}"; do
  csv="${MAP[$s]}"
  if [ ! -f "$csv" ]; then
    echo "SKIP: $csv (not found)"
    continue
  fi
  echo "Validating $csv ↔ $s"
  python3 "$SCHEMA_DIR/validate_csv_table.py" "$s" "$csv" || failed=1
done

if [ $failed -ne 0 ]; then
  echo "One or more CSV validations failed" >&2
  exit 1
fi
echo "All checked CSVs OK"
exit 0

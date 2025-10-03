#!/usr/bin/env bash
set -Eeuo pipefail
APPLY=${APPLY:-0}
PLAN='.ci-out/figures_rename_plan.tsv'
test -f "$PLAN" || { echo "Plan introuvable: $PLAN"; exit 1; }
tail -n +2 "$PLAN" | while IFS=$'\t' read -r SRC DST; do
  echo "mv -- "$SRC" "$DST"";
  if [ "$APPLY" = "1" ]; then mkdir -p "$(dirname "$DST")"; mv -- "$SRC" "$DST"; fi
done

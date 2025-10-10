#!/usr/bin/env bash
set -Eeuo pipefail
ROOT="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"; cd "$ROOT"
source tools/_lib_trap_exit.sh || true
TS="$(date -u +%Y%m%d_%H%M%S)"
LOG=".ci-logs/coherence_${TS}.log"
exec > >(tee -a "$LOG") 2>&1
mcgt_install_exit_trap "$LOG"

FIGDIR="${FIGDIR:-zz-figures}"
SDIR="${SDIR:-zz-scripts}"
DDIR="${DDIR:-zz-data}"
CSVOUT="${CSVOUT:-zz-manifests/coverage_fig_scripts_data.csv}"
frel="$(realpath --relative-to="$ROOT" "$FIGDIR" 2>/dev/null || echo "$FIGDIR")"
mkdir -p "$(dirname "$CSVOUT")"
echo "chapter,figure_stem,has_script,script_example,has_data,data_example" > "$CSVOUT"
echo "== Couverture fig/script/data =="
total=0; with_script=0; with_data=0
while IFS= read -r p; do
  bn="$(basename "$p")"; ch="$(basename "$(dirname "$p")")"
  stem="${bn%.*}"
  if [[ "$stem" =~ ^[0-9]{2}_(fig_.*)$ ]]; then s="${BASH_REMATCH[1]}"; else s="$stem"; fi
  total=$((total+1))
  script_match="$(LC_ALL=C find "$SDIR" -type f -iname "*${s}*.py" | head -n 1 || true)"
  data_match="$(LC_ALL=C find "$DDIR" -type f -iname "*${s}*" | head -n 1 || true)"
  hs=0; hd=0; [ -n "$script_match" ] && hs=1 && with_script=$((with_script+1))
  [ -n "$data_match" ]   && hd=1 && with_data=$((with_data+1))
  printf "%s,%s,%s,%s,%s,%s\n" "$ch" "$s" "$hs" "$script_match" "$hd" "$data_match" >> "$CSVOUT"
done < <(LC_ALL=C find "$frel" -type f ! -path "$frel/_legacy_conflicts/*" \( -iname "*_fig_*.png" -o -iname "*_fig_*.svg" -o -iname "*_fig_*.pdf" -o -iname "fig_*.png" -o -iname "fig_*.svg" -o -iname "fig_*.pdf" \) -print)
echo "Total figures: $total; avec script: $with_script; avec data: $with_data"
echo "Couverture CSV: $CSVOUT"

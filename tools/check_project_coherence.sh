#!/usr/bin/env bash
set -Eeuo pipefail
ROOT="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"; cd "$ROOT"
TS="$(date -u +%Y%m%d_%H%M%S)"
LOG=".ci-logs/coherence_tolerant_${TS}.log"
exec > >(tee -a "$LOG") 2>&1

FIGDIR="${FIGDIR:-zz-figures}"
SDIR="${SDIR:-zz-scripts}"
DDIR="${DDIR:-zz-data}"
CSVOUT="${CSVOUT:-zz-manifests/coverage_fig_scripts_data.csv}"
GAPSMD="${GAPSMD:-zz-manifests/coverage_gaps.md}"
frel="$(realpath --relative-to="$ROOT" "$FIGDIR" 2>/dev/null || echo "$FIGDIR")"
mkdir -p "$(dirname "$CSVOUT")"
echo "chapter,figure_stem,has_script,script_example,has_data,data_example" > "$CSVOUT"
echo "== Couverture tolérante fig/script/data =="

# Candidates list (évite des find multiples)
cands_py="$(LC_ALL=C find "$SDIR" -type f \( -iname "*.py" -o -iname "*.py.bak" \) -print || true)"
cands_data="$(LC_ALL=C find "$DDIR" -type f \( -iname "*.csv" -o -iname "*.json" -o -iname "*.parquet" -o -iname "*.npz" -o -iname "*.npy" -o -iname "*.fits" \) -print || true)"

total=0; with_script=0; with_data=0
while IFS= read -r p; do
  bn="$(basename "$p")"; ch="$(basename "$(dirname "$p")")"
  stem="${bn%.*}"
  # s = stem canonique sans préfixe chapitre
  if [[ "$stem" =~ ^[0-9]{2}_(fig_.*)$ ]]; then s="${BASH_REMATCH[1]}"; else s="$stem"; fi
  # variantes de correspondance: fig_03_x -> fig03_x, fig_03_x -> plot_fig03_x
  alt1="$(printf "%s" "$s" | sed -E "s/_([0-9]+)/\\1/g")"
  alt2="$(printf "%s" "$s" | sed -E "s/^fig_([0-9]{2})_/fig\\1_/")"
  alt3="$(printf "%s" "$s" | sed -E "s/^fig_([0-9]{2})_/plot_fig\\1_/")"

  total=$((total+1))
  script_match=""
  if [ -n "$cands_py" ]; then
    script_match="$(printf "%s\n" "$cands_py" | grep -i -e "$s" -e "$alt1" -e "$alt2" -e "$alt3" | head -n 1 || true)"
  fi
  data_match=""
  if [ -n "$cands_data" ]; then
    data_match="$(printf "%s\n" "$cands_data" | grep -i -e "$s" -e "$alt1" -e "$alt2" | head -n 1 || true)"
  fi
  hs=0; hd=0; [ -n "$script_match" ] && hs=1 && with_script=$((with_script+1))
  [ -n "$data_match" ]   && hd=1 && with_data=$((with_data+1))
  printf "%s,%s,%s,%s,%s,%s\n" "$ch" "$s" "$hs" "$script_match" "$hd" "$data_match" >> "$CSVOUT"
done < <(LC_ALL=C find "$frel" -type f ! -path "$frel/_legacy_conflicts/*" \( -iname "*_fig_*.png" -o -iname "*_fig_*.svg" -o -iname "*_fig_*.pdf" -o -iname "fig_*.png" -o -iname "fig_*.svg" -o -iname "fig_*.pdf" \) -print | LC_ALL=C sort)

echo "Total figures: $total; avec script: $with_script; avec data: $with_data"
echo "Couverture CSV: $CSVOUT"

# Rapport des manques
tmpgap="/tmp/gaps_${TS}.csv"
awk -F, 'NR>1 && ($3==0 || $5==0) {print $0}' "$CSVOUT" > "$tmpgap" || true
{ printf "# Manques de couverture (scripts/données)\n\n| Chapitre | Figure | Script ? | Données ? | Exemple script | Exemple data |\n|---|---|---|---|---|---|\n";
  if [ -s "$tmpgap" ]; then
    while IFS=, read -r ch s hs sm hd dm; do
      printf "| %s | %s | %s | %s | %s | %s |\n" "$ch" "$s" "$hs" "$hd" "$sm" "$dm"
    done < "$tmpgap"
  else
    printf "| ✅ | Couverture complète |  |  |  |  |\n"
  fi
} > "$GAPSMD"
echo "Gaps: $GAPSMD"

#!/usr/bin/env bash
set -Eeuo pipefail
ROOT="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"; cd "$ROOT"
TS="$(date -u +%Y%m%d_%H%M%S)"
LOG=".ci-logs/coherence_plus_data_${TS}.log"
exec > >(tee -a "$LOG") 2>&1

FIGDIR="${FIGDIR:-zz-figures}"
SDIR="${SDIR:-zz-scripts}"
DDIR="${DDIR:-zz-data}"
CSVOUT="${CSVOUT:-zz-manifests/coverage_fig_scripts_data.csv}"
GAPSMD="${GAPSMD:-zz-manifests/coverage_gaps.md}"
LINKS="${LINKS:-zz-manifests/script_data_links.csv}"
mkdir -p "$(dirname "$CSVOUT")"
echo "== Couverture fig/script/data (scan des scripts) =="

# Prépare listes candidates
cands_py="$(LC_ALL=C find "$SDIR" -type f \( -iname "*.py" -o -iname "*.py.bak" \) -print || true)"
cands_data="$(LC_ALL=C find "$DDIR" -type f \( -iname "*.csv" -o -iname "*.json" -o -iname "*.parquet" -o -iname "*.npy" -o -iname "*.npz" -o -iname "*.fits" -o -iname "*.txt" \) -print || true)"
printf "script_path,data_path\\n" > "$LINKS"

# Map script -> première data détectée (via scan du contenu)
if [ -n "$cands_py" ]; then
  while IFS= read -r sp; do
    # On cherche des appels classiques de lecture de données
    m="$(grep -Ei '(read_csv|read_json|read_parquet|np\.load|numpy\.load|loadtxt|genfromtxt|fits\.open|Table\.read|pd\.read_(csv|json|parquet))' "$sp" 2>/dev/null | \\
         sed -n -E 's/.*["'"'"]([^"'"'"]+\.(csv|json|parquet|npy|npz|fits|txt))["'"'"].*/\1/p' | head -n 1 || true)"
    if [ -n "$m" ]; then
      printf "%s,%s\\n" "$sp" "$m" >> "$LINKS"
    fi
  done < <(printf "%s\n" "$cands_py")
fi

# Index rapide des data par chapitre (fallback)
declare -A first_data_by_ch
if [ -n "$cands_data" ]; then
  while IFS= read -r dp; do
    ch="$(basename "$(dirname "$dp")")"
    first_data_by_ch["$ch"]="${first_data_by_ch["$ch"]:-$dp}"
  done < <(printf "%s\n" "$cands_data")
fi

echo "chapter,figure_stem,has_script,script_example,has_data,data_example" > "$CSVOUT"
total=0; with_script=0; with_data=0
frel="$(realpath --relative-to="$ROOT" "$FIGDIR" 2>/dev/null || echo "$FIGDIR")"
while IFS= read -r p; do
  bn="$(basename "$p")"; ch="$(basename "$(dirname "$p")")"
  stem="${bn%.*}"
  if [[ "$stem" =~ ^[0-9]{2}_(fig_.*)$ ]]; then s="${BASH_REMATCH[1]}"; else s="$stem"; fi
  alt1="$(printf "%s" "$s" | sed -E "s/_([0-9]+)/\\1/g")"
  alt2="$(printf "%s" "$s" | sed -E "s/^fig_([0-9]{2})_/fig\\1_/")"
  alt3="$(printf "%s" "$s" | sed -E "s/^fig_([0-9]{2})_/plot_fig\\1_/")"
  total=$((total+1))
  # Script associé
  script_match=""
  if [ -n "$cands_py" ]; then
    script_match="$(printf "%s\n" "$cands_py" | grep -i -e "$s" -e "$alt1" -e "$alt2" -e "$alt3" | head -n 1 || true)"
  fi
  # Data associée : (1) via lien script->data si dispo, sinon (2) fallback par chapitre
  data_match=""
  if [ -n "$script_match" ] && [ -s "$LINKS" ]; then
    data_match="$(awk -F, -v s="$script_match" 'NR>1 && $1==s {print $2; exit}' "$LINKS" | head -n 1 || true)"
  fi
  if [ -z "$data_match" ]; then
    data_match="${first_data_by_ch["$ch"]:-}"
  fi
  hs=0; hd=0; [ -n "$script_match" ] && hs=1 && with_script=$((with_script+1))
  [ -n "$data_match" ]   && hd=1 && with_data=$((with_data+1))
  printf "%s,%s,%s,%s,%s,%s\n" "$ch" "$s" "$hs" "$script_match" "$hd" "$data_match" >> "$CSVOUT"
done < <(LC_ALL=C find "$frel" -type f ! -path "$frel/_legacy_conflicts/*" \( -iname "*_fig_*.png" -o -iname "*_fig_*.svg" -o -iname "*_fig_*.pdf" -o -iname "fig_*.png" -o -iname "fig_*.svg" -o -iname "fig_*.pdf" \) -print | LC_ALL=C sort)

echo "Total figures: $total; avec script: $with_script; avec data: $with_data"
echo "Couverture CSV: $CSVOUT"
echo "Liens script→data: $LINKS"

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

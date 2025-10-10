#!/usr/bin/env bash
# Résume zz-out/homog_smoke_pass14.csv et pointe vers les logs utiles
set -Eeuo pipefail

CSV="zz-out/homog_smoke_pass14.csv"
LOG="zz-out/homog_smoke_pass14.log"

if [[ ! -f "$CSV" ]]; then
  echo "[ERREUR] Introuvable: $CSV" >&2
  exit 2
fi

echo "=== PASS14: résumé global ==="
# compte par statut
awk -F',' 'NR>1 {c[$2]++} END{for (k in c) printf "%-10s %6d\n", k, c[k]}' "$CSV" | sort

# top 10 plus grosses sorties
echo
echo "=== Top 10 des sorties les plus volumineuses ==="
# colonnes: file,status,reason,elapsed_sec,out_path,out_size
# on protège les virgules éventuelles dans le chemin via awk simple (données homogènes)
awk -F',' 'NR>1 && $6 ~ /^[0-9]+$/ {print $6,$5,$1}' "$CSV" \
  | sort -nrk1 | head -10 \
  | awk '{sz=$1; path=$2; $1=$2=""; sub(/^  */,""); print sz"\t"path"\t"$0}'

# échecs éventuels
echo
echo "=== Éléments non OK (si présents) ==="
awk -F',' 'NR>1 && $2!="OK" {printf "%-60s  %-6s  %s\n", $1, $2, $3}' "$CSV" | sed 's/  $//'

# durées extrêmes
echo
echo "=== Durées (top 10) ==="
awk -F',' 'NR>1 && $4 ~ /^[0-9.]+$/ {print $4,$1,$2}' "$CSV" \
  | sort -nrk1 | head -10 \
  | awk '{printf "%7.2fs  %-6s  %s\n", $1, $3, $2}'

echo
[[ -f "$LOG" ]] && echo "Log détaillé smoke : $LOG" || true

# rappel : dernier log d’enrobage pass14_direct_*.log
last_wrap="$(ls -t zz-out/pass14_direct_*.log 2>/dev/null | head -1 || true)"
[[ -n "$last_wrap" ]] && echo "Dernier log wrapper : $last_wrap"

#!/usr/bin/env bash
set -euo pipefail

echo "[HOMOG-PASS2] Purge fig.tight_layout / plt.tight_layout (toutes variantes) + re-scan"

SROOT="zz-scripts"
REPORT_TXT="zz-out/homog_scan_report_pass2.txt"
REPORT_CSV="zz-out/homog_scan_failures_pass2.csv"
mkdir -p "$(dirname "$REPORT_TXT")"

# Cible : chapitres 01..10
chapters=()
for d in "$SROOT"/chapter0{1..9} "$SROOT"/chapter10; do
  [[ -d "$d" ]] && chapters+=("$d")
done

echo "[PATCH] Remplacements automatiques dans ${#chapters[@]} dossiers…"
for d in "${chapters[@]}"; do
  while IFS= read -r -d '' f; do
    cp -n "$f" "$f.bak" 2>/dev/null || true

    # 1) fig.tight_layout(rect=[l,b,r,t]) -> fig.subplots_adjust(left=l,bottom=b,right=r,top=t)
    perl -0777 -pe '
      s/\bfig\.tight_layout\(\s*rect\s*=\s*\[\s*([^,]+)\s*,\s*([^,]+)\s*,\s*([^,]+)\s*,\s*([^\]]+)\s*\]\s*\)/
        "fig.subplots_adjust(left=".$1.",bottom=".$2.",right=".$3.",top=".$4.")"
      /sge;
    ' -i "$f"

    # 2) plt.tight_layout(rect=[l,b,r,t]) -> fig=plt.gcf(); fig.subplots_adjust(left=...,bottom=...,right=...,top=...)
    perl -0777 -pe '
      s/\bplt\.tight_layout\(\s*rect\s*=\s*\[\s*([^,]+)\s*,\s*([^,]+)\s*,\s*([^,]+)\s*,\s*([^\]]+)\s*\]\s*\)/
        "fig=plt.gcf(); fig.subplots_adjust(left=".$1.",bottom=".$2.",right=".$3.",top=".$4.")"
      /sge;
    ' -i "$f"

    # 3) fig.tight_layout() (sans rect) -> fig.subplots_adjust(default margins)
    perl -0777 -pe '
      s/\bfig\.tight_layout\(\s*\)/fig.subplots_adjust(left=0.07,right=0.98,top=0.95,bottom=0.12)/sg;
    ' -i "$f"

    # 4) plt.tight_layout() (sans rect) -> fig=plt.gcf(); fig.subplots_adjust(default margins)
    perl -0777 -pe '
      s/\bplt\.tight_layout\(\s*\)/fig=plt.gcf(); fig.subplots_adjust(left=0.07,right=0.98,top=0.95,bottom=0.12)/sg;
    ' -i "$f"

  done < <(find "$d" -maxdepth 1 -name "*.py" -print0)
done

echo "[CHECK] Recherche d apppels actifs à tight_layout restants (hors commentaires)"
viol=$(awk '/tight_layout/ && $0 !~ /^[[:space:]]*#/{print FILENAME ":" FNR ":" $0}' $(find "${chapters[@]}" -name "*.py") || true)
if [[ -n "${viol}" ]]; then
  echo "[WARN] Appels tight_layout restants :" ; echo "$viol" | sed 's/^/  /'
else
  echo "[OK] Plus d appels actifs à tight_layout (fig/plt) dans 01–10."
fi

echo "[SCAN] --help sur tous les scripts"
echo "# Homogenization scan report (pass2) $(date -u +"%Y-%m-%dT%H:%M:%SZ")" > "$REPORT_TXT"
echo "file,status,detail" > "$REPORT_CSV"

ok=0; fail=0
for d in "${chapters[@]}"; do
  echo "## $(basename "$d")" >> "$REPORT_TXT"
  while IFS= read -r -d '' f; do
    if python3 "$f" --help >/dev/null 2>&1; then
      echo "- $f : OK" >> "$REPORT_TXT"
      echo "\"$f\",OK," >> "$REPORT_CSV"
      ok=$((ok+1))
    else
      detail=$(python3 "$f" --help 2>&1 | head -n 2 | tr '\n' ' ' | sed 's/,/;/g')
      echo "- $f : FAIL" >> "$REPORT_TXT"
      echo "  -> $detail" >> "$REPORT_TXT"
      echo "\"$f\",FAIL,\"$detail\"" >> "$REPORT_CSV"
      fail=$((fail+1))
    fi
  done < <(find "$d" -maxdepth 1 -name "*.py" -print0)
  echo "" >> "$REPORT_TXT"
done

echo "[RESULT] --help OK: $ok, FAIL: $fail"
echo "[REPORT] Texte : $REPORT_TXT"
echo "[REPORT] CSV   : $REPORT_CSV"
echo "[DONE]"

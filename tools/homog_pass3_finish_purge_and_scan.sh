#!/usr/bin/env bash
set -euo pipefail

echo "[HOMOG-PASS3] Purge recursive *.tight_layout + hook global + re-scan --help"

SROOT="zz-scripts"
REPORT_TXT="zz-out/homog_scan_report_pass3.txt"
REPORT_CSV="zz-out/homog_scan_failures_pass3.csv"
mkdir -p "$(dirname "$REPORT_TXT")"

# 1) Hook pre-commit (récursif, fig.* et plt.*)
cat > .git/hooks/pre-commit <<'HOOK'
#!/usr/bin/env bash
set -euo pipefail
viol=$(awk '/[[:alnum:]_]\.tight_layout\(/ && $0 !~ /^[[:space:]]*#/{print FILENAME ":" FNR ":" $0}' $(find zz-scripts -type f -name "*.py") || true)
if [[ -n "${viol}" ]]; then
  echo "[pre-commit] Appel actif à *.tight_layout détecté :"
  echo "${viol}"
  echo "=> Utilise fig.subplots_adjust(...) à la place."
  exit 1
fi
HOOK
chmod +x .git/hooks/pre-commit
echo "[HOOK] pre-commit global mis à jour (scan récursif)."

# 2) Purge recursive dans chapitres 01..10 (inclut utils/)
echo "[PATCH] Purge recursive *.tight_layout(...) dans 01–10…"
chapters=()
for d in "$SROOT"/chapter0{1..9} "$SROOT"/chapter10; do
  [[ -d "$d" ]] && chapters+=("$d")
done

for d in "${chapters[@]}"; do
  while IFS= read -r -d '' f; do
    cp -n "$f" "$f.bak" 2>/dev/null || true

    # fig.tight_layout(rect=[l,b,r,t]) -> fig.subplots_adjust(left=...,bottom=...,right=...,top=...)
    perl -0777 -pe '
      s/\bfig\.tight_layout\(\s*rect\s*=\s*\[\s*([^,]+)\s*,\s*([^,]+)\s*,\s*([^,]+)\s*,\s*([^\]]+)\s*\]\s*\)/
        "fig.subplots_adjust(left=".$1.",bottom=".$2.",right=".$3.",top=".$4.")"
      /sge;
    ' -i "$f"

    # plt.tight_layout(rect=[l,b,r,t]) -> fig=plt.gcf(); fig.subplots_adjust(...)
    perl -0777 -pe '
      s/\bplt\.tight_layout\(\s*rect\s*=\s*\[\s*([^,]+)\s*,\s*([^,]+)\s*,\s*([^,]+)\s*,\s*([^\]]+)\s*\]\s*\)/
        "fig=plt.gcf(); fig.subplots_adjust(left=".$1.",bottom=".$2.",right=".$3.",top=".$4.")"
      /sge;
    ' -i "$f"

    # fig.tight_layout() -> fig.subplots_adjust(default)
    perl -0777 -pe '
      s/\bfig\.tight_layout\(\s*\)/fig.subplots_adjust(left=0.07,right=0.98,top=0.95,bottom=0.12)/sg;
    ' -i "$f"

    # plt.tight_layout() -> fig=plt.gcf(); fig.subplots_adjust(default)
    perl -0777 -pe '
      s/\bplt\.tight_layout\(\s*\)/fig=plt.gcf(); fig.subplots_adjust(left=0.07,right=0.98,top=0.95,bottom=0.12)/sg;
    ' -i "$f"

  done < <(find "$d" -type f -name "*.py" -print0)
done

# 3) Vérif de toute occurrence active résiduelle
echo "[CHECK] Recherche d'appels actifs *.tight_layout (hors commentaires)"
viol=$(awk '/[[:alnum:]_]\.tight_layout\(/ && $0 !~ /^[[:space:]]*#/{print FILENAME ":" FNR ":" $0}' $(find "${chapters[@]}" -type f -name "*.py") || true)
if [[ -n "${viol}" ]]; then
  echo "[WARN] Appels tight_layout restants :" ; echo "$viol" | sed 's/^/  /'
else
  echo "[OK] Plus d'appels actifs à *.tight_layout dans 01–10."
fi

# 4) Re-scan --help (récursif) + rapports
echo "[SCAN] --help sur tous les scripts (récursif)"
echo "# Homogenization scan report (pass3) $(date -u +"%Y-%m-%dT%H:%M:%SZ")" > "$REPORT_TXT"
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
  done < <(find "$d" -type f -name "*.py" -print0)
  echo "" >> "$REPORT_TXT"
done

echo "[RESULT] --help OK: $ok, FAIL: $fail"
echo "[REPORT] Texte : $REPORT_TXT"
echo "[REPORT] CSV   : $REPORT_CSV"
echo "[DONE]"

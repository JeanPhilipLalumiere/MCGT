#!/usr/bin/env bash
set -euo pipefail

echo "[HOMOG] Scan global chapitres 01–10 : tight_layout + --help"

SROOT="zz-scripts"
REPORT="zz-out/homog_scan_report.txt"
mkdir -p "$(dirname "$REPORT")"

chapters=()
for d in "$SROOT"/chapter0{1..9} "$SROOT"/chapter10; do
  [[ -d "$d" ]] && chapters+=("$d")
done

# 1) Purge automatique de plt.tight_layout(...) -> fig.subplots_adjust(...)
purged=0
for d in "${chapters[@]}"; do
  while IFS= read -r -d '' f; do
    # Sauvegarde
    cp -n "$f" "$f.bak" 2>/dev/null || true
    # Trois passes comme pour ch10 (séquences, blocs warnings, occurrences simples)
    perl -0777 -pe '
      s/plt\.tight_layout\([^)]*\)\s*;\s*fig\.savefig\(([^)]+)\)/fig.subplots_adjust(left=0.07,right=0.98,top=0.95,bottom=0.12);\nfig.savefig(\1)/sg;
      s/with\s+warnings\.catch_warnings\(\):\s*warnings\.simplefilter\([^)]*\)\s*;\s*plt\.tight_layout\(\)/with warnings.catch_warnings(): warnings.simplefilter("ignore"); fig=plt.gcf(); fig.subplots_adjust(left=0.07,right=0.98,top=0.95,bottom=0.12)/sg;
      s/plt\.tight_layout\([^)]*\)/fig=plt.gcf(); fig.subplots_adjust(left=0.07,right=0.98,top=0.95,bottom=0.12)/sg;
    ' -i "$f"
    purged=$((purged+1))
  done < <(find "$d" -maxdepth 1 -name "*.py" -print0)
done
echo "[HOMOG] Purge tight_layout appliquée à ~$purged scripts (sauvegardes *.bak conservées)."

# 2) Rapport --help
echo "# Homogenization scan report ($(date -u +"%Y-%m-%dT%H:%M:%SZ"))" > "$REPORT"
echo "" >> "$REPORT"
fail=0
ok=0
for d in "${chapters[@]}"; do
  echo "## $(basename "$d")" >> "$REPORT"
  while IFS= read -r -d '' f; do
    rel="${f}"
    echo "- $rel : \c" >> "$REPORT"
    if python3 "$f" --help >/dev/null 2>&1; then
      echo "OK" >> "$REPORT"
      ok=$((ok+1))
    else
      echo "FAIL" >> "$REPORT"
      echo "  -> $(python3 "$f" --help 2>&1 | head -n 3 | tr '\n' ' ')" >> "$REPORT"
      fail=$((fail+1))
    fi
  done < <(find "$d" -maxdepth 1 -name "*.py" -print0)
  echo "" >> "$REPORT"
done

echo "[HOMOG] --help OK: $ok, FAIL: $fail"
if [[ $fail -gt 0 ]]; then
  echo "[HOMOG] Des parseurs sont à réécrire. Voir $REPORT"
else
  echo "[HOMOG] Tous les parseurs répondent à --help. Rapport: $REPORT"
fi

# 3) Affiche les occurrences actives restantes de 'tight_layout' (hors commentaires)
viol=$(awk '/tight_layout/ && $0 !~ /^[[:space:]]*#/{print FILENAME ":" FNR ":" $0}' $(find "${chapters[@]}" -name "*.py") || true)
if [[ -n "${viol}" ]]; then
  echo "[HOMOG] ATTENTION: appels actifs tight_layout détectés:"
  echo "$viol" | sed 's/^/  /'
  echo ">> Intervention manuelle nécessaire sur ces lignes."
else
  echo "[HOMOG] Aucun appel actif à tight_layout détecté dans 01–10."
fi

echo "[DONE] Homog scan terminé."

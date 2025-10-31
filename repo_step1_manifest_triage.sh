bash <<'BASH'
#!/usr/bin/env bash
# repo_step1_manifest_triage.sh (lecture-seule)
set -o pipefail; set +e
ts="$(date +%Y%m%dT%H%M%S)"
OUT="/tmp/mcgt_triage_step1_${ts}"
mkdir -p "$OUT"

# Garde-fou pour éviter fermeture de fenêtre:
trap 'code=$?; echo; echo "[INFO] Triage terminé (code=${code}). Sorties: $OUT"; read -rp "[PAUSE] Appuie sur Entrée pour quitter... " _' EXIT

# Trouver les derniers OUT de DEEP A / C / D
latest_dir() { ls -1dt /tmp/"$1"_* 2>/dev/null | head -n1; }
A="$(latest_dir mcgt_deepA)"
C="$(latest_dir mcgt_deepC)"
D="$(latest_dir mcgt_deepD)"

echo "A=$A" | tee "$OUT/SUMMARY.txt"
echo "C=$C" | tee -a "$OUT/SUMMARY.txt"
echo "D=$D" | tee -a "$OUT/SUMMARY.txt"

# 1) Manquants (depuis DEEP-A 06_manifest_coverage.txt)
MISSING_ALL="$OUT/missing_all.txt"
if [ -f "$A/06_manifest_coverage.txt" ]; then
  # Extrait toutes les lignes "MISSING: path"
  sed -n 's/^MISSING: //p' "$A/06_manifest_coverage.txt" | sort -u > "$MISSING_ALL"
else
  : > "$MISSING_ALL"
fi

# Catégorisation des manquants
grep -E '\.lock\.json(\.lock)?$' "$MISSING_ALL" > "$OUT/missing_lockjson.txt" || true
grep -E '/requirements\.txt$'     "$MISSING_ALL" > "$OUT/missing_requirements.txt" || true
grep -E '^zz-figures/.+\.png$'    "$MISSING_ALL" > "$OUT/missing_figures_png.txt" || true
grep -E '^zz-data/|^zz-scripts/|^tools/|^mcgt/|^zz_tools/' "$MISSING_ALL" \
  | grep -vE '\.lock\.json(\.lock)?$|/requirements\.txt$' \
  | grep -vE '^zz-figures/.+\.png$' \
  > "$OUT/missing_other.txt" || true

# 2) Orphelins non référencés (depuis DEEP-C unreferenced.tsv)
UNREF="$OUT/unreferenced_all.txt"
if [ -f "$C/unreferenced.tsv" ]; then
  # suppose 1ère colonne = path (skip header si présent)
  awk -F'\t' 'NR==1 && $1 ~ /path|file/i {next} {print $1}' "$C/unreferenced.tsv" | sort -u > "$UNREF"
else
  : > "$UNREF"
fi

# ADD candidates = orphelins plausibles à intégrer au master (hors out/tmp/attic/backups)
grep -E '^(zz-data|zz-figures|zz-scripts)/' "$UNREF" \
  | grep -vE '(^|/)(zz-out|_snapshots|_tmp|attic|_attic_untracked|backups)(/|$)' \
  > "$OUT/add_candidates.txt" || true

# DROP candidates = manquants manifestement indésirables
cat "$OUT/missing_lockjson.txt" "$OUT/missing_requirements.txt" 2>/dev/null | sort -u > "$OUT/drop_candidates.txt"

# 3) Résumés chiffrés
wc -l "$MISSING_ALL"                         | awk '{printf("missing_all=%s\n",$1)}'     | tee -a "$OUT/SUMMARY.txt"
wc -l "$OUT/missing_figures_png.txt"         | awk '{printf("missing_figures_png=%s\n",$1)}' | tee -a "$OUT/SUMMARY.txt"
wc -l "$OUT/missing_lockjson.txt"            | awk '{printf("missing_lockjson=%s\n",$1)}' | tee -a "$OUT/SUMMARY.txt"
wc -l "$OUT/missing_requirements.txt"        | awk '{printf("missing_requirements=%s\n",$1)}' | tee -a "$OUT/SUMMARY.txt"
wc -l "$OUT/missing_other.txt"               | awk '{printf("missing_other=%s\n",$1)}'    | tee -a "$OUT/SUMMARY.txt"
wc -l "$UNREF"                               | awk '{printf("unreferenced=%s\n",$1)}'     | tee -a "$OUT/SUMMARY.txt"
wc -l "$OUT/add_candidates.txt"              | awk '{printf("add_candidates=%s\n",$1)}'   | tee -a "$OUT/SUMMARY.txt"
wc -l "$OUT/drop_candidates.txt"             | awk '{printf("drop_candidates=%s\n",$1)}'  | tee -a "$OUT/SUMMARY.txt"

# 4) Échantillons lisibles à l'écran (têtes)
echo -e "\n--- HEAD: missing_figures_png.txt ---"; sed -n '1,40p' "$OUT/missing_figures_png.txt" 2>/dev/null || true
echo -e "\n--- HEAD: add_candidates.txt ---";      sed -n '1,40p' "$OUT/add_candidates.txt" 2>/dev/null || true
echo -e "\n--- HEAD: drop_candidates.txt ---";     sed -n '1,40p' "$OUT/drop_candidates.txt" 2>/dev/null || true

BASH

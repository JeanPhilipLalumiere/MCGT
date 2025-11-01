# repo_step2_build_round2_lists.sh
# Usage: bash repo_step2_build_round2_lists.sh [TRIAGE_DIR]
# Effet: écrit uniquement sous /tmp/mcgt_round2_*/ ; ne modifie pas le repo.
# Garde-fou: ne tue pas la fenêtre en cas d'erreur; pause finale.

set +e  # on n'abat pas le terminal sur erreur
set -u

ts="$(date +%Y%m%dT%H%M%S)"
REPO="${REPO:-$(git rev-parse --show-toplevel 2>/dev/null || pwd)}"

# Détecte le dernier triage step1 si non fourni
TRIAGE_DIR="${1:-$(ls -d /tmp/mcgt_triage_step1_* 2>/dev/null | tail -1)}"
if [ -z "${TRIAGE_DIR:-}" ] || [ ! -d "$TRIAGE_DIR" ]; then
  echo "ERR: TRIAGE_DIR introuvable. Fournis le chemin ou relance step1b."
  read -r -p "[PAUSE] Entrée pour quitter..." _
  exit 1
fi

OUT="/tmp/mcgt_round2_${ts}"
mkdir -p "$OUT"

missing_figs="$TRIAGE_DIR/missing_figures_png.txt"
add_candidates="$TRIAGE_DIR/add_candidates.txt"
drop_candidates="$TRIAGE_DIR/drop_candidates.txt"

# --- 1) IGNORE: artefacts et doublons CSV non compressés ---
ignore_patterns_tmp="$OUT/ignore_patterns.raw.txt"
ignore_list="$OUT/ignore_list_round2.txt"

# Artefacts (lock/caches/broken/bak)
{
  echo '**/*.lock.json'
  echo '**/*.lock.lock.json'
  echo '**/*.npz.lock.lock.json'
  echo 'zz-scripts/chapter10/*.broken.*'
  echo 'tools/*.bak_*'
  echo 'tools/*/*.bak_*'
} > "$ignore_patterns_tmp"

# Doublons CSV vs CSV.GZ (on ignore les .csv si le .csv.gz existe)
dup_uncompressed="$OUT/dup_csv_uncompressed.txt"
( cd "$REPO" && \
  find zz-data -type f -name '*.csv.gz' -print0 2>/dev/null \
  | xargs -0 -I{} bash -c 'b="{}"; echo "${b%.gz}"' \
  | while read -r base; do [ -f "$base" ] && echo "$base"; done ) > "$dup_uncompressed"

# Concatène et normalise
{
  cat "$ignore_patterns_tmp"
  if [ -s "$dup_uncompressed" ]; then
    sed 's#^#/#' "$dup_uncompressed"
  fi
} | awk 'NF' | sort -u > "$ignore_list"

# --- 2) ADD: ce qu’on veut référencer explicitement maintenant ---
add_list="$OUT/add_list_round2.txt"
# Point de départ: add_candidates du step1
touch "$add_list"
if [ -f "$add_candidates" ]; then
  cat "$add_candidates" >> "$add_list"
fi
# On s’assure que les .csv.gz doublonnés sont dedans
( cd "$REPO" && \
  find zz-data -type f -name '*.csv.gz' 2>/dev/null | sed 's#^#/#' ) >> "$add_list"
# Nettoyage
sort -u "$add_list" | grep -v '\.broken\.' > "$add_list.tmp" && mv "$add_list.tmp" "$add_list"

# --- 3) REVIEW: figures & requirements manquants ---
review_list="$OUT/review_list_round2.txt"
touch "$review_list"

# Figures manquantes (du step1)
if [ -f "$missing_figs" ]; then
  # saute la première ligne "N /path..." si présente
  tail -n +2 "$missing_figs" >> "$review_list"
fi

# Requirements manquants: repêche depuis drop_candidates (car listés comme 'missing')
if [ -f "$drop_candidates" ]; then
  grep -E '^zz-scripts/chapter[0-9]+/requirements\.txt$' "$drop_candidates" >> "$review_list"
fi

# Tri & unique
sort -u "$review_list" -o "$review_list"

# --- 4) Résumé & copies prêtes ---
echo "=== ROUND2 LISTS ==="
wc -l "$add_list" "$ignore_list" "$review_list" | sed "s#${OUT}/##g"
echo
echo "Chemin OUT: $OUT"
echo
echo "Copier dans le repo (simulation):"
echo "  install -D \"$add_list\"     \"$REPO/zz-manifests/triage_round2/add_list_round2.txt\""
echo "  install -D \"$ignore_list\"  \"$REPO/zz-manifests/triage_round2/ignore_list_round2.txt\""
echo "  install -D \"$review_list\"  \"$REPO/zz-manifests/triage_round2/review_list_round2.txt\""
echo
echo "Vérifs utiles:"
echo "  head -n 20 \"$add_list\""
echo "  head -n 20 \"$ignore_list\""
echo "  head -n 20 \"$review_list\""

read -r -p "[PAUSE] Entrée pour quitter..." _

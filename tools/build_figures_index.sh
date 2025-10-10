#!/usr/bin/env bash
set -Eeo pipefail

ROOT="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
cd "$ROOT"

FIGDIR="${FIGDIR:-zz-figures}"
OUTCSV="${OUTCSV:-zz-manifests/figures_index.csv}"
OUTMD="${OUTMD:-zz-manifests/figures_per_chapter.md}"

TS="$(date -u +%Y%m%d_%H%M%S)"
LOG=".ci-logs/figures_index_${TS}.log"

# Duplique stdout+stderr vers un log
exec > >(tee -a "$LOG") 2>&1

# --- Garde-fou anti-fermeture ---
on_exit() {
  ec=$?
  echo
  echo "== Fin (code: $ec) =="
  echo "Log: $LOG"
  if [ -z "${MCGT_NO_SHELL_DROP:-}" ]; then
    echo
    echo "Ouverture d'un shell interactif (anti-fermeture)."
    echo "Pour quitter: 'exit' ou Ctrl+D."
    if command -v "${SHELL:-bash}" >/dev/null 2>&1; then
      exec "${SHELL:-bash}" -i
    elif command -v bash >/dev/null 2>&1; then
      exec bash -i
    else
      echo "Aucun shell trouvé, maintien de la session (Ctrl+C pour fermer)."
      tail -f /dev/null
    fi
  fi
}
trap on_exit EXIT

echo "== Build figures index =="
echo "ROOT=$ROOT"
echo "FIGDIR=$FIGDIR"
echo "OUTCSV=$OUTCSV"
echo "OUTMD=$OUTMD"
echo

# Helpers
sha256_of() { sha256sum -- "$1" | awk '{print $1}'; }
size_bytes() {
  if stat --version >/dev/null 2>&1; then
    stat -c '%s' -- "$1"
  else
    wc -c < "$1" | tr -d '[:space:]'
  fi
}

figdir_rel="$(realpath --relative-to="$ROOT" "$FIGDIR")"

# Collecte des fichiers (relatif, tri stable), en excluant la quarantaine et les symlinks
mapfile -d '' FILES < <(
  LC_ALL=C \
  find "$figdir_rel" \
    \( -path "$figdir_rel/_legacy_conflicts" -o -path "$figdir_rel/_legacy_conflicts/*" -o -type l \) -prune -o \
    -type f \( -iname '*.png' -o -iname '*.svg' -o -iname '*.pdf' \) -print0 \
  | LC_ALL=C sort -z
)

mkdir -p "$(dirname "$OUTCSV")"
echo "chapter,basename,stem,ext,rel_path,sha256,bytes" > "$OUTCSV"

# Comptages par chapitre
declare -A COUNT=()
declare -A BYTES=()

for p in "${FILES[@]}"; do
  base="${p##*/}"
  stem="${base%.*}"
  ext="${base##*.}"

  # Chapitre depuis le dossier parent (chapterNN), sinon 'chapter??'
  chapter_dir="$(dirname "$p")"
  chapter_base="$(basename "$chapter_dir")"
  chapter="chapter??"
  if [[ "$chapter_base" =~ ^chapter([0-9]{2})$ ]]; then
    chapter="$chapter_base"
  fi

  hash="$(sha256_of "$p")"
  bytes="$(size_bytes "$p")"

  echo "$chapter,$base,$stem,$ext,$p,$hash,$bytes" >> "$OUTCSV"

  (( COUNT["$chapter"] += 1 )) || true
  (( BYTES["$chapter"] += bytes )) || true
done

# Résumé par chapitre (trié)
{
  echo "# Figures par chapitre"
  echo
  echo "| Chapitre | # Figures | Taille totale (MiB) |"
  echo "|---|---:|---:|"
  for ch in $(printf "%s\n" "${!COUNT[@]}" | LC_ALL=C sort); do
    n="${COUNT[$ch]}"
    b="${BYTES[$ch]}"
    mib=$(awk -v b="$b" 'BEGIN{printf "%.2f", b/1024/1024}')
    echo "| $ch | $n | $mib |"
  done
  echo
  echo "_Généré: ${TS}Z_"
} > "$OUTMD"

echo
echo "Index écrit: $OUTCSV"
echo "Résumé écrit: $OUTMD"

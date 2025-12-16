#!/usr/bin/env bash
set -Eeo pipefail
mkdir -p .ci-logs

ROOT="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
cd "$ROOT"

FIGDIR="${FIGDIR:-zz-figures}"
CSV="${CSV:-zz-manifests/figures_index.csv}"
TS="$(date -u +%Y%m%d_%H%M%S)"
TMPCSV="/tmp/figidx_${TS}.csv"

LOG=".ci-logs/index_guard_${TS}.log"
exec > >(tee -a "$LOG") 2>&1

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

echo "== Index guard =="
echo "ROOT=$ROOT"
echo "FIGDIR=$FIGDIR"
echo "CSV=$CSV"
echo "TMPCSV=$TMPCSV"
echo

if [ ! -f "$CSV" ]; then
  echo "::error::Index absent ($CSV). Lance 'bash tools/build_figures_index.sh' d'abord."
  exit 1
fi

# Régénère un CSV temporaire en désactivant l'anti-fermeture pour ne pas bloquer ici
MCGT_NO_SHELL_DROP=1 OUTCSV="$TMPCSV" OUTMD="/dev/null" \
  bash tools/build_figures_index.sh

# Normalisation : on compare (rel_path,sha256,bytes), sans l'en-tête, triés
norm() {
  awk -F',' 'NR>1{print $5","$6","$7}' "$1" | LC_ALL=C sort
}

DIFF=$(diff -u <(norm "$CSV") <(norm "$TMPCSV") || true)
COUNT_REPO=$(awk -F',' 'NR>1{c++}END{print c+0}' "$CSV")
COUNT_TMP=$(awk -F',' 'NR>1{c++}END{print c+0}' "$TMPCSV")

echo "Repo index: $COUNT_REPO lignes"
echo "Temp index: $COUNT_TMP lignes"
echo

if [ -n "$DIFF" ]; then
  echo "::error::Index désaligné entre repo et état actuel."
  echo "$DIFF"
  exit 1
fi

echo "Index OK (identique)."

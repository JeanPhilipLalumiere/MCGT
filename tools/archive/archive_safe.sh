#!/usr/bin/env bash
set -euo pipefail
DATE=$(date -u +"%Y%m%dT%H%M%SZ")
ARCHDIR="${1:-archive}"; shift || true
mkdir -p "${ARCHDIR}"
TMP_TAR="$(mktemp "/tmp/cleanup_${DATE}.XXXXXX.tar")"
OUT="${ARCHDIR}/cleanup_${DATE}.tar.gz"

DEFAULTS=( ".ci_poke" ".tmp-ci" ".tmp-gh-dist" ".tmp-cleanup-logs" "artifacts_*" "dist*" "dist_from_*" ".pytest_cache" "*.log" "*.bak" "*publish_testonly*.sh" )
INCLUDES=( "$@" )
[ "${#INCLUDES[@]}" -eq 0 ] && INCLUDES=( "${DEFAULTS[@]}" )

TO_ADD=()
# compgen -G retourne les matches du glob, rien si aucun.
for pat in "${INCLUDES[@]}"; do
  while IFS= read -r match; do
    # sécuriser: n’ajouter que si ça existe
    [ -e "$match" ] && TO_ADD+=("$match")
  done < <(bash -lc "compgen -G '$pat' || true")
done

if [ "${#TO_ADD[@]}" -eq 0 ]; then
  echo "ℹ️ Rien à archiver (aucun chemin existant pour les globs fournis)."
  exit 0
fi

echo "▶️ Création TAR: ${TMP_TAR}"
tar -cf "${TMP_TAR}" -- "${TO_ADD[@]}"

echo "▶️ Compression → ${OUT}"
gzip -9c "${TMP_TAR}" > "${OUT}"
rm -f "${TMP_TAR}"
echo "✅ Archive prête: ${OUT}"

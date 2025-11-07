#!/usr/bin/env bash
# Déplacement sécurisé des artefacts vers attic/<timestamp> (DRY-RUN par défaut)
set -euo pipefail
: "${DRY_RUN:=1}"
: "${SHOW:=40}"   # nombre d’éléments à prévisualiser
TS="$(date -u +%Y%m%dT%H%M%SZ)"
DEST="attic/${TS}"
OUTDIR=".ci-out/audit_attic_${TS}"
mkdir -p "${OUTDIR}"

FILES=$(mktemp)
DIRS=$(mktemp)
trap 'rm -f "$FILES" "$DIRS"' EXIT

# Candidats typiques à purger / déplacer
find . -type f \( -name '*.bak' -o -name '*~' -o -name '*.tmp' -o -name '*.lock' \) \
  -not -path './.git/*' | sort > "$FILES"

# Dossiers candidats
find . -type d \( -name '_tmp' -o -name 'old' -o -name 'attic' -o -name '.ci-out' \) \
  -not -path './.git/*' | sort > "$DIRS"

cp "$FILES" "${OUTDIR}/files.txt"
cp "$DIRS"  "${OUTDIR}/dirs.txt"

echo "# mv_to_attic — DRY_RUN=${DRY_RUN}"
echo "[files] $(wc -l < "$FILES")"
echo "[dirs ] $(wc -l < "$DIRS")"
echo "# Aperçu fichiers (SHOW=${SHOW})"
head -n "${SHOW}" "$FILES" || true
echo "# Aperçu dossiers (SHOW=${SHOW})"
head -n "${SHOW}" "$DIRS" || true
echo "# Listes complètes sauvegardées → ${OUTDIR}/files.txt  et  ${OUTDIR}/dirs.txt"

if [ "${DRY_RUN}" = "1" ]; then
  echo "(simulation) Rien n'est déplacé."
  exit 0
fi

mkdir -p "${DEST}/files" "${DEST}/dirs"
i=0
while IFS= read -r f; do
  [ -e "$f" ] || continue
  d="${DEST}/files/$(dirname "$f")"
  mkdir -p "$d"
  mv "$f" "$d/"
  i=$((i+1))
done < "$FILES"

while IFS= read -r d; do
  if [ "$d" = "./attic" ] || [[ "$d" == ./attic/* ]]; then continue; fi
  base=$(basename "$d")
  mv "$d" "${DEST}/dirs/${base}_moved"
done < "$DIRS"

echo "[OK] Déplacés: $i fichiers + dossiers listés → ${DEST}"

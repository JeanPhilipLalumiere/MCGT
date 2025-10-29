#!/usr/bin/env bash
# audit_title_variants_docs.sh — DRY RUN: recense les variantes dans README/docs/chapters (.md/.tex)
# Sortie: _tmp/title_audit_<ts>/hits.txt

set -euo pipefail
ROOT="$(git rev-parse --show-toplevel)"; cd "$ROOT"
mkdir -p _tmp
TS="$(date -u +%Y%m%dT%H%M%SZ)"
OUTDIR="_tmp/title_audit_${TS}"; mkdir -p "$OUTDIR"
OUT="$OUTDIR/hits.txt"

# canon
canon='Le Modèle de la Courbure Gravitationnelle du Temps'

# cibles docs (pas de code)
mapfile -t TARGETS < <(git ls-files \
  | grep -E '(^README\.md$|^docs/|^chapters?/|^chapitre/).*\.(md|tex)$' || true)

# modèles (sans lookaround)
PATTERNS=(
  '[Mm]od[eè]le de la courbure gravitationnelle temporelle'
  'Mod[eè]le de la Courbure Gravitationnelle Temporelle'
  'mod[eè]le.*gravitationnelle.*temporel(le)?'
)

: > "$OUT"
for f in "${TARGETS[@]}"; do
  [[ -f "$f" ]] || continue
  for p in "${PATTERNS[@]}"; do
    if grep -Eiq "$p" "$f"; then
      echo ">>> $f"        >> "$OUT"
      grep -Ein "$p" "$f"  >> "$OUT" || true
      echo                 >> "$OUT"
    fi
  done
done

if [[ -s "$OUT" ]]; then
  echo "[FOUND] Variantes détectées → $OUT"
else
  echo "[CLEAN] Aucune variante trouvée dans les docs (md/tex)."
fi

read -r -p $'Terminé. ENTER pour fermer…\n' _ </dev/tty || true

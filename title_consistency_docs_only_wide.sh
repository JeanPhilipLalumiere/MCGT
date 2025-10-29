#!/usr/bin/env bash
# title_consistency_docs_only_wide.sh — doc-only title harmonization (safe, no code/package change)
set -euo pipefail
ROOT="$(git rev-parse --show-toplevel)"; cd "$ROOT"
BR="chore/title-docs-wide-$(date -u +%Y%m%dT%H%M%SZ)"
git switch -c "$BR" >/dev/null

# fichiers doc seulement
mapfile -t DOCS < <(git ls-files '*.md' '*.tex' '*.rst')

# patterns: variantes courantes à remplacer par la forme canonique
CANON='Le Modèle de la Courbure Gravitationnelle du Temps'
for f in "${DOCS[@]}"; do
  # remplace variantes (insensible casse sur 'temporelle')
  sed -i \
    -e "s/[Ll]e[ ]\?mod[eè]le de la courbure gravitationnelle temporelle/${CANON}/g" \
    -e "s/[Mm]od[eè]le de la Courbure Gravitationnelle Temporelle/${CANON}/g" \
    -e "s/[Mm]od[eè]le de la courbure gravitationnelle du temps/${CANON}/g" \
    "$f"
done

echo "[DIFF] (aperçu court)"
git --no-pager diff --stat | tail -n +1

if git diff --quiet; then
  echo "[INFO] Aucun changement (docs déjà harmonisés)."
else
  git add -A
  git commit -m "docs: harmonize project title → « ${CANON} » (doc-only)" >/dev/null
  git push -u origin HEAD >/dev/null
  gh pr create --fill >/dev/null || true
  echo "[DONE] PR doc-only créée."
fi

read -r -p $'ENTER pour fermer…\n' _ </dev/tty || true

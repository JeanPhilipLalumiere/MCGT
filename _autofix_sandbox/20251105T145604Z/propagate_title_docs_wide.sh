#!/usr/bin/env bash
# propagate_title_docs_wide.sh — harmonise le titre dans README/docs/chapitres (pas de code)
set -euo pipefail
ROOT="$(git rev-parse --show-toplevel)"; cd "$ROOT"
BR="chore/title-propagation-wide"
git switch -c "$BR"

# 1) Cible: docs/ + README + chapters/chapitre/ *.md *.tex ; on épargne code et data binaires
mapfile -t TARGETS < <(git ls-files \
  | grep -E '(^README\.md$|^docs/|^chapters?/|^chapitre/|\.md$|\.tex$)' || true)

# 2) Remplacements robustes (sans lookaround)
# variantes communes → forme canonique
canon="Le Modèle de la Courbure Gravitationnelle du Temps"
for f in "${TARGETS[@]}"; do
  [[ -f "$f" ]] || continue
  sed -i \
    -e 's/[Mm]od[eè]le de la courbure gravitationnelle temporelle/'"$canon"'/g' \
    -e 's/Mod[eè]le de la Courbure Gravitationnelle Temporelle/'"$canon"'/g' \
    "$f" || true
done

git add "${TARGETS[@]}" 2>/dev/null || true
git commit -m "docs: harmonisation étendue du titre « Le Modèle de la Courbure Gravitationnelle du Temps » (docs-only)"
git push -u origin "$BR"

gh pr create \
  --title "docs: harmonisation étendue du titre — Le Modèle de la Courbure Gravitationnelle du Temps" \
  --body "Propagation du titre officiel dans README/docs/chapitres. Aucun changement de code/package." \
  --base main --head "$BR"

# anti-fermeture
read -r -p $'Terminé. ENTER pour fermer…\n' _ </dev/tty || true

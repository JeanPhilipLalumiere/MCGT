#!/usr/bin/env bash
# propagate_title_docs_only_safe.sh
# - Branche docs-only
# - Remplace variantes textuelles par la forme canonique
# - Cible .md/.tex dans README, docs/, chapter*/chapitre*/ (pas de code)
# - Ouvre PR
# - Anti-fermeture

set -euo pipefail
ROOT="$(git rev-parse --show-toplevel)"; cd "$ROOT"
BR="chore/title-propagation-docs-wide"
git fetch origin
git switch -c "$BR"

canon="Le Modèle de la Courbure Gravitationnelle du Temps"

# Cible: README.md, docs/**, chapter*/**, chapitre*/**, *.md/*.tex du dépôt qui sont sous contrôle Git
mapfile -t TARGETS < <(git ls-files | grep -E '(^README\.md$|^docs/|^chapters?/|^chapitre/).*\.(md|tex)$' || true)

# Remplacements sans lookaround (compatibles sed POSIX)
for f in "${TARGETS[@]}"; do
  [[ -f "$f" ]] || continue
  sed -i \
    -e "s/[Mm]od[eè]le de la courbure gravitationnelle temporelle/${canon}/g" \
    -e "s/Mod[eè]le de la Courbure Gravitationnelle Temporelle/${canon}/g" \
    "$f" || true
done

# Commit si diff
if ! git diff --quiet; then
  git add "${TARGETS[@]}" 2>/dev/null || true
  git commit -m "docs: harmonisation du titre « ${canon} » (docs-only)"
  git push -u origin "$BR"
  gh pr create \
    --title "docs: harmonisation titre — ${canon} (docs-only)" \
    --body "Propagation du titre officiel dans README/docs/chapitres (.md/.tex). Aucun changement de code ni de package." \
    --base main --head "$BR" || true
else
  echo "[INFO] Aucun changement détecté (docs déjà harmonisés ?)."
fi

read -r -p $'Terminé. ENTER pour fermer…\n' _ </dev/tty || true

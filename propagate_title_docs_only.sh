#!/usr/bin/env bash
# propagate_title_docs_only.sh — Renomme le titre dans la documentation (safe)
set -euo pipefail
REPO_ROOT="$(git rev-parse --show-toplevel)"; cd "$REPO_ROOT"

BR="chore/title-propagation-docs"
git switch -c "$BR"

# 1) Dry-run: lister les occurrences candidates (sans binaires / .git / figures)
echo "[DRY-RUN] Occurrences potentielles (affichage 200 lignes max)…"
{ command -v rg >/dev/null && \
  rg -n -S -M 200 --hidden --glob '!{.git,**/*.png,**/*.pdf,**/*.svg,**/*.ipynb,**/*.pyc,**/build/**,**/.venv/**}' \
  -e 'mod[eè]le de la courbure gravitationnelle temporelle' \
  -e 'Mod[eè]le de la Courbure Gravitationnelle Temporelle' \
  -e 'MCGT(?![^])' || true; } | head -n 200

# 2) Remplacements docs-only (README, docs/, chapters, CITATION déjà traité)
#   - On garde strictement le package/code intact.
mapfile -t TARGETS < <(git ls-files \
  | grep -E '(^README\.md$|^docs/|^chapters?/|^chapitre/|^CITATION\.cff$|^LICENSE|^CHANGELOG|^RELEASE|^.*\.md$|^.*\.tex$)' || true)

# Remplacement normalisé du titre officiel
for f in "${TARGETS[@]}"; do
  [[ -f "$f" ]] || continue
  sed -i \
    -e 's/[Mm]od[eè]le de la courbure gravitationnelle temporelle/Le Modèle de la Courbure Gravitationnelle du Temps/g' \
    -e 's/Mod[eè]le de la Courbure Gravitationnelle Temporelle/Le Modèle de la Courbure Gravitationnelle du Temps/g' \
    "$f" || true
done

# 3) Commit + PR
git add "${TARGETS[@]}" 2>/dev/null || true
git commit -m "docs: harmonise le titre « Le Modèle de la Courbure Gravitationnelle du Temps » (docs-only)"
git push -u origin "$BR"

echo "[INFO] Ouvre la PR…"
gh pr create --title "docs: titre harmonisé — Le Modèle de la Courbure Gravitationnelle du Temps" \
             --body "Harmonisation du titre dans la documentation. Aucun changement de code/package (mcgt intact)." \
             --base main --head "$BR"

# Petit garde-fou pour ne pas fermer la fenêtre
read -r -p $'Terminé. ENTER pour fermer…\n' _ </dev/tty || true

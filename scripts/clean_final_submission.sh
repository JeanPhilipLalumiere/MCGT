#!/usr/bin/env bash
set -euo pipefail

# Usage:
#  ./scripts/clean_final_submission.sh     -> dry-run (list only)
#  ./scripts/clean_final_submission.sh --apply  -> actually delete
#
# IMPORTANT: vérifie la sortie en dry-run avant --apply.

APPLY=0
if [[ "${1:-}" == "--apply" ]]; then APPLY=1; fi

# patterns à rechercher (ajoute/modifie si besoin)
declare -a PATTERNS=(
  "dist"
  "build"
  "*.egg-info"
  "__pycache__"
  "*.pyc"
  ".pytest_cache"
  ".mypy_cache"
  ".cache"
  ".tox"
  ".venv"
  "venv"
  "env"
  "phase4_*.log"
  "phase4_*.log.*"
  "*.log"
  "/tmp/venv*"
  "MCGT-clean"
  "pyproject.toml.bak*"
  "pyproject.toml.before*"
  "*~"
  ".DS_Store"
  "Thumbs.db"
  ".ipynb_checkpoints"
)

echo "==> Dry-run: fichiers trouvés (ne supprime rien si pas --apply) ==>"
TO_DELETE=()
# find matches (prune .git)
for p in "${PATTERNS[@]}"; do
  # use two passes: first directories named exactly (dist, build, MCGT-clean), then by name/glob for files
  found=$(find . -path "./.git" -prune -o -iname "$p" -print 2>/dev/null || true)
  if [[ -n "$found" ]]; then
    while IFS= read -r f; do
      # ignore leading "./"
      f="${f#./}"
      # skip empty
      [[ -z "$f" ]] && continue
      TO_DELETE+=("$f")
    done <<< "$found"
  fi
done

# unique & sort
IFS=$'\n' sorted=($(printf "%s\n" "${TO_DELETE[@]}" | sed '/^$/d' | sort -u))
unset IFS

if [[ ${#sorted[@]} -eq 0 ]]; then
  echo "=> Aucun fichier candidat trouvé pour suppression."
  exit 0
fi

printf "\n==> %d élément(s) trouvé(s) :\n" "${#sorted[@]}"
for item in "${sorted[@]}"; do
  echo " - $item"
done

if [[ "$APPLY" -eq 0 ]]; then
  echo ""
  echo "Dry-run complet. Relance avec --apply pour supprimer ces fichiers."
  exit 0
fi

# Safety: create a tarball backup before deleting (timestamped)
BACKUP="/tmp/mcgt_clean_backup_$(date +%Y%m%d_%H%M%S).tar.gz"
echo "Création d'une archive de sauvegarde (au cas où) : $BACKUP"
tar -czf "$BACKUP" "${sorted[@]}" || { echo "Erreur lors de la création de l'archive. Abandon."; exit 1; }

# Delete for real (use rm -rf on each path)
echo "Suppression des éléments..."
for item in "${sorted[@]}"; do
  echo "rm -rf '$item'"
  rm -rf -- "$item"
done

echo "Suppression terminée. Vérifier git status."
echo "Si tout OK, tu peux committer les suppressions :"
echo "  git add -A && git commit -m 'chore: remove build artifacts and temporary files for final submission' && git push"

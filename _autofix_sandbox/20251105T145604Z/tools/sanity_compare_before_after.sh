#!/usr/bin/env bash
# tools/sanity_compare_before_after.sh
# Compare deux refs Git (avant/après) au niveau des blobs (hash par fichier).
# - Ne plante pas si une ref manque.
# - Sorties dans _tmp/sanity_*.txt

set -u  # volontairement sans -e pour ne pas fermer le shell
mkdir -p _tmp

# Heuristiques pour la ref "avant"
BEFORE_REF="${1:-}"
AFTER_REF="${2:-}"

if [[ -z "${BEFORE_REF}" ]]; then
  # Branche “backup” vue dans tes logs; sinon fallback sur origin/main
  if git show-ref --verify --quiet "refs/remotes/origin/backup/origin-main-before-finalize"; then
    BEFORE_REF="origin/backup/origin-main-before-finalize"
  else
    BEFORE_REF="origin/main"
  fi
fi

if [[ -z "${AFTER_REF}" ]]; then
  # Par défaut : ta branche de réécriture poussée
  if git show-ref --verify --quiet "refs/remotes/origin/rewrite/main-20251026T134200"; then
    AFTER_REF="origin/rewrite/main-20251026T134200"
  else
    AFTER_REF="$(git rev-parse --abbrev-ref HEAD 2>/dev/null || echo HEAD)"
  fi
fi

echo "[INFO] BEFORE_REF=${BEFORE_REF}"
echo "[INFO] AFTER_REF =${AFTER_REF}"

dump_tree() {
  local ref="$1" out="$2"
  if git rev-parse --verify -q "$ref" >/dev/null; then
    # format : <blob_sha> <path>
    git ls-tree -r --full-tree "$ref" \
      | awk '$2 == "blob" {print $3, $4}' \
      > "$out"
    echo "[OK] dump ${ref} -> ${out}"
  else
    echo "[WARN] ref introuvable: $ref ; fichier vide: ${out}"
    : > "$out"
  fi
}

dump_tree "${BEFORE_REF}" "_tmp/sanity_before.txt"
dump_tree "${AFTER_REF}"  "_tmp/sanity_after.txt"

# Diffs
comm -23 <(cut -d' ' -f2- "_tmp/sanity_after.txt"  | sort) \
         <(cut -d' ' -f2- "_tmp/sanity_before.txt" | sort) \
  > "_tmp/sanity_added_paths.txt"

comm -13 <(cut -d' ' -f2- "_tmp/sanity_after.txt"  | sort) \
         <(cut -d' ' -f2- "_tmp/sanity_before.txt" | sort) \
  > "_tmp/sanity_removed_paths.txt"

# Fichiers présents des deux côtés mais avec hash différent
join -j2 -o 1.1,1.2,2.1 \
  <(sort -k2 "_tmp/sanity_before.txt") \
  <(sort -k2 "_tmp/sanity_after.txt") \
  | awk '$1 != $3 {print $2}' \
  > "_tmp/sanity_changed_paths.txt"

echo
echo "──────── Résumé comparatif ────────"
echo "Ajouts   : $(wc -l < _tmp/sanity_added_paths.txt)"
echo "Suppress : $(wc -l < _tmp/sanity_removed_paths.txt)"
echo "Modifiés : $(wc -l < _tmp/sanity_changed_paths.txt)"
echo "———————————————————————————————"
echo "Détails :"
echo "  _tmp/sanity_added_paths.txt"
echo "  _tmp/sanity_removed_paths.txt"
echo "  _tmp/sanity_changed_paths.txt"

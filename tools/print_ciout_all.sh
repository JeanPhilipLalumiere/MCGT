#!/usr/bin/env bash
# Imprime TOUT le contenu des fichiers texte sous .ci-out/ dans le log (stdout)
# Usage:
#   bash tools/print_ciout_all.sh                # parcourt .ci-out/
#   bash tools/print_ciout_all.sh path/to/dir    # autre dossier racine
#   bash tools/print_ciout_all.sh .ci-out '*.tsv' '*.txt'  # filtre par glob(s)

set -Eeuo pipefail
ROOT="${1:-.ci-out}"
shift || true

# Si des globs sont fournis (ex: '*.txt' '*.tsv'), on les utilisera pour filtrer
FILTERS=("$@")
shopt -s nullglob globstar

if [[ ! -d "$ROOT" ]]; then
  echo "[print-ciout] dossier introuvable: $ROOT" >&2
  exit 1
fi

# Fonction: teste si fichier est texte (rapide et portable)
is_text() {
  local f="$1"
  # 'file -bi' si dispo, sinon heuristique grep -Iq
  if command -v file >/dev/null 2>&1; then
    local mt
    mt="$(file -bi -- "$f" 2>/dev/null || true)"
    [[ "$mt" == text/* || "$mt" == */json* || "$mt" == */xml* || "$mt" == */yaml* || "$mt" == */toml* ]]
  else
    grep -Iq . -- "$f"
  fi
}

# Liste des fichiers (avec filtres éventuels)
collect() {
  if ((${#FILTERS[@]} > 0)); then
    for pat in "${FILTERS[@]}"; do
      # shellcheck disable=SC2044
      for f in $(cd "$ROOT" && printf '%s\0' **/"$pat" | xargs -0 -I{} echo "$ROOT"/{}); do
        [[ -f "$f" ]] && echo "$f"
      done
    done | sort -u
  else
    find "$ROOT" -type f -print | sort
  fi
}

echo
for f in $(collect); do
  if is_text "$f"; then
    echo "========================================================================"
    echo ">>> FILE: $f"
    echo "========================================================================"
    # Imprime tout le fichier (sans troncature)
    sed -n '1,999999p' -- "$f"
    echo
  else
    # Binaire ou inconnu → résumé seulement
    size=$(wc -c <"$f" | tr -d ' ')
    echo "========================================================================"
    echo ">>> FILE: $f  (binaire, $size bytes) — contenu non affiché"
    echo "========================================================================"
    echo
  fi
done

echo "[print-ciout] terminé."

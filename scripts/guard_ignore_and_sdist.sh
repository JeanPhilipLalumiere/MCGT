#!/usr/bin/env bash
# Guard: détecter les fichiers trackés mais ignorés par les .gitignore du dépôt.
# Codes de retour :
#   0   = OK, rien à signaler
#   123 = au moins un fichier est à la fois tracké et ignoré (à corriger)
#   1   = autre erreur inattendue

set -Eeuo pipefail

echo "=== GUARD: tracked files ignored check ==="

# On récupère tous les fichiers trackés et on demande à git quels sont ceux
# qui sont ignorés par les fichiers d'ignore du dépôt (.gitignore, .git/info/exclude).
# On filtre pour ignorer les règles provenant des ignores globaux de l'environnement
# (chemins absolus du style /home/runner/.config/git/ignore).

TRACKED_IGNORED=$(
  git ls-files -z \
    | xargs -0 -I{} git check-ignore --verbose "{}" 2>/dev/null \
    | awk '
        {
          # $1 contient par exemple ".gitignore:6:pattern"
          # ou "/home/runner/.config/git/ignore:12:pattern"
          meta=$1;
          file=$NF;
          split(meta, parts, ":");
          path=parts[1];

          # Si le chemin de la règle ne commence PAS par "/",
          # c’est un fichier d’ignore du dépôt (.gitignore, .git/info/exclude, etc.).
          if (substr(path, 1, 1) != "/") {
            print file;
          }
        }
      ' \
    | sort -u \
    || true
)

if [ -n "${TRACKED_IGNORED}" ]; then
  echo "[ERREUR] Fichiers trackés mais ignorés par les .gitignore du dépôt :"
  echo "${TRACKED_IGNORED}"
  echo
  echo "[ASTUCE] Pour chaque fichier ci-dessus :"
  echo "  - s’il s’agit d’un artefact (log, build, cache, etc.) :"
  echo "        git rm --cached <chemin/du/fichier>"
  echo "  - s’il s’agit d’un vrai fichier de projet :"
  echo "        ajuster les .gitignore pour qu’il ne soit plus ignoré"
  exit 123
fi

echo "OK: aucun fichier tracké + ignoré trouvé."
exit 0

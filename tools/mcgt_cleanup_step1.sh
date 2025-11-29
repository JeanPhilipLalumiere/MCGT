#!/usr/bin/env bash
# Scan non destructif des candidats au nettoyage dans MCGT
# - Liste l'état Git
# - Fichiers non suivis
# - Fichiers/répertoires "junk" (tmp, bak, caches, etc.)
# Résultats dans /tmp/mcgt_cleanup_step1_<timestamp>/

set -Eeuo pipefail

echo "[INFO] Scan de nettoyage MCGT — étape 1 (lecture seule)"

# Vérification de base : être dans un repo Git avec pyproject.toml
if [ ! -d ".git" ] || [ ! -f "pyproject.toml" ]; then
  echo "[ERREUR] Ce script doit être lancé depuis la racine du dépôt MCGT."
  exit 1
fi

timestamp="$(date +%Y%m%dT%H%M%S)"
outdir="/tmp/mcgt_cleanup_step1_${timestamp}"
mkdir -p "${outdir}"

echo "[INFO] Dossier de sortie : ${outdir}"

###############################################################################
# 1. État Git (tracked / modified / untracked)
###############################################################################

echo "[INFO] Capture de git status --short"
git status --short > "${outdir}/git_status_short.txt"

echo "[INFO] Extraction des fichiers non suivis (untracked)"
# Lignes commençant par "?? "
grep '^?? ' "${outdir}/git_status_short.txt" | sed 's/^?? //' > "${outdir}/untracked_files.txt" || true

###############################################################################
# 2. Recherche de répertoires 'junk' classiques
###############################################################################

echo "[INFO] Recherche de répertoires techniques (__pycache__, .ipynb_checkpoints, etc.)"
find . \
  -type d \( \
    -name '__pycache__' -o \
    -name '.ipynb_checkpoints' -o \
    -name '.mypy_cache' -o \
    -name '.ruff_cache' \
  \) \
  -print | sort > "${outdir}/junk_dirs.txt"

###############################################################################
# 3. Recherche de fichiers 'junk' classiques
###############################################################################

echo "[INFO] Recherche de fichiers temporaires / historiques (bak, tmp, logs, etc.)"
find . \
  -type f \( \
    -name '*~' -o \
    -name '*.tmp' -o \
    -name '*.bak' -o \
    -name '*.swp' -o \
    -name '*.swo' -o \
    -name '*.log' \
  \) \
  ! -path './.git/*' \
  -print | sort > "${outdir}/junk_files_raw.txt"

# On ajoute les tailles pour prioriser
echo "[INFO] Ajout des tailles (du -b) pour prioriser les plus lourds"
> "${outdir}/junk_files_with_size.txt"
while IFS= read -r f; do
  if [ -f "$f" ]; then
    size_bytes="$(du -b "$f" | awk '{print $1}')"
    printf "%12s  %s\n" "${size_bytes}" "${f}" >> "${outdir}/junk_files_with_size.txt"
  fi
done < "${outdir}/junk_files_raw.txt"

sort -nr "${outdir}/junk_files_with_size.txt" > "${outdir}/junk_files_sorted_by_size.txt"

###############################################################################
# 4. Petit résumé à l'écran
###############################################################################

echo
echo "========== RÉSUMÉ =========="
echo "  - git_status_short.txt              -> ${outdir}/git_status_short.txt"
echo "  - untracked_files.txt               -> ${outdir}/untracked_files.txt"
echo "  - junk_dirs.txt                     -> ${outdir}/junk_dirs.txt"
echo "  - junk_files_raw.txt                -> ${outdir}/junk_files_raw.txt"
echo "  - junk_files_sorted_by_size.txt     -> ${outdir}/junk_files_sorted_by_size.txt"
echo
echo "[INFO] AUCUN fichier n'a été supprimé."
echo "[INFO] Étape suivante : ouvrir ces fichiers et décider de ce qui est:"
echo "        - à supprimer,"
echo "        - à déplacer dans attic/,"
echo "        - à conserver (et éventuellement documenter/ajouter au manifest)."
echo "============================="

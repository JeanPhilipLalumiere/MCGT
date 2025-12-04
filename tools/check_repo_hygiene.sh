#!/usr/bin/env bash
# check_repo_hygiene.sh
set -Eeuo pipefail

echo "[CHECK] Hygiène des répertoires internes (_attic_untracked, _autofix_sandbox, _tmp)"

root_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$root_dir"

status=0

# 1) _attic_untracked doit être absent ou vide
if [ -d "_attic_untracked" ]; then
    if find _attic_untracked -mindepth 1 -type f -o -type d | grep -q .; then
        echo "[FAIL] _attic_untracked contient encore des fichiers ou sous-répertoires."
        status=1
    else
        echo "[OK] _attic_untracked existe mais est vide."
    fi
else
    echo "[OK] _attic_untracked n'existe pas (rien à nettoyer)."
fi

# 2) _autofix_sandbox doit être absent ou vide
if [ -d "_autofix_sandbox" ]; then
    if find _autofix_sandbox -mindepth 1 -type f -o -type d | grep -q .; then
        echo "[FAIL] _autofix_sandbox contient encore des fichiers ou sous-répertoires."
        status=1
    else
        echo "[OK] _autofix_sandbox existe mais est vide."
    fi
else
    echo "[OK] _autofix_sandbox n'existe pas (rien à nettoyer)."
fi

# 3) _tmp ne doit contenir aucun sous-répertoire (uniquement des fichiers "tableau de bord")
if [ -d "_tmp" ]; then
    if find _tmp -mindepth 1 -type d | grep -q .; then
        echo "[FAIL] _tmp contient au moins un sous-répertoire."
        echo "       -> Archiver ces runs / logs dans attic/snapshots/, puis supprimer les répertoires."
        status=1
    else
        echo "[OK] _tmp ne contient aucun sous-répertoire (seulement des fichiers)."
    fi
else
    echo "[WARN] _tmp n'existe pas – ce n'est pas bloquant, mais inattendu si tu utilises les tableaux de bord."
fi

if [ "$status" -eq 0 ]; then
    echo "[SUCCESS] Hygiène des répertoires internes : OK"
else
    echo "[ERROR] Hygiène des répertoires internes : des corrections sont nécessaires."
fi

exit "$status"

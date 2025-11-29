#!/usr/bin/env bash
set -Eeuo pipefail
IFS=$'\n\t'

# Racine du dépôt
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

echo "=== MCGT: cleanup pkgmeta v1 ==="
echo "Dossier courant: $ROOT"
echo

mkdir -p attic/pkgmeta attic/generated

moved_bkp=0
moved_egg=0

echo "[INFO] Recherche des répertoires .bkp_pkgmeta_* à déplacer dans attic/pkgmeta/ ..."
for d in .bkp_pkgmeta_*; do
    if [[ -d "$d" ]]; then
        echo "[MOVE] $d -> attic/pkgmeta/$d"
        if [[ -e "attic/pkgmeta/$d" ]]; then
            # Si jamais une ancienne copie existe, on suffixe avec la date
            stamp="$(date -u +%Y%m%dT%H%M%SZ)"
            echo "[WARN] attic/pkgmeta/$d existe déjà, déplacement vers attic/pkgmeta/${d}.${stamp}"
            mv "$d" "attic/pkgmeta/${d}.${stamp}"
        else
            mv "$d" "attic/pkgmeta/"
        fi
        moved_bkp=1
    fi
done

echo
echo "[INFO] Vérification éventuelle de zz_tools.egg-info ..."
if [[ -d "zz_tools.egg-info" ]]; then
    stamp="$(date -u +%Y%m%dT%H%M%SZ)"
    dest="attic/generated/zz_tools.egg-info.${stamp}"
    echo "[MOVE] zz_tools.egg-info -> ${dest}"
    mkdir -p "$(dirname "${dest}")"
    mv "zz_tools.egg-info" "${dest}"
    moved_egg=1
else
    echo "[INFO] Aucun zz_tools.egg-info à déplacer."
fi

# Log dans TODO_CLEANUP.md si présent
if [[ -f "TODO_CLEANUP.md" ]]; then
    echo "[INFO] Ajout d'une entrée dans TODO_CLEANUP.md"
    {
        echo ""
        echo "## [$(date -u +%Y-%m-%dT%H:%M:%SZ)] mcgt_cleanup_pkgmeta_v1"
        if [[ "${moved_bkp}" -eq 1 ]]; then
            echo "- Déplacé .bkp_pkgmeta_* vers attic/pkgmeta/"
        else
            echo "- Aucun .bkp_pkgmeta_* à déplacer"
        fi
        if [[ "${moved_egg}" -eq 1 ]]; then
            echo "- Déplacé zz_tools.egg-info vers attic/generated/ (suffixé par timestamp)"
        else
            echo "- Aucun zz_tools.egg-info à déplacer"
        fi
    } >> "TODO_CLEANUP.md"
else
    echo "[INFO] TODO_CLEANUP.md absent, aucun log ajouté."
fi

echo
echo "[OK] cleanup pkgmeta terminé."

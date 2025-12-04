#!/usr/bin/env bash
# tools/cleanup_hygiene_residuals.sh
# Dernière passe SAFE : snapshot + purge de _attic_untracked et des sous-répertoires de _tmp

set -Eeuo pipefail

root_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$root_dir"

ts="$(date +%Y%m%dT%H%M%SZ)"
mkdir -p attic/snapshots

echo "[CLEANUP] Démarrage cleanup_hygiene_residuals à $ts"

########################################
# 1) _attic_untracked -> snapshot + purge
########################################

if [ -d "_attic_untracked" ]; then
    if find _attic_untracked -mindepth 1 -print -quit | grep -q .; then
        snap_attic="attic/snapshots/attic_untracked_rest_${ts}.tar.gz"
        echo "[STEP] Snapshot du contenu résiduel de _attic_untracked -> ${snap_attic}"
        tar -czf "${snap_attic}" _attic_untracked
        echo "[STEP] Suppression de _attic_untracked (tout est archivé)"
        rm -rf _attic_untracked
    else
        echo "[INFO] _attic_untracked existe mais est déjà vide."
    fi
else
    echo "[INFO] _attic_untracked n'existe pas (rien à faire)."
fi

########################################
# 2) Sous-répertoires de _tmp -> snapshot + purge
########################################

if [ -d "_tmp" ]; then
    echo "[CHECK] Recherche de sous-répertoires dans _tmp..."
    # On liste tous les répertoires sous _tmp (n'importe quelle profondeur)
    mapfile -t tmp_dirs < <(find _tmp -mindepth 1 -type d | sort || true)

    if [ "${#tmp_dirs[@]}" -eq 0 ]; then
        echo "[INFO] Aucun sous-répertoire dans _tmp (OK pour l'hygiène)."
    else
        echo "[STEP] Sous-répertoires trouvés dans _tmp :"
        for d in "${tmp_dirs[@]}"; do
            echo "       - $d"
        done

        snap_tmp="attic/snapshots/tmp_residual_dirs_${ts}.tar.gz"
        echo "[STEP] Snapshot des sous-répertoires de _tmp -> ${snap_tmp}"
        tar -czf "${snap_tmp}" "${tmp_dirs[@]}"

        echo "[STEP] Suppression des sous-répertoires de _tmp (contenu archivé)"
        rm -rf "${tmp_dirs[@]}"
    fi
else
    echo "[WARN] _tmp n'existe pas – inattendu, mais pas bloquant pour ce script."
fi

echo "[DONE] cleanup_hygiene_residuals terminé."

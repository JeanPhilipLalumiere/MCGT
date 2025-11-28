#!/usr/bin/env bash
# Script de release MCGT avec garde-fou (fenêtre ne se ferme pas immédiatement)

set -Eeuo pipefail

on_exit() {
    code=$?
    echo
    if [ "$code" -eq 0 ]; then
        echo "[OK] Script terminé sans erreur."
    else
        echo "[ERREUR] Le script s'est terminé avec le code : $code"
        echo "[ASTUCE] Vérifie les messages ci-dessus pour voir où ça a coincé."
    fi
    # Garde-fou : empêcher la fermeture immédiate de la fenêtre
    read -rp "Appuie sur Entrée pour fermer cette fenêtre..." _ || true
}

trap on_exit EXIT

main() {
    cd "${HOME}/MCGT"

    ############################################
    # 0) Choisir et définir la nouvelle version
    ############################################

    # IMPORTANT :
    # - Ouvre pyproject.toml et mets à jour la ligne "version = ..."
    #   Exemple : version = "0.3.10"
    # - Mets EXACTEMENT la même valeur ici :
    NEW_VERSION="0.3.10"   # <-- À ADAPTER AVANT D'EXÉCUTER

    echo "==============================================="
    echo "   MCGT – Script de release avec garde-fou"
    echo "==============================================="
    echo
    echo "Nouvelle version prévue : ${NEW_VERSION}"
    echo

    ############################################
    # 0bis) Vérification stricte de la version
    ############################################

    echo "[INFO] Vérification de la version dans pyproject.toml"

    if ! grep -qE '^version\s*=' pyproject.toml; then
        echo "⚠ Impossible de trouver une ligne 'version = \"...\"' dans pyproject.toml"
        echo "  → Ajoute ou corrige la clé version dans pyproject.toml, puis relance."
        exit 1
    fi

    PYPROJECT_VERSION=$(grep -E '^version\s*=' pyproject.toml | head -n1 | sed -E 's/.*"([^"]+)".*/\1/')
    echo "version = \"${PYPROJECT_VERSION}\""

    if [ "${PYPROJECT_VERSION}" != "${NEW_VERSION}" ]; then
        echo
        echo "⚠ Incohérence entre pyproject.toml et NEW_VERSION."
        echo "   pyproject.toml : ${PYPROJECT_VERSION}"
        echo "   NEW_VERSION    : ${NEW_VERSION}"
        echo "→ Modifie soit pyproject.toml, soit NEW_VERSION dans le script, puis relance."
        exit 1
    fi

    ############################################
    # 1) Sanity check Git
    ############################################

    echo
    echo "### Git status avant build"
    echo "-----------------------------------------------"
    git status
    echo "-----------------------------------------------"

    ############################################
    # 2) Nettoyage des anciens artefacts de build
    ############################################

    echo
    echo "### Cleanup dist/build/egg-info"
    echo "-----------------------------------------------"
    rm -rf dist build ./*.egg-info
    echo "[OK] Répertoires dist/, build/ et *.egg-info nettoyés."
    echo "-----------------------------------------------"

    ############################################
    # 3) Phase tests rapides (pytest filtré)
    ############################################

    echo
    echo "### Phase tests rapides (pytest filtré)"
    echo "-----------------------------------------------"
    if [ -d "tests" ]; then
        echo "[INFO] Répertoire tests/ trouvé."
        echo "[INFO] Lancement de pytest limité à tests/ avec ignore des backups :"
        echo "       - _attic_untracked/"
        echo "       - _autofix_sandbox/"
        echo

        if ! python -m pytest -q tests --ignore _attic_untracked --ignore _autofix_sandbox; then
            echo
            echo "⚠ Pytest a retourné une erreur (sur les tests officiels)."
            echo "  → Corrige les tests dans tests/ avant de continuer vers une release."
            exit 1
        fi
        echo "[OK] pytest (filtré) terminé sans erreur."
    else
        echo "[INFO] Aucun répertoire tests/ détecté, pytest ignoré."
    fi
    echo "-----------------------------------------------"

    ############################################
    # 4) Build du paquet (sdist + wheel)
    ############################################

    echo
    echo "### Build Python (sdist + wheel)"
    echo "-----------------------------------------------"
    if ! python -m build; then
        echo
        echo "⚠ Échec du build (python -m build)."
        echo "  → Vérifie les messages d'erreur ci-dessus."
        exit 1
    fi
    echo "[OK] Build effectué (dist/ contient sdist + wheel)."
    echo "-----------------------------------------------"

    ############################################
    # 5) Vérification des artefacts avec twine
    ############################################

    echo
    echo "### twine check dist/*"
    echo "-----------------------------------------------"
    if ! python -m twine check dist/*; then
        echo
        echo "⚠ twine check a détecté un problème dans les artefacts."
        echo "  → Corrige avant d'aller plus loin (PyPI / release publique)."
        exit 1
    fi
    echo "[OK] twine check dist/* passé avec succès."
    echo "-----------------------------------------------"

    ############################################
    # 6) Commit de la version + scripts + manifests
    ############################################

    echo
    echo "### Git status avant commit"
    echo "-----------------------------------------------"
    git status
    echo "-----------------------------------------------"

    echo
    echo "### Ajout des fichiers modifiés principaux"
    echo "-----------------------------------------------"
    # On ajoute la version, les manifests, les outils et tous les scripts chapitre01–10.
    # (git add sur des fichiers non changés est sans effet et sans danger.)
    git add pyproject.toml \
           zz-manifests/manifest_master.json \
           zz-manifests/manifest_publication.json \
           tools/*.sh \
           zz-scripts/chapter01/*.py \
           zz-scripts/chapter02/*.py \
           zz-scripts/chapter03/*.py \
           zz-scripts/chapter04/*.py \
           zz-scripts/chapter05/*.py \
           zz-scripts/chapter06/*.py \
           zz-scripts/chapter07/*.py \
           zz-scripts/chapter08/*.py \
           zz-scripts/chapter09/*.py \
           zz-scripts/chapter10/*.py 2>/dev/null || true

    echo "[INFO] Fichiers principaux ajoutés à l'index git (si modifiés)."
    echo "-----------------------------------------------"

    # Garde-fou : vérifier qu'il y a bien quelque chose en staging
    if git diff --cached --quiet; then
        echo
        echo "⚠ Aucun changement n'a été ajouté à l'index."
        echo "  → Vérifie que pyproject.toml a bien été mis à jour vers ${NEW_VERSION},"
        echo "    et que les fichiers que tu veux inclure sont modifiés."
        echo "  → Tu peux aussi faire un 'git add ...' manuel puis relancer ce script."
        exit 1
    fi

    echo
    echo "### Commit de la release"
    echo "-----------------------------------------------"
    COMMIT_MSG="chore: release ${NEW_VERSION}"
    git commit -m "${COMMIT_MSG}" || {
        echo
        echo "⚠ Échec du commit."
        echo "  → Soit un hook a échoué, soit un conflit. Vérifie git status et les hooks."
        exit 1
    }
    echo "[OK] Commit créé : ${COMMIT_MSG}"
    echo "-----------------------------------------------"

    ############################################
    # 7) Tag et push vers GitHub
    ############################################

    TAG="v${NEW_VERSION}"

    echo
    echo "### Création du tag ${TAG}"
    echo "-----------------------------------------------"
    git tag -a "${TAG}" -m "MCGT ${NEW_VERSION}" || {
        echo
        echo "⚠ Impossible de créer le tag ${TAG}."
        echo "  → Vérifie si le tag existe déjà (git tag)."
        exit 1
    }
    echo "[OK] Tag créé : ${TAG}"
    echo "-----------------------------------------------"

    echo
    echo "### Push vers origin (branche principale + tag)"
    echo "-----------------------------------------------"
    # Si ta branche principale n'est pas 'main', adapte ci-dessous.
    git push origin main || {
        echo
        echo "⚠ Échec du push sur origin main."
        echo "  → Vérifie ta connexion ou la configuration du remote."
        exit 1
    }

    git push origin "${TAG}" || {
        echo
        echo "⚠ Échec du push du tag ${TAG}."
        echo "  → Vérifie ta connexion ou la configuration du remote."
        exit 1
    }
    echo "[OK] Push main + tag ${TAG} effectué."
    echo "-----------------------------------------------"

    echo
    echo "### Rappel post-release"
    echo " - Vérifie la Release GitHub associée à ${TAG}."
    echo " - Vérifie sur Zenodo que la nouvelle version a bien été enregistrée"
    echo "   (nouveau record lié au concept DOI existant)."
    echo " - Si tu maintiens CITATION.cff / .zenodo.json avec le numéro de version,"
    echo "   pense à les mettre à jour également à ${NEW_VERSION}."
    echo
}

main

#!/usr/bin/env bash
# File: stepZ_publish_github_release_guard.sh
set -Euo pipefail
trap 'st=$?; echo; echo "[HOLD] Terminé (code=$st)."; read -rp "Entrée pour revenir au shell... " _' EXIT

VERSION="${VERSION:-v0.3.x}"
TAG="${VERSION}"
TITLE="MCGT ${VERSION}"
NOTES_FILE="$(ls -1 _logs/RELEASE_NOTES_${VERSION}_*.txt 2>/dev/null | tail -n1 || true)"
ARCHIVE="$(ls -1 release_zenodo_codeonly_${VERSION}_*.tar.gz 2>/dev/null | tail -n1 || true)"
SHAFILE="release_zenodo_codeonly/${VERSION}/SHA256SUMS.txt"

echo "[INFO] Tag=${TAG}"
[[ -n "${NOTES_FILE}" ]] || { echo "[ERR] Notes introuvables (_logs/RELEASE_NOTES_${VERSION}_*.txt)."; exit 2; }
[[ -f "${SHAFILE}" ]] || { echo "[ERR] ${SHAFILE} introuvable."; exit 3; }
[[ -n "${ARCHIVE}" && -f "${ARCHIVE}" ]] || { echo "[ERR] Archive .tar.gz introuvable."; exit 4; }

if command -v gh >/dev/null 2>&1; then
  echo "[INFO] gh détecté. Publication/MAJ de la Release…"
  # Crée ou met à jour la release
  if gh release view "${TAG}" >/dev/null 2>&1; then
    gh release edit "${TAG}" --title "${TITLE}" --notes-file "${NOTES_FILE}"
  else
    gh release create "${TAG}" --title "${TITLE}" --notes-file "${NOTES_FILE}"
  fi

  # Attache/maj assets (idempotent : --clobber remplace)
  gh release upload "${TAG}" "${ARCHIVE}" --clobber
  gh release upload "${TAG}" "${SHAFILE}" --clobber

  echo "[OK] Release GitHub ${TAG} publiée/mise à jour avec assets."
else
  echo "[WARN] 'gh' indisponible."
  echo "    1) Crée la release manuellement : https://github.com/JeanPhilipLalumiere/MCGT/releases/new"
  echo "    2) Tag : ${TAG} | Titre : ${TITLE}"
  echo "    3) Description : contenu de ${NOTES_FILE}"
  echo "    4) Joins les fichiers :"
  echo "       - ${ARCHIVE}"
  echo "       - ${SHAFILE}"
fi

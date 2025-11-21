#!/usr/bin/env bash
set -Eeuo pipefail
IFS=$'\n\t'

echo "== Twine Upload (simple) =="

# Dist files (args override default)
if [[ $# -ge 1 ]]; then
  dists=("$@")
else
  shopt -s nullglob
  dists=(dist/*.whl dist/*.tar.gz dist/*.zip)
  shopt -u nullglob
fi

((${#dists[@]})) || { echo "[ERR ] Aucun fichier dans ./dist — quitte."; exit 1; }

# Show env
echo "[INFO] TWINE_REPOSITORY=${TWINE_REPOSITORY-pypi}"
echo "[INFO] TWINE_REPOSITORY_URL=${TWINE_REPOSITORY_URL-<vide>}"
echo "[INFO] TWINE_USERNAME=${TWINE_USERNAME-<non défini>}"
if [[ -z "${TWINE_PASSWORD-}" ]]; then
  echo "[ERR ] TWINE_PASSWORD non défini — exporte 'pypi-...' et relance."; exit 1;
fi

echo "[INFO] twine check ..."
twine check "${dists[@]}"

echo "[INFO] Upload ..."
# Si TWINE_REPOSITORY_URL est défini, Twine l'utilisera. Sinon TWINE_REPOSITORY (pypi/testpypi).
twine upload "${dists[@]}" --verbose

echo "[OK] Upload terminé."

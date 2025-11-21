#!/usr/bin/env bash
set -Eeuo pipefail

# ==== Paramètres à ajuster si besoin ====
VERSION="0.3.2"   # version stable telle qu'écrite dans ./pyproject.toml

cd ~/MCGT

echo "########## RELEASE ZZ-TOOLS vers PyPI ##########"
echo "[INFO] Branche et statut git :"
git status -sb || true
echo

echo "==== 0) Vérification rapide de la version dans ./pyproject.toml ===="
grep -n 'version *= ' ./pyproject.toml || {
  echo "[ERREUR] Impossible de trouver 'version = ' dans ./pyproject.toml"
  exit 1
}
echo

echo "==== 1) diag_consistency sur ./zz-manifests/manifest_publication.json (strict) ===="
PAUSE_ON_EXIT=0 python ./zz-manifests/diag_consistency.py \
  --repo-root "$PWD" \
  --normalize-paths \
  --apply-aliases \
  --content-check \
  --report text \
  --fail-on errors \
  ./zz-manifests/manifest_publication.json
echo

echo "==== 2) diag_consistency sur ./zz-manifests/manifest_master.json (fail-on none) ===="
PAUSE_ON_EXIT=0 python ./zz-manifests/diag_consistency.py \
  --repo-root "$PWD" \
  --normalize-paths \
  --apply-aliases \
  --content-check \
  --report text \
  --fail-on none \
  ./zz-manifests/manifest_master.json
echo

echo "==== 3) pytest ./zz-tests ===="
PAUSE_ON_EXIT=0 python -m pytest ./zz-tests
echo

echo "==== 4) Nettoyage dist/build/egg-info ===="
rm -rf ./dist/ ./build/ ./zz_tools.egg-info
echo "OK."
echo

echo "==== 5) Build sdist + wheel ===="
python -m build
echo

echo "==== 6) Contenu de ./dist/ ===="
ls -l ./dist/
echo

echo "==== 7) twine check (sécurité) ===="
python -m twine check ./dist/zz_tools-${VERSION}-py3-none-any.whl ./dist/zz_tools-${VERSION}.tar.gz
echo

echo "==== 8) CONFIRMATION avant upload vers PyPI (PROD) ===="
echo "On va uploader les fichiers suivants vers PyPI :"
echo "  - ./dist/zz_tools-${VERSION}-py3-none-any.whl"
echo "  - ./dist/zz_tools-${VERSION}.tar.gz"
echo
read -rp "OK pour uploader vers PyPI (https://upload.pypi.org/legacy/) ? [Entrée pour continuer / Ctrl-C pour annuler] " _dummy

echo "==== 9) Upload vers PyPI (PROD) ===="
python -m twine upload \
  --repository-url https://upload.pypi.org/legacy/ \
  ./dist/zz_tools-${VERSION}-py3-none-any.whl \
  ./dist/zz_tools-${VERSION}.tar.gz

echo
echo "########## RELEASE PYPI TERMINÉE ##########"
echo "Tu peux vérifier sur : https://pypi.org/project/zz-tools/${VERSION}/"

#!/usr/bin/env bash
set -Eeuo pipefail

REPO="${1:-$(pwd)}"
cd "$REPO"

echo "==> Repo: $REPO"

if [ ! -f pyproject.toml ]; then
  echo "pyproject.toml introuvable dans $REPO" >&2
  exit 2
fi

# Backup
BKP="pyproject.toml.spdxbak.$(date +%s)"
cp pyproject.toml "$BKP"
echo "Backup -> $BKP"

# 1) Normaliser la licence: table -> chaîne SPDX, et ajouter license-files
# Remplace toute table { ... } après 'license =' par une simple chaîne "MIT"
if grep -qE '^[[:space:]]*license[[:space:]]*=[[:space:]]*\{.*\}' pyproject.toml; then
  sed -i -E 's/^[[:space:]]*license[[:space:]]*=[[:space:]]*\{[^}]*\}/license = "MIT"/' pyproject.toml
fi

# Si aucune ligne license n'existe sous [project], insère-la après l'en-tête
if ! grep -qE '^[[:space:]]*license[[:space:]]*=' pyproject.toml; then
  awk '
    BEGIN{printed=0}
    /^\[project\]/{print; print "license = \"MIT\""; printed=1; next}
    {print}
    END{ if(printed==0) print "license = \"MIT\"" }
  ' pyproject.toml > pyproject.toml.tmp && mv pyproject.toml.tmp pyproject.toml
fi

# Ajouter license-files si absent
if ! grep -qE '^[[:space:]]*license-files[[:space:]]*=' pyproject.toml; then
  sed -i -E '/^[[:space:]]*license[[:space:]]*=/a license-files = ["LICENSE", "LICENSE-data"]' pyproject.toml
fi

# Retirer "license" et "license-file" de project.dynamic s'ils s'y trouvent
# (garde la ligne, mais nettoie la liste)
if grep -qE '^[[:space:]]*dynamic[[:space:]]*=\s*\[.*\]' pyproject.toml; then
  sed -i -E 's/"license-file"\s*,?\s*//g; s/,?\s*"license-file"//g; s/"license"\s*,?\s*//g; s/,?\s*"license"//g' pyproject.toml
  # Nettoyage des virgules orphelines dans []
  sed -i -E 's/\[\s*,/\[/g; s/,\s*\]/]/g' pyproject.toml
fi

echo "pyproject.toml patché pour SPDX + license-files."

# 2) Rebuild sdist + wheel
python3 -V
python -m pip -q install -U build twine >/dev/null
python -m build --sdist --wheel

SDIST="$(ls -1t dist/*.tar.gz | head -n1)"
WHEEL="$(ls -1t dist/*.whl | head -n1)"
echo "sdist: $SDIST"
echo "wheel: $WHEEL"

# 3) Inspecter PKG-INFO (sdist)
echo -e "\n=== Inspect PKG-INFO (head) ==="
tar -xOf "$SDIST" */PKG-INFO | sed -n '1,40p'

# 4) Twine check
echo -e "\n=== Run twine check ==="
python -m twine check "$SDIST" "$WHEEL"

echo -e "\nOK: twine check passé. Pour valider l’install:\n  python -m venv .venv-test && . .venv-test/bin/activate && pip install \"$SDIST\" && python -c 'import zz_tools, sys; print(\"zz_tools OK\", sys.version)'"
echo -e "\nPense à committer:\n  git add pyproject.toml && git -c commit.gpgsign=false commit -m \"build(meta): SPDX license string + license-files\""

#!/usr/bin/env bash
# Tolérant : on ne quitte jamais sur erreur, logs clairs
set -uo pipefail
set -o errtrace

STATUS=0
declare -a ERRORS=()
ts(){ date +"%Y-%m-%d %H:%M:%S"; }
say(){ echo -e "[$(ts)] $*"; }
run(){ say "▶ $*"; eval "$@" || { c=$?; say "❌ Échec (code=$c): $*"; ERRORS+=("$* [code=$c]"); STATUS=1; }; }
step(){ echo; say "────────────────────────────────────────────────────────"; say "🚩 $*"; say "────────────────────────────────────────────────────────"; }
trap 'say "⚠️  Erreur interceptée (on continue)"; STATUS=1' ERR

step "0) Préparation"
run "mkdir -p tools .github/workflows"

###############################################################################
# 1) utilitaire ensure_pyproject.py : crée/complète pyproject.toml (PEP 621)
###############################################################################
step "1) Générer tools/ensure_pyproject.py (complétion non invasive)"
cat > tools/ensure_pyproject.py <<'PY'
#!/usr/bin/env python3
import sys, re, json
from pathlib import Path

root = Path(__file__).resolve().parents[1]
ppy = root / "pyproject.toml"
backup = root / "pyproject.toml.before_series9.bak"

def read_text(p: Path) -> str:
    try: return p.read_text(encoding="utf-8")
    except FileNotFoundError: return ""

def write_text(p: Path, s: str):
    p.write_text(s, encoding="utf-8")

content = read_text(ppy)
original = content

def ensure_block(s: str, header: str, body_lines: list[str]) -> str:
    if re.search(rf'^\s*\[{re.escape(header)}\]\s*$', s, flags=re.M):
        return s
    addition = "\n\n[" + header + "]\n" + "\n".join(body_lines) + "\n"
    return s + addition

if not content:
    content = """# pyproject généré par Série 9 (idempotent)
[build-system]
requires = ["hatchling>=1.23"]
build-backend = "hatchling.build"

[project]
name = "mcgt"
version = "0.0.0"
description = "MCGT: outils et données (builds, figures, CI)."
readme = "README.md"
requires-python = ">=3.10"
authors = [{name="MCGT maintainers"}]
license = {text = "MIT"}
dependencies = []

[project.urls]
Homepage = "https://github.com/JeanPhilipLalumiere/MCGT"
Repository = "https://github.com/JeanPhilipLalumiere/MCGT"
"""
else:
    # S'assurer d'un build-system présent
    if not re.search(r'^\s*\[build-system\]\s*$', content, flags=re.M):
        content += """
[build-system]
requires = ["hatchling>=1.23"]
build-backend = "hatchling.build"
"""
    # S'assurer que [project] existe
    if not re.search(r'^\s*\[project\]\s*$', content, flags=re.M):
        content += """
[project]
name = "mcgt"
version = "0.0.0"
description = "MCGT package"
readme = "README.md"
requires-python = ">=3.10"
authors = [{name="MCGT maintainers"}]
license = {text = "MIT"}
dependencies = []
"""
    # Ajouter quelques URLs si absentes (non intrusif)
    content = ensure_block(content, "project.urls", [
        'Homepage = "https://github.com/JeanPhilipLalumiere/MCGT"',
        'Repository = "https://github.com/JeanPhilipLalumiere/MCGT"',
    ])

# S’assurer d’un layout acceptable (src/ ou paquet plat) via hatchling include
if "[tool.hatch.build]" not in content:
    content += """
[tool.hatch.build]
include = [
  "/**/*.py",
  "/zz-data/**/*",
  "/zz-figures/**/*",
  "/README.md",
  "/LICENSE*",
]
exclude = [
  "/.ci-logs/**/*",
  "/.ci-out/**/*",
  "/_tmp-figs/**/*",
  "/zz-out/**/*",
  "/.github/**/*",
]
"""

# Éviter d’écraser silencieusement
if original != content:
    if original:
        backup.write_text(original, encoding="utf-8")
    write_text(ppy, content)
    print("UPDATED: pyproject.toml (backup: pyproject.toml.before_series9.bak)")
else:
    print("OK: pyproject.toml déjà conforme")
PY
run "chmod +x tools/ensure_pyproject.py"
run "python3 tools/ensure_pyproject.py || true"

###############################################################################
# 2) Makefile : cibles build Python (sdist/wheel), check, clean
###############################################################################
step "2) Makefile : targets build/dist"
if ! grep -q '^# BEGIN PY DIST TARGETS$' Makefile 2>/dev/null; then
  cat >> Makefile <<'MK'

# BEGIN PY DIST TARGETS
.PHONY: dist clean-dist twine-check
dist:
	@python -m pip install -U build twine >/dev/null
	@python -m build
twine-check:
	@python -m pip install -U twine >/dev/null
	@python -m twine check dist/*
clean-dist:
	@rm -rf dist build *.egg-info || true
# END PY DIST TARGETS
MK
fi

###############################################################################
# 3) Workflow CI : build sdist/wheel sur push/PR + artefacts
###############################################################################
step "3) Workflow CI build paquet (artefacts)"
cat > .github/workflows/pypi-build.yml <<'YML'
name: pypi-build
on:
  push:
    branches: ["**"]
  pull_request:
    branches: ["**"]

permissions:
  contents: read

jobs:
  build:
    runs-on: ubuntu-latest
    timeout-minutes: 20
    steps:
      - uses: actions/checkout@v4
        with: { fetch-depth: 0 }

      - uses: actions/setup-python@v5
        with:
          python-version: "3.12"
          cache: "pip"

      - name: Build sdist/wheel
        run: |
          python -m pip install -U pip build twine
          python -m build
          python -m twine check dist/*

      - name: Upload dist artifacts
        uses: actions/upload-artifact@v4
        with:
          name: py-dist
          path: dist/*
YML

###############################################################################
# 4) Workflow publication TestPyPI/PyPI sur tag v* (seulement si secrets présents)
###############################################################################
step "4) Workflow publication sur tag (TestPyPI/PyPI si secrets)"
cat > .github/workflows/pypi-publish.yml <<'YML'
name: pypi-publish
on:
  push:
    tags:
      - "v*"

permissions:
  contents: read
  id-token: write

jobs:
  build-and-publish:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
        with: { fetch-depth: 0 }
      - uses: actions/setup-python@v5
        with:
          python-version: "3.12"
          cache: "pip"
      - name: Build
        run: |
          python -m pip install -U pip build twine
          python -m build
          python -m twine check dist/*
      - name: Publish to TestPyPI (si token dispo)
        if: ${{ secrets.TEST_PYPI_API_TOKEN != '' }}
        uses: pypa/gh-action-pypi-publish@release/v1
        with:
          repository-url: https://test.pypi.org/legacy/
          password: ${{ secrets.TEST_PYPI_API_TOKEN }}
          skip-existing: true
      - name: Publish to PyPI (si token dispo)
        if: ${{ secrets.PYPI_API_TOKEN != '' }}
        uses: pypa/gh-action-pypi-publish@release/v1
        with:
          password: ${{ secrets.PYPI_API_TOKEN }}
          skip-existing: true
YML

###############################################################################
# 5) .gitignore : ignorer dist/, build/ et *.egg-info
###############################################################################
step "5) .gitignore : dist/ build/ *.egg-info"
add_ignore() {
  line="$1"
  grep -qxF "$line" .gitignore 2>/dev/null || echo "$line" >> .gitignore
}
add_ignore "dist/"
add_ignore "build/"
add_ignore "*.egg-info/"

###############################################################################
# 6) Commit + push (jamais bloquant)
###############################################################################
step "6) Commit + push"
run "git add pyproject.toml Makefile .gitignore .github/workflows/pypi-build.yml .github/workflows/pypi-publish.yml tools/ensure_pyproject.py || true"
run "git commit -m 'build(py): pyproject PEP 621/hatchling; cibles Makefile dist; CI build artefacts; publish TestPyPI/PyPI sur tags' || true"
run "pre-commit install || true"
run "git push || true"

echo
say "RÉCAPITULATIF :"
if [ ${#ERRORS[@]} -gt 0 ]; then
  say "Certaines étapes ont échoué mais l’exécution a continué :"
  for e in "${ERRORS[@]}"; do say "  - $e"; done
  say "→ Envoie-moi la fin du log pour patch ciblé."
else
  say "✅ Série 9 appliquée : build Python prêt (sdist/wheel + artefacts CI)."
  say "   Publication sur tag v* si secrets TEST_PYPI_API_TOKEN / PYPI_API_TOKEN sont configurés."
fi

echo
read -rp $'Appuyez sur Entrée pour terminer (fenêtre maintenue ouverte)…'
exit 0

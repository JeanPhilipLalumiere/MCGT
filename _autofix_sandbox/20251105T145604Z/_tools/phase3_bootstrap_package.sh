#!/usr/bin/env bash
# Pas de -e: on corrige au mieux, on log, on continue.
set -u
ROOT="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
cd "$ROOT" || exit 1
TS="$(date -u +%Y%m%dT%H%M%SZ)"
REPORTS="_reports/${TS}"; mkdir -p "$REPORTS"
log(){ printf "%s\n" "$*" | tee -a "${REPORTS}/phase3_bootstrap_package.log"; }

log "==[0] Contexte =="
python -V 2>&1 | tee -a "${REPORTS}/python.txt"

# 0bis) Déps build
python -m PIP_CONSTRAINT=constraints/security-pins.txt PIP_CONSTRAINT=constraints/security-pins.txt pip install -q --upgrade pip >/dev/null 2>&1 || true
python -m PIP_CONSTRAINT=constraints/security-pins.txt PIP_CONSTRAINT=constraints/security-pins.txt pip install -q build twine >/dev/null 2>&1 || true

# 1) pyproject.toml (PEP 621 + setuptools, version dynamique depuis mcgt.__version__)
python - <<'PY'
from pathlib import Path
import re, sys, json

root = Path(".")
pkg_dir = root/"mcgt"
if not pkg_dir.exists():
    print("ABORT: dossier 'mcgt/' introuvable — packaging sauté.")
    sys.exit(0)

readme = "README.md" if (root/"README.md").exists() else None

py = root/"pyproject.toml"
content = []
content.append("[build-system]")
content.append('requires = ["setuptools>=68", "wheel"]')
content.append('build-backend = "setuptools.build_meta"')
content.append("")
content.append("[project]")
content.append('name = "mcgt"')
content.append('description = "MCGT core package"')
if readme:
    content.append('readme = "README.md"')
content.append('requires-python = ">=3.10"')
content.append('authors = [{name="Jean-Philip Lalumiere"}]')
content.append('keywords = ["mcgt", "cosmo", "analysis"]')
content.append('classifiers = [')
content.append('  "Programming Language :: Python :: 3",')
content.append('  "License :: OSI Approved :: MIT License",')
content.append('  "Operating System :: OS Independent",')
content.append("]")
content.append('dependencies = []')
content.append('dynamic = ["version"]')
content.append("")
content.append("[project.optional-dependencies]")
content.append('dev = ["pytest", "pytest-cov", "ruff", "pre-commit"]')
content.append('viz = ["pandas", "matplotlib"]')
content.append("")
content.append("[project.scripts]")
content.append('mcgt = "mcgt.__main__:main"')
content.append("")
content.append("[tool.setuptools]")
content.append('include-package-data = true')
content.append("")
content.append("[tool.setuptools.packages.find]")
content.append('include = ["mcgt*"]')
content.append('namespaces = false')
content.append("")
content.append("[tool.setuptools.dynamic]")
content.append('version = {attr = "mcgt.__version__"}')
content.append("")

txt = "\n".join(content) + "\n"
if py.exists():
    old = py.read_text(encoding="utf-8")
    if old == txt:
        print("pyproject.toml inchangé")
    else:
        py.write_text(txt, encoding="utf-8")
        print("pyproject.toml écrit/mis à jour")
else:
    py.write_text(txt, encoding="utf-8")
    print("pyproject.toml créé")
PY

# 2) __main__.py minimal (CLI) — idempotent
python - <<'PY'
from pathlib import Path
p = Path("mcgt/__main__.py")
if not p.exists():
    p.parent.mkdir(parents=True, exist_ok=True)
    p.write_text(
        """# mcgt.__main__ — minimal CLI
from __future__ import annotations

import argparse
import sys

def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(prog="mcgt", description="MCGT CLI")
    parser.add_argument("--version", action="store_true", help="print version and exit")
    parser.add_argument("--summary", action="store_true", help="print debug summary")
    args = parser.parse_args(argv)
    if args.version:
        try:
            from . import __version__
            print(__version__)
        except Exception:
            print("unknown")
        return 0
    if args.summary:
        try:
            from . import print_summary
            print_summary()
        except Exception as e:
            print(f"summary unavailable: {e}")
        return 0
    parser.print_help()
    return 0

if __name__ == "__main__":
    raise SystemExit(main())
""",
        encoding="utf-8",
    )
    print("mcgt/__main__.py créé")
else:
    print("mcgt/__main__.py présent (ok)")
PY

# 3) __init__.py — s’assurer que __version__ existe
python - <<'PY'
from pathlib import Path, re
p = Path("mcgt/__init__.py")
if not p.exists():
    print("WARN: mcgt/__init__.py manquant — création minimaliste")
    p.write_text('__version__ = "0.0.0.dev0"\n', encoding="utf-8")
else:
    s = p.read_text(encoding="utf-8")
    if re.search(r"__version__\s*=", s) is None:
        s += '\n__version__ = "0.0.0.dev0"\n'
        p.write_text(s, encoding="utf-8")
        print("__version__ ajouté dans mcgt/__init__.py")
    else:
        print("__version__ déjà présent (ok)")
PY

# 4) .gitignore — ignorer artefacts build
touch .gitignore
grep -qxF "dist/" .gitignore || echo "dist/" >> .gitignore
grep -qxF "build/" .gitignore || echo "build/" >> .gitignore
grep -qxF "*.egg-info/" .gitignore || echo "*.egg-info/" >> .gitignore
grep -qxF "coverage.xml" .gitignore || echo "coverage.xml" >> .gitignore

# 5) Build sdist+wheel + vérif twine
log "==[build] python -m build =="
python -m build 2>&1 | tee -a "${REPORTS}/build.txt"
log "==[twine check]=="
python -m twine check dist/* 2>&1 | tee -a "${REPORTS}/twine_check.txt" || true

# 6) Smoke test dans un venv éphémère
log "==[smoke] import & CLI=="
rm -rf .venv-mcgt-wheel 2>/dev/null || true
python -m venv .venv-mcgt-wheel
. .venv-mcgt-wheel/bin/activate
python -m PIP_CONSTRAINT=constraints/security-pins.txt PIP_CONSTRAINT=constraints/security-pins.txt pip install -q --upgrade pip >/dev/null 2>&1 || true
python -m PIP_CONSTRAINT=constraints/security-pins.txt PIP_CONSTRAINT=constraints/security-pins.txt pip install dist/*.whl 2>&1 | tee -a "${REPORTS}/install_wheel.txt"
python - <<'PY' 2>&1 | tee -a "${REPORTS}/smoke.txt"
import mcgt, subprocess, sys
print("import mcgt OK; __version__ =", getattr(mcgt, "__version__", "n/a"))
# test CLI
out = subprocess.check_output([sys.executable, "-m", "mcgt", "--version"]).decode().strip()
print("python -m mcgt --version ->", out)
PY
deactivate

# 7) CI build-package (workflow simple, artefacts attachés)
mkdir -p .github/workflows
cat > .github/workflows/build-package.yml <<'YML'
name: Build package
on:
  push:
  workflow_dispatch:
jobs:
  build:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-python@v5
        with: { python-version: '3.12' }
      - run: python -m PIP_CONSTRAINT=constraints/security-pins.txt PIP_CONSTRAINT=constraints/security-pins.txt pip install --upgrade pip build twine
      - run: python -m build
      - run: python -m twine check dist/*
      - uses: actions/upload-artifact@v4
        with:
          name: dist-${{ github.sha }}
          path: dist/
YML

# 8) pre-commit + commit/push
pre-commit run --all-files || true
git add pyproject.toml mcgt/__main__.py mcgt/__init__.py .gitignore .github/workflows/build-package.yml
git commit -m "build(phase3): PEP621 packaging, CLI entrypoint, wheel build & CI workflow" || true
git push -u origin "$(git rev-parse --abbrev-ref HEAD)" || true

log ">>> Phase 3 bootstrap terminé. Artefacts: dist/, Rapports: ${REPORTS}"

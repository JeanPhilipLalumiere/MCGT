#!/usr/bin/env bash
set -u
ROOT="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
cd "$ROOT"
TS="$(date -u +%Y%m%dT%H%M%SZ)"
REPORTS="_reports/${TS}"; mkdir -p "$REPORTS"
log(){ printf "%s\n" "$*" | tee -a "${REPORTS}/phase2_finish.log"; }

log "==[0] Contexte =="
python -V 2>&1 | tee -a "${REPORTS}/python.txt"
ruff --version 2>/dev/null | tee -a "${REPORTS}/ruff.txt" || true
pytest --version 2>/dev/null | tee -a "${REPORTS}/pytest.txt" || true

log "==[1] Déps tests (idempotent) =="
python -m PIP_CONSTRAINT=constraints/security-pins.txt PIP_CONSTRAINT=constraints/security-pins.txt pip install -q pytest pytest-cov >/dev/null 2>&1 || true

log "==[2] Patch pytest.ini (couverture + découverte tests) =="
python - <<'PY'
from pathlib import Path
p = Path("pytest.ini")
txt = p.read_text(encoding="utf-8") if p.exists() else "[pytest]\naddopts = -q\n"
# addopts
if "addopts" not in txt:
    txt += "\naddopts = -q\n"
if "--cov=" not in txt:
    txt = txt.replace(
        "addopts =",
        "addopts = --cov=mcgt --cov-report=term-missing:skip-covered --cov-report=xml:coverage.xml"
    )
# testpaths
if "testpaths" not in txt:
    txt += "\ntestpaths =\n    tests\n    zz-scripts/chapter10/tests\n"
else:
    if "tests" not in txt:
        txt = txt.replace("testpaths =", "testpaths =\n    tests")
    if "zz-scripts/chapter10/tests" not in txt:
        txt = txt.replace("testpaths =", "testpaths =\n    zz-scripts/chapter10/tests")
p.write_text(txt, encoding="utf-8")
print("pytest.ini updated")
PY

log "==[3] Badge CI (branche courante) =="
BRANCH="$(git rev-parse --abbrev-ref HEAD)"
REMOTE_URL="$(git config --get remote.origin.url | sed -E 's#^(git@|https://)github.com[:/](.*)\.git$#\2#')"
BADGE="[![CI](https://github.com/${REMOTE_URL}/actions/workflows/ci.yml/badge.svg?branch=${BRANCH})](https://github.com/${REMOTE_URL}/actions/workflows/ci.yml?query=branch%3A${BRANCH})"
[ -f README.md ] || echo "# MCGT" > README.md
grep -q "actions/workflows/ci.yml/badge.svg" README.md || sed -i "1i ${BADGE}\n" README.md

log "==[4] pre-commit (x2) + pytest local (avec couverture) =="
pre-commit run --all-files || true
pre-commit run --all-files || true
pytest -q || true
[ -f coverage.xml ] && cp coverage.xml "${REPORTS}/" || true

log "==[5] Commit/push si diff =="
git add README.md pytest.ini requirements-test.txt 2>/dev/null || true
git commit -m "ci(phase2): finalize — coverage + badge + tests discovery" 2>/dev/null || true
git push -u origin "$(git rev-parse --abbrev-ref HEAD)" 2>/dev/null || true

log "==[6] Récapitulatif =="
git status --porcelain | tee -a "${REPORTS}/git_status.txt"
echo "Reports -> ${REPORTS}"

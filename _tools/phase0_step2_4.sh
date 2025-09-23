#!/usr/bin/env bash
set -euo pipefail

# Toujours repartir de la racine du repo
cd "$(git rev-parse --show-toplevel)"

TS="$(date -u +%Y%m%dT%H%M%SZ)"
REPORTS="_reports/${TS}"
mkdir -p "${REPORTS}"

echo "==[0] Contexte machine ==" | tee "${REPORTS}/machine.txt"
{
  echo "whoami: $(whoami)"
  echo "cwd    : $(pwd)"
  echo -n "kernel : "; uname -a
  echo -n "python : "; python3 --version 2>/dev/null || echo "n/a"
  echo -n "pip    : "; pip --version 2>/dev/null || echo "n/a"
} >> "${REPORTS}/machine.txt" 2>&1

echo "==[1] État Git avant actions =="
git status --porcelain=v1 -uno > "${REPORTS}/git_status_before.txt" || true
git rev-parse --abbrev-ref HEAD > "${REPORTS}/current_branch.txt" || true
git fetch origin --prune --tags >/dev/null 2>&1 || true
git diff --no-color origin/main... > "${REPORTS}/diff_vs_origin_before.patch" || true
git diff --name-status origin/main... > "${REPORTS}/diff_names_vs_origin_before.txt" || true

echo "==[2] pre-commit =="
if ! command -v pre-commit >/dev/null 2>&1; then
  python3 -m pip install --upgrade pip pre-commit |& tee "${REPORTS}/precommit_pip_install.txt"
fi
pre-commit install -f |& tee "${REPORTS}/precommit_install.txt"
# On ne fail pas la CI locale si un hook échoue : on capture et on continue
pre-commit run --all-files |& tee "${REPORTS}/precommit_run.txt" || true

echo "==[3] Validate (JSON/CSV/diag) =="
if [ -f Makefile ]; then
  ( make validate ) |& tee "${REPORTS}/make_validate.txt" || true
else
  (
    ./zz-schemas/validate_all.sh
    ./zz-schemas/validate_csv_all.sh
    python3 zz-manifests/diag_consistency.py zz-manifests/manifest_master.json --report json --fail-on errors
  ) |& tee "${REPORTS}/make_validate.txt" || true
fi

echo "==[4] Diffstat et patch du worktree =="
git diff --stat origin/main... > "${REPORTS}/diffstat_vs_origin.txt" || true
git diff --no-color > "${REPORTS}/diff_worktree.patch" || true

echo "==[5] Stash & résumé =="
{
  echo "Branche active : $(git rev-parse --abbrev-ref HEAD)"
  echo "Stash (top 10) :"
  git stash list | head -n 10
  echo "Rapports       : ${REPORTS}"
} | tee "${REPORTS}/summary.txt"

echo
echo ">>> Phase 0 — Étapes 2→4 TERMINÉES. Rapports : ${REPORTS}"

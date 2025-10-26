#!/usr/bin/env bash
# tools/scan_pypi_safely.sh
# Scanne l’arbre de travail et l’historique pour des chaînes de type “pypi-…”
# Non destructif, never-fail.

set -u
mkdir -p _tmp

PATTERN='pypi-[-A-Za-z0-9_=]{50,}'

echo "[INFO] Scan arbre de travail…"
git grep -nE "${PATTERN}" -- . ':!*.png' ':!*.jpg' ':!*.jpeg' ':!*.gif' \
  > _tmp/scan_pypi_worktree.txt || true
echo "[OK] -> _tmp/scan_pypi_worktree.txt"

echo "[INFO] Scan historique (tous commits)…"
# Utilise -P pour paralléliser le xargs si dispo
git rev-list --all | xargs -n1 -P4 git grep -nE "${PATTERN}" \
  > _tmp/scan_pypi_history.txt || true
echo "[OK] -> _tmp/scan_pypi_history.txt"

echo
echo "──────── Résumé scan PyPI ────────"
echo "Worktree : $(wc -l < _tmp/scan_pypi_worktree.txt) matches"
echo "History  : $(wc -l < _tmp/scan_pypi_history.txt) matches"
echo "Fichiers :"
echo "  _tmp/scan_pypi_worktree.txt"
echo "  _tmp/scan_pypi_history.txt"

#!/usr/bin/env bash
set -euo pipefail

# === PSX: empêcher la fermeture auto (hors CI) ===
WAIT_ON_EXIT="${WAIT_ON_EXIT:-1}"
psx_pause() {
  rc=$?
  echo
  if [[ $rc -eq 0 ]]; then
    echo "✅ Étape 2 — Terminé avec exit code: $rc"
  else
    echo "❌ Étape 2 — Terminé avec exit code: $rc"
  fi
  if [[ "${WAIT_ON_EXIT}" == "1" && -t 1 && -z "${CI:-}" ]]; then
    read -r -p "PSX — Appuie sur Entrée pour fermer cette fenêtre…" _
  fi
}
trap 'psx_pause' EXIT
# ================================================

cd "$(git rev-parse --show-toplevel)"

echo "==> (0) Auto-réparation des bits exécutables (ce script inclus)"
if [[ ! -x "$0" ]]; then
  chmod +x "$0"
  git add --chmod=+x "$0" || git add "$0"
fi

echo "==> (1) Sauvegarde pyproject.toml puis retrait de select=['I'] (si présent)"
ts="$(date -u +%Y%m%dT%H%M%SZ)"
cp -f pyproject.toml "pyproject.toml.before_restore_ruff_${ts}" || true
python3 - <<'PY'
import re, pathlib
p = pathlib.Path("pyproject.toml")
s = p.read_text(encoding="utf-8")
select_i_re = re.compile(r'^\s*select\s*=\s*\[\s*["\']I["\']\s*\]\s*(#.*)?$', re.M)
new = select_i_re.sub("", s)
if new != s:
    p.write_text(new, encoding="utf-8"); print("pyproject.toml: rattrapage (suppression select=['I']).")
else:
    print("pyproject.toml: rien à changer.")
PY

echo "==> (2) Ruff check --fix (compat 0.13.x) — on exclut .ci-archive"
ruff --version || true
ruff check --fix --unsafe-fixes --exclude '.ci-archive' .

echo "==> (3) Pré-commit (tolérant, 2 passes)"
pre-commit install || true
pre-commit run --all-files || true
pre-commit run --all-files || true

echo "==> (4) Commit/push si diff"
git add -A
if ! git diff --staged --quiet; then
  git commit -m "style: restore full Ruff config and apply formatting"
  git push
else
  echo "Aucun changement à committer."
fi

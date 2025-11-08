#!/usr/bin/env bash
set -euo pipefail
KEEP_OPEN="${KEEP_OPEN:-1}"
stay_open(){ rc=$?; echo; echo "[unskip-diag] Script terminé avec exit code: $rc"; if [[ "$KEEP_OPEN" == "1" && -t 1 && -z "${CI:-}" ]]; then echo "[unskip-diag] Appuie sur Entrée pour quitter…"; read -r _; fi; }
trap 'stay_open' EXIT

cd "$(git rev-parse --show-toplevel)"
f="zz-tests/test_schemas.py"
[[ -f "$f" ]] || { echo "Fichier introuvable: $f"; exit 1; }

# Supprime le décorateur xfail ajouté précédemment
python - <<'PY'
from pathlib import Path, re
p = Path("zz-tests/test_schemas.py")
t = p.read_text(encoding="utf-8")
orig = t
t = re.sub(r'^\s*@pytest\.mark\.xfail\([^\)]*\)\s*\n(?=\s*def\s+test_diag_master_no_errors_json_report\b)', '', t, flags=re.MULTILINE)
if t != orig:
    p.write_text(t, encoding="utf-8")
    print("[tests] xfail retiré")
else:
    print("[tests] pas de xfail à retirer")
PY

pre-commit run --files zz-tests/test_schemas.py || true
git add zz-tests/test_schemas.py
if ! git diff --cached --quiet; then
  git commit -m "tests: re-enable diag_consistency after manifest refresh"
  git push
else
  echo "Rien à committer"
fi

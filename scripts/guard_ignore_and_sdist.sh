#!/usr/bin/env bash
set -euo pipefail

echo "=== GUARD: tracked files ignored check ==="
TRACK_IGN_CNT=$(git ls-files -z | xargs -0 -I{} sh -c 'git check-ignore -q -- "{}" && echo "{}"' | wc -l | tr -d ' ')
echo "[tracked & ignored count] $TRACK_IGN_CNT"
if [ "$TRACK_IGN_CNT" -ne 0 ]; then
  echo "::error::Des fichiers SUIVIS seraient ignorés par .gitignore"
  git ls-files -z | xargs -0 -I{} sh -c 'git check-ignore -q -- "{}" && echo "::warning file={}::tracked & ignored"'
  exit 1
fi

echo
echo "=== GUARD: build sdist (python -m build --sdist) ==="
python -m pip -q install --upgrade pip >/dev/null
python -m pip -q install build >/dev/null
python -m build --sdist

SDIST="$(ls -1t dist/*.tar.gz | head -1)"
test -n "${SDIST:-}" || { echo "::error::Aucun sdist produit"; exit 1; }
echo "[sdist] $SDIST"

echo
echo "=== Inspect sdist content ==="
# Liste et contrôles “denylist” (régex simples)
python - <<'PY'
import tarfile, re, sys, os
sdist = os.environ.get("SDIST")
deny = [
    r'(^|/)\.venv', r'(^|/)venv', r'(^|/)_tmp', r'(^|/)zz-figures',
    r'(^|/)legacy-tex', r'\.pytest_cache/', r'\.ruff_cache/', r'\.mypy_cache/',
    r'\.ipynb_checkpoints/', r'\.(log|tmp|bak)(\.|$)', r'(^|/)_logs(/|$)',
    r'(^|/)dist(/|$)', r'(^|/)build(/|$)', r'\.tar\.gz$', r'\.whl$'
]
deny_re = [re.compile(p, re.I) for p in deny]
bad = []
with tarfile.open(sdist, "r:gz") as tf:
    members = tf.getnames()
    for m in members:
        path = m.lower()
        if any(rx.search(path) for rx in deny_re):
            bad.append(m)
    # Affiche un petit résumé
    print(f"[members] {len(members)} entries")
    print("sample:")
    for s in members[:15]: print("  -", s)
if bad:
    print("::error::Fichiers/chemins indésirables détectés dans le sdist:")
    for b in bad[:50]:
        print("  -", b)
    sys.exit(1)
else:
    print("[OK] Aucun chemin indésirable dans le sdist.")
PY
PY_EC=$?
exit $PY_EC

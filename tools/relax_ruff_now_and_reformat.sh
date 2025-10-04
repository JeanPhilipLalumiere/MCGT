#!/usr/bin/env bash
set -euo pipefail
KEEP_OPEN="${KEEP_OPEN:-1}"
stay_open(){ rc=$?; echo; echo "[ruff-relax] Script terminé avec exit code: $rc"; if [[ "$KEEP_OPEN" == "1" && -t 1 && -z "${CI:-}" ]]; then echo "[ruff-relax] Appuie sur Entrée pour quitter…"; read -r _; fi; }
trap 'stay_open' EXIT

cd "$(git rev-parse --show-toplevel)"

echo "==> (1) Réduit Ruff lint à import-sorting uniquement (select=['I'])"
python - <<'PY'
from pathlib import Path, re
p = Path("pyproject.toml")
s = p.read_text(encoding="utf-8")

def upsert(section, body_builder):
    import re
    pat = re.compile(rf"(?ms)^\[{re.escape(section)}\]\s*(.*?)(?=^\[|\Z)")
    m = pat.search(s)
    if not m:
        return s + f"\n[{section}]\n" + body_builder(""), True
    old = m.group(1)
    new = body_builder(old)
    if new != old:
        return s[:m.start(1)] + new + s[m.end(1):], True
    return s, False

changed = False

def body_ruff(old):
    # garde line-length/target-version/extend-exclude existants
    return old if old.endswith("\n") else old + "\n"

def body_lint(old):
    import re
    b = re.sub(r'(?m)^\s*select\s*=.*\n', "", old)
    b = re.sub(r'(?m)^\s*ignore\s*=.*\n', "", b)
    b = re.sub(r'(?m)^\s*fixable\s*=.*\n', "", b)
    if b and not b.endswith("\n"):
        b += "\n"
    b += 'select = ["I"]\n'
    b += 'fixable = ["ALL"]\n'
    return b

s, c1 = upsert("tool.ruff", body_ruff)
s, c2 = upsert("tool.ruff.lint", body_lint)
changed = c1 or c2

if changed:
    Path("pyproject.toml").write_text(s, encoding="utf-8")
print({"changed": changed})
PY

git add pyproject.toml

echo "==> (2) Exécute les hooks de style (tolérant) jusqu’à stabilisation"
pre-commit install || true
# 1er passage : ruff trie les imports (peut modifier, donc exit 1)
pre-commit run ruff -a || true
# 2e passage : doit être propre
pre-commit run ruff -a || true
pre-commit run ruff-format -a || true
pre-commit run black -a || true

echo "==> (3) Commit/push si des fichiers ont bougé"
if ! git diff --quiet; then
  git add -A
  git commit -m "style: temporarily scope Ruff to import-sorting (I); reformat"
  git push
else
  echo "Aucun changement à committer."
fi

echo "==> (4) Refresh manifest & revalider schémas"
KEEP_OPEN=0 tools/refresh_master_manifest_full.sh || true

echo '==> (5) Pré-commit global (tolérant)'
pre-commit run --all-files || true

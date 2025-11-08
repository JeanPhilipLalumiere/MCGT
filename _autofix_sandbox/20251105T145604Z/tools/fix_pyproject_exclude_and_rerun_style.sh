#!/usr/bin/env bash
set -euo pipefail
KEEP_OPEN="${KEEP_OPEN:-1}"
stay_open(){ rc=$?; echo; echo "[pyproject-fix] Script terminé avec exit code: $rc"; if [[ "$KEEP_OPEN" == "1" && -t 1 && -z "${CI:-}" ]]; then echo "[pyproject-fix] Appuie sur Entrée pour quitter…"; read -r _; fi; }
trap 'stay_open' EXIT

cd "$(git rev-parse --show-toplevel)"

echo "==> (1) Patch pyproject.toml (Black exclude en '''...'''; Ruff extend-exclude en liste)"
touch pyproject.toml
python - <<'PY'
from pathlib import Path
import re

p = Path("pyproject.toml")
s = p.read_text(encoding="utf-8")

changed = False

black_block = (
    "exclude = '''\n"
    "(\n"
    r"  \.git"
    "\n| " r"\.mypy_cache"
    "\n| " r"\.ci-out"
    "\n| legacy-tex"
    "\n| venv"
    "\n)\n"
    "'''\n"
)

def upsert_section(content: str, section: str, body_inserter):
    pat = re.compile(rf"(?ms)^\[{re.escape(section)}\]\s*(.*?)(?=^\[|\Z)")
    m = pat.search(content)
    if not m:
        ins = f"\n[{section}]\n" + body_inserter("")
        return content + ins, True
    old_body = m.group(1)
    new_body = body_inserter(old_body)
    if new_body != old_body:
        return content[:m.start(1)] + new_body + content[m.end(1):], True
    return content, False

def body_black(old):
    # Supprime toute définition existante de exclude (ligne simple ou bloc '''...'''/"""...""")
    body = re.sub(r"(?ms)^\s*exclude\s*=\s*(\"\"\".*?\"\"\"|'''.*?'''|\".*?\"|'.*?')\s*\n", "", old)
    # Évite doublon du bloc si déjà présent
    if "exclude = '''" not in body:
        if body and not body.endswith("\n"):
            body += "\n"
        body += black_block
    return body

def body_ruff(old):
    # On supprime (extend-)exclude existants, puis on pose extend-exclude en liste (globs)
    body = re.sub(r"(?m)^\s*(?:extend-)?exclude\s*=.*\n", "", old)
    # Ajoute settings de base s'ils n'y sont pas déjà
    if "line-length" not in body:
        body += ("\n" if not body.endswith("\n") and body else "") + "line-length = 88\n"
    if "target-version" not in body:
        body += "target-version = \"py312\"\n"
    if "extend-exclude" not in body:
        body += "extend-exclude = [\".ci-out\",\"legacy-tex\",\".git\",\"venv\",\".mypy_cache\"]\n"
    return body if body.endswith("\n") else body + "\n"

# Upsert [tool.black]
s, c1 = upsert_section(s, "tool.black", body_black)
changed |= c1

# Upsert [tool.ruff]
s, c2 = upsert_section(s, "tool.ruff", body_ruff)
changed |= c2

# S'assure qu'il existe un bloc [tool.ruff.lint] avec select basique
pat_lint = re.compile(r"(?ms)^\[tool\.ruff\.lint\]\s*(.*?)(?=^\[|\Z)")
m = pat_lint.search(s)
if not m:
    s += '\n[tool.ruff.lint]\nselect = ["E","F","W","I","B","UP","SIM"]\n'
    changed = True
else:
    body = m.group(1)
    if "select" not in body:
        s = s[:m.end(1)] + 'select = ["E","F","W","I","B","UP","SIM"]\n' + s[m.end(1):]
        changed = True

if changed:
    p.write_text(s, encoding="utf-8")
print({"changed": changed})
PY

git add pyproject.toml

echo "==> (2) Exécute Ruff/Black via pre-commit (tolérant)"
pre-commit install || true
pre-commit run ruff -a || true
pre-commit run ruff-format -a || true
pre-commit run black -a || true

echo "==> (3) Commit/push si style ou pyproject ont changé"
if ! git diff --cached --quiet; then
  git commit -m "style: fix pyproject exclude; run Ruff & Black"
  git push
else
  echo "Aucun changement à committer."
fi

echo "==> (4) Refresh manifest & revalider schémas"
KEEP_OPEN=0 tools/refresh_master_manifest_full.sh || true

echo "==> (5) Pré-commit global (tolérant)"
pre-commit run --all-files || true

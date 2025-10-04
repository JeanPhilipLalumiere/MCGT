#!/usr/bin/env bash
set -euo pipefail

REPORT=".ci-out/py_constants_guard_report.txt"
TSV=".ci-out/py_constants_registry_preview.tsv"
REG="zz-configuration/python_constants_registry.json"
: >"$REPORT"

log() { echo "INFO:  $*" | tee -a "$REPORT"; }
err() { echo "ERROR: $*" | tee -a "$REPORT"; }

log "Scan des constantes Python (AST) → $REG"
python - <<'PY' >"$TSV"
import sys, os, json, ast, pathlib, datetime

ROOT = pathlib.Path(".").resolve()

def dotted(p: pathlib.Path) -> str:
    rel = p.resolve().relative_to(ROOT)
    parts = list(rel.with_suffix("").parts)
    while parts and parts[0].startswith("."):
        parts.pop(0)
    return ".".join(parts)

def iter_py_files(root: pathlib.Path):
    skip_dirs = {".git","__pycache__",".mypy_cache",".pytest_cache",".ci-archive",".venv","venv","env","build","dist",".eggs"}
    for p in root.rglob("*.py"):
        if any(part in skip_dirs for part in p.parts):
            continue
        yield p

def make_jsonable(x):
    # conversion récursive vers un sous-ensemble JSON
    if isinstance(x, dict):
        return {str(k): make_jsonable(v) for k, v in x.items()}
    if isinstance(x, (list, tuple)):
        return [make_jsonable(v) for v in x]
    if isinstance(x, set):
        try:
            return sorted(make_jsonable(v) for v in x)
        except Exception:
            return [make_jsonable(v) for v in x]
    if isinstance(x, (int, float, bool, str)) or x is None:
        return x
    # fallback: représentation lisible
    return repr(x)

def literal_info(node):
    # Essaie d'évaluer le littéral; sinon garde l'expression
    try:
        val = ast.literal_eval(node)
        if isinstance(val, bool): t="boolean"
        elif isinstance(val, int): t="integer"
        elif isinstance(val, float): t="number"
        elif isinstance(val, str): t="string"
        elif val is None: t="null"
        elif isinstance(val, tuple): t="tuple"
        elif isinstance(val, list): t="list"
        elif isinstance(val, dict): t="object"
        elif isinstance(val, set): t="set"
        else: t=type(val).__name__
        return t, val, True
    except Exception:
        try:
            rep = ast.unparse(node)
        except Exception:
            rep = "<non-unparseable>"
        return "unknown", rep, False

def is_upper_snake(name: str) -> bool:
    if not name or name.startswith("_"): return False
    return name.upper() == name

consts = []
issues = {"conflicts": []}
by_name = {}

for path in iter_py_files(ROOT):
    try:
        txt = path.read_text(encoding="utf-8", errors="replace")
    except Exception:
        continue
    try:
        mod = ast.parse(txt, filename=str(path))
    except Exception:
        continue
    module = dotted(path)
    for node in mod.body:
        targets = []
        if isinstance(node, ast.Assign):
            targets = [t for t in node.targets if isinstance(t, ast.Name)]
            value = node.value
            lineno = node.lineno
        elif isinstance(node, ast.AnnAssign) and isinstance(node.target, ast.Name):
            targets = [node.target]
            value = node.value
            lineno = node.lineno
        else:
            continue

        for t in targets:
            name = t.id
            if not is_upper_snake(name):
                continue
            vtype, vraw, is_lit = literal_info(value) if value is not None else ("unknown", None, False)
            entry = {
                "name": name,
                "module": module,
                "path": str(path.as_posix()),
                "lineno": lineno,
                "value_type": vtype,
                "is_literal": is_lit,
                "value": make_jsonable(vraw) if is_lit else None,
                "expr": None if is_lit else (vraw or None),
            }
            consts.append(entry)
            by_name.setdefault(name, []).append(entry)

# Détection de conflits: même nom, valeurs littérales différentes
for name, items in by_name.items():
    variants = []
    for it in items:
        if it["is_literal"]:
            variants.append(json.dumps({"t": it["value_type"], "v": it["value"]}, sort_keys=True, ensure_ascii=False))
    if len(set(variants)) > 1:
        issues["conflicts"].append({
            "name": name,
            "variants": [json.loads(v) for v in sorted(set(variants))],
            "occurrences": items,
        })

data = {
    "generated_at": datetime.datetime.utcnow().strftime("%Y-%m-%dT%H:%M:%SZ"),
    "python_version": sys.version.split()[0],
    "root": str(ROOT),
    "total_constants": len(consts),
    "issues": issues,
    "constants": consts,
}

# Aperçu TSV (limite soft à 1000 lignes)
print("name\tvalue_type\tis_literal\tmodule\tpath:lineno\tvalue_or_expr")
for c in consts[:1000]:
    v = c["value"] if c["is_literal"] else (c["expr"] or "")
    print(f"{c['name']}\t{c['value_type']}\t{c['is_literal']}\t{c['module']}\t{c['path']}:{c['lineno']}\t{v}")

# Écriture du registre
out = pathlib.Path("zz-configuration/python_constants_registry.json")
out.write_text(json.dumps(data, indent=2, ensure_ascii=False) + "\n", encoding="utf-8")
PY

echo "==> (a) Résumé du scan (premières lignes TSV)" | tee -a "$REPORT"
sed -n '1,40p' "$TSV" | tee -a "$REPORT"

echo "==> (b) Vérification conflits (si présents)" | tee -a "$REPORT"
python - <<'PY' | tee -a "$REPORT"
import json, pathlib
reg = json.loads(pathlib.Path("zz-configuration/python_constants_registry.json").read_text(encoding="utf-8"))
conf = reg.get("issues",{}).get("conflicts",[])
print(f"CONFLICTS: {len(conf)}")
for c in conf[:20]:
    print(f"- {c['name']} -> {len(c['variants'])} variantes, {len(c['occurrences'])} occurrences")
PY

echo "==> (c) Fin génération" | tee -a "$REPORT"

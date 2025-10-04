#!/usr/bin/env bash
# shellcheck source=/dev/null
. .ci-helpers/guard.sh
set -euo pipefail

DRY_RUN="${DRY_RUN:-0}" # DRY_RUN=1 => plan uniquement (pas d'écriture)
# shellcheck disable=SC2034
REPORT=".ci-out/unify_cG_apply_report.txt"

python - <<'PY' 2>&1 | tee -a ".ci-out/unify_cG_apply_py.log"
import ast, io, os, re, sys
from pathlib import Path

ROOT = Path(".").resolve()
EXCL_DIRS = {".git", ".hg", ".svn", ".ci-out", ".ci-logs", ".venv", "venv", "env", "build", "dist", "__pycache__"}
NAMES_C = {"c", "C", "clight", "c_light", "C_LIGHT", "C_LIGHT_M_S", "C_LIGHT_KM_S"}
NAMES_G = {"g", "G", "G_N", "GNewton", "G_SI"}

def approx(x, ref, rel=0.02):
    try:
        return abs(x - ref) <= rel * abs(ref)
    except Exception:
        return False

def classify_c_unit(num_or_none):
    """Retourne 'M_S', 'KM_S' ou None si inconnu."""
    if num_or_none is None:
        return None
    if approx(num_or_none, 299_792_458.0, rel=0.02) or approx(num_or_none, 3.0e8, rel=0.05):
        return "M_S"
    if approx(num_or_none, 299_792.458, rel=0.02) or approx(num_or_none, 3.0e5, rel=0.05):
        return "KM_S"
    return None

def number_from(node):
    try:
        if isinstance(node, ast.Constant) and isinstance(node.value, (int, float)):
            return float(node.value)
        if isinstance(node, ast.UnaryOp) and isinstance(node.op, ast.USub):
            v = number_from(node.operand)
            return -v if isinstance(v, (int, float, float)) else None
        # évalue prudemment des petites expressions numériques (sans builtins)
        if isinstance(node, ast.BinOp) or isinstance(node, ast.UnaryOp):
            code = ast.unparse(node)
            return float(eval(code, {"__builtins__": {}}, {}))  # noqa: S307 (sandboxé)
    except Exception:
        return None
    return None

def insert_import(lines, names):
    """Insère/complète 'from mcgt.constants import ...' après docstring/__future__."""
    if not names:
        return lines
    imp_line = "from mcgt.constants import " + ", ".join(sorted(names)) + "\n"

    # Si déjà présent, merge des noms
    for i, line in enumerate(lines):
        if line.strip().startswith("from mcgt.constants import "):
            existing = [x.strip() for x in line.split("import",1)[1].split(",")]
            pool = sorted(set([n for n in existing if n] + list(names)))
            lines[i] = "from mcgt.constants import " + ", ".join(pool) + "\n"
            return lines

    # Trouver insertion point : après shebang/encoding/docstring/__future__
    idx = 0
    if lines and lines[0].startswith("#!"):
        idx = 1
    enc_re = re.compile(r"coding[:=]\s*([-\w.]+)")
    if idx < len(lines) and ("coding" in lines[idx] and enc_re.search(lines[idx])):
        idx += 1

    # skipper docstring module
    try:
        mod = ast.parse("".join(lines))
        if (mod.body and isinstance(mod.body[0], ast.Expr)
                and isinstance(getattr(mod.body[0], "value", None), ast.Constant)
                and isinstance(mod.body[0].value.value, str)):
            # docstring présent
            first_non = mod.body[1] if len(mod.body) > 1 else None
            # insérer après docstring + éventuels __future__
            after = 1
            while after < len(mod.body):
                n = mod.body[after]
                if isinstance(n, ast.ImportFrom) and n.module == "__future__":
                    after += 1
                else:
                    break
            # trouver ligne
            tgt = mod.body[after-1] if after>1 else mod.body[0]
            insert_at = getattr(tgt, "end_lineno", 1)
            # insérer une ligne après insert_at
            lines = lines[:insert_at] + [imp_line] + lines[insert_at:]
            return lines
    except Exception:
        pass

    # fallback : au début (après shebang/encoding éventuels)
    lines = lines[:idx] + [imp_line] + lines[idx:]
    return lines

def replace_slice(lines, start, end, repl):
    """Remplace le slice [start:(end)] dans le texte par repl, basé sur positions (line,col)."""
    # lines indices 0-based ; positions sont (lineno>=1, col>=0)
    s_line, s_col = start
    e_line, e_col = end
    s_line -= 1; e_line -= 1
    if s_line == e_line:
        lines[s_line] = lines[s_line][:s_col] + repl + lines[s_line][e_col:]
    else:
        first = lines[s_line][:s_col]
        last  = lines[e_line][e_col:]
        lines[s_line:e_line+1] = [first + repl + last]

def process_file(path: Path):
    src = path.read_text(encoding="utf-8")
    try:
        tree = ast.parse(src, filename=str(path))
    except SyntaxError:
        return {"file": str(path), "changed": False, "reason": "syntax-error"}

    lines = src.splitlines(keepends=True)
    changes = []
    need_imports = set()

    for node in ast.walk(tree):
        if isinstance(node, (ast.Assign, ast.AnnAssign)):
            # cibles
            targets = []
            if isinstance(node, ast.Assign):
                for t in node.targets:
                    if isinstance(t, ast.Name):
                        targets.append(t.id)
            else:
                if isinstance(node.target, ast.Name):
                    targets.append(node.target.id)
            if not targets:
                continue

            val = getattr(node, "value", None)
            if val is None:
                continue

            names_lower = {t.lower() for t in targets}
            touch_c = bool(names_lower & {n.lower() for n in NAMES_C})
            touch_g = bool(names_lower & {n.lower() for n in NAMES_G})

            if not touch_c and not touch_g:
                continue  # sécurité : on ne patch QUE les noms explicites

            # calcule valeur numérique si possible
            vnum = number_from(val)

            if touch_c:
                unit = classify_c_unit(vnum)
                repl = "C_LIGHT_M_S" if unit in (None, "M_S") else "C_LIGHT_KM_S"
                # position du RHS
                try:
                    s = (val.lineno, val.col_offset)
                    e = (val.end_lineno, val.end_col_offset)
                    replace_slice(lines, s, e, repl)
                    need_imports.add(repl)
                    changes.append({"kind": "c", "unit": unit or "M_S", "line": getattr(node, "lineno", -1)})
                except Exception:
                    pass

            if touch_g:
                repl = "G_SI"
                try:
                    s = (val.lineno, val.col_offset)
                    e = (val.end_lineno, val.end_col_offset)
                    replace_slice(lines, s, e, repl)
                    need_imports.add(repl)
                    changes.append({"kind": "g", "line": getattr(node, "lineno", -1)})
                except Exception:
                    pass

    if not changes:
        return {"file": str(path), "changed": False, "reason": "no-targets"}

    # insère/complète import
    lines = insert_import(lines, need_imports)

    new_src = "".join(lines)
    if new_src != src:
        if os.getenv("DRY_RUN", "0") == "1":
            return {"file": str(path), "changed": True, "dry_run": True, "edits": changes}
        path.write_text(new_src, encoding="utf-8")
        return {"file": str(path), "changed": True, "dry_run": False, "edits": changes}
    return {"file": str(path), "changed": False, "reason": "no-diff-after"}

touched = []
for py in ROOT.rglob("*.py"):
    if set(py.parts) & EXCL_DIRS:
        continue
    if py.name == "__init__.py":
        pass
    res = process_file(py)
    if res.get("changed"):
        touched.append(res)

print("==> Résumé des modifications c/G")
print({"files_changed": len(touched)})
for r in touched:
    print(f"[patched] {r['file']} :: edits={r.get('edits')}")
PY

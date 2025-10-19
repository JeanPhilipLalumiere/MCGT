#!/usr/bin/env python3
# tools/ast_scan.py
# Parcours le repo, collecte imports, defs, présence de __main__, shebang, taille.
# Ne s'exécute pas dans les modules (utilise ast.parse seulement).

import ast
import os
import json
import sys
from pathlib import Path
from collections import Counter, defaultdict

ROOT = Path('.').resolve()
OUT_DIR = Path('.ci-out/scan')
OUT_DIR.mkdir(parents=True, exist_ok=True)

pyfiles = [p for p in ROOT.rglob('*.py') if '.git' not in p.parts and '.venv' not in p.parts]
summary = {
    "repo_root": str(ROOT),
    "num_py": len(pyfiles),
    "files": [],
    "imports_counter": {},
    "froms_counter": {},
}

imports = Counter()
froms = Counter()
files_meta = []

for p in sorted(pyfiles):
    rec = {"path": str(p.relative_to(ROOT)), "imports": [], "froms": [], "defs": [], "has_main": False, "shebang": None, "size": p.stat().st_size}
    try:
        text = p.read_text(encoding='utf-8')
    except Exception as e:
        rec["error"] = f"read_error:{e}"
        files_meta.append(rec)
        continue

    # shebang
    first_line = text.splitlines()[0] if text.splitlines() else ''
    if first_line.startswith('#!'):
        rec["shebang"] = first_line.strip()

    try:
        tree = ast.parse(text)
    except Exception as e:
        rec["error"] = f"ast_parse_error:{e}"
        files_meta.append(rec)
        continue

    for node in ast.walk(tree):
        if isinstance(node, ast.Import):
            for n in node.names:
                top = n.name.split('.')[0]
                rec["imports"].append(top)
                imports[top] += 1
        elif isinstance(node, ast.ImportFrom):
            if node.module:
                top = node.module.split('.')[0]
                rec["froms"].append(top)
                froms[top] += 1

    # top-level defs (functions / classes)
    top_defs = []
    for n in getattr(tree, 'body', []):
        if isinstance(n, ast.FunctionDef) or isinstance(n, ast.ClassDef):
            top_defs.append(n.name)
    rec["defs"] = top_defs

    # detect "if __name__ == '__main__'" in AST (robuste)
    has_main = False
    for n in ast.walk(tree):
        if isinstance(n, ast.If):
            try:
                src = ast.get_source_segment(text, n.test) or ''
                if "__name__" in src and "__main__" in src:
                    has_main = True
                    break
            except Exception:
                continue
    rec["has_main"] = has_main

    files_meta.append(rec)

summary["files"] = files_meta
summary["imports_counter"] = dict(imports.most_common())
summary["froms_counter"] = dict(froms.most_common())

# write outputs
with open(OUT_DIR / "ast_scan_summary.json", "w", encoding="utf-8") as fh:
    json.dump(summary, fh, indent=2, ensure_ascii=False)

# write CSV-like files for quick greps
with open(OUT_DIR / "ast_file_mains.csv", "w", encoding="utf-8") as fm:
    fm.write("path,size,has_main,shebang,top_defs,imports_count,froms_count\n")
    for f in summary["files"]:
        fm.write(",".join([
            f["path"],
            str(f.get("size", "")),
            str(f.get("has_main", False)),
            '"' + (f.get("shebang") or "").replace('"','""') + '"',
            '"' + ",".join(f.get("defs", []))[:500].replace('"','""') + '"',
            str(len(f.get("imports", []))),
            str(len(f.get("froms", []))),
        ]) + "\n")

with open(OUT_DIR / "top_imports.txt", "w", encoding="utf-8") as ti:
    for k,v in summary["imports_counter"].items():
        ti.write(f"{v:8d} {k}\n")

with open(OUT_DIR / "top_froms.txt", "w", encoding="utf-8") as ti2:
    for k,v in summary["froms_counter"].items():
        ti2.write(f"{v:8d} {k}\n")

print("AST scan complete. Outputs in", str(OUT_DIR / "ast_scan_summary.json"))

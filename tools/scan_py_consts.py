#!/usr/bin/env python3
import ast, pathlib, sys

OUT = pathlib.Path(".ci-out/python_consts.tsv")
OUT.parent.mkdir(parents=True, exist_ok=True)

def is_module_const(name):
    return name.isupper() and len(name) >= 3 and name[0].isalpha()

def preview(value, n=80):
    s = repr(value)
    return (s if len(s) <= n else s[:n] + "…").replace("\t","\\t").replace("\n","\\n")

rows = []
for p in sorted(pathlib.Path(".").rglob("*.py")):
    try:
        src = p.read_text(encoding="utf-8", errors="ignore")
        mod = ast.parse(src, filename=str(p))
    except Exception:
        continue
    for node in mod.body:
        if isinstance(node, ast.Assign):
            for target in node.targets:
                if isinstance(target, ast.Name) and is_module_const(target.id):
                    try:
                        val = ast.literal_eval(node.value)
                    except Exception:
                        val = "<non-literal>"
                    rows.append((p.as_posix(), target.id, preview(val), getattr(node, "lineno", 0)))

with OUT.open("w", encoding="utf-8") as f:
    f.write("file\tname\tvalue_preview\tlineno\n")
    for r in rows:
        f.write(f"{r[0]}\t{r[1]}\t{r[2]}\t{r[3]}\n")

print(f"[py consts] {len(rows)} entries → {OUT}")

#!/usr/bin/env python3
import pathlib
import re

OUT = pathlib.Path(".ci-out/make_vars.tsv")
OUT.parent.mkdir(parents=True, exist_ok=True)

pat = re.compile(r"^([A-Z][A-Z0-9_]+)\s*(\?|:)?=\s*(.*)$")

rows = []
for p in sorted(pathlib.Path(".").rglob("Makefile")):
    try:
        lines = p.read_text(encoding="utf-8", errors="ignore").splitlines()
    except Exception:
        continue
    for i, line in enumerate(lines, 1):
        m = pat.match(line.strip())
        if m:
            var, op, val = m.group(1), (m.group(2) or "="), m.group(3).strip()
            rows.append((p.as_posix(), i, var, op, val))

with OUT.open("w", encoding="utf-8") as f:
    f.write("file\tlineno\tvar\toperator\tvalue\n")
    for r in rows:
        f.write(f"{r[0]}\t{r[1]}\t{r[2]}\t{r[3]}\t{r[4]}\n")

print(f"[make vars] {len(rows)} entries → {OUT}")

#!/usr/bin/env bash
set -euo pipefail
CSV="zz-out/homog_smoke_pass14.csv"

# Refresh smoke so the CSV is current
tools/pass14_smoke_with_mapping.sh >/dev/null

python3 - <<'PY'
from pathlib import Path
import csv, re, sys

csv_path = Path("zz-out/homog_smoke_pass14.csv")
if not csv_path.exists():
    print("[step32] missing zz-out/homog_smoke_pass14.csv"); sys.exit(1)

rows = list(csv.reader(csv_path.open(encoding="utf-8")))
rows = rows[1:] if rows else []

def reason(r):
    return ",".join(r[2:-3]) if len(r) >= 6 else (r[2] if len(r) >= 3 else "")

def read_text(fp: Path) -> str:
    return fp.read_text(encoding="utf-8", errors="replace")

remaining = []

for r in rows:
    if len(r) < 3:
        continue
    msg = reason(r)
    if "SyntaxError" not in msg and "IndentationError" not in msg:
        continue
    p = r[0]
    if not p.endswith(".py"):
        continue
    fp = Path(p)
    if not fp.exists():
        continue

    # try to extract line from message; otherwise from compile()
    m = re.search(r"line\s+(\d+)", msg)
    line = int(m.group(1)) if m else None
    if line is None:
        try:
            compile(read_text(fp), str(fp), "exec")
        except SyntaxError as e:
            line = e.lineno or 1
        except Exception:
            line = 1
    if line is None:
        line = 1

    lines = read_text(fp).splitlines()
    if not lines:
        continue
    start = max(1, line - 3)
    end   = min(len(lines), line + 3)
    snippet = "\n".join(f"{i:>5}: {lines[i-1]}" for i in range(start, end + 1))
    kind = msg.split(":")[0]

    print(f"\n=== {p} | {kind} | line~{line} ===\n{snippet}")
    remaining.append(p)

Path("zz-out/_remaining_files.lst").write_text(
    "\n".join(sorted(set(remaining))) + "\n", encoding="utf-8"
)
PY

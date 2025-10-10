#!/usr/bin/env bash
set -euo pipefail

CSV="zz-out/homog_smoke_pass14.csv"

echo "[STEP07] 0) Smoke de référence"
tools/pass14_smoke_with_mapping.sh

echo "[STEP07] 1) Triage & mini-fix (def sans corps + strings non fermées)"
python3 - <<'PY'
import csv, io, os, re, sys
from pathlib import Path

CSV_PATH = Path("zz-out/homog_smoke_pass14.csv")
if not CSV_PATH.exists():
    print("[ERR] CSV absent:", CSV_PATH)
    sys.exit(1)

def reconstruct_reason(row):
    # reason = col3 jusqu'à l'avant-avant-dernière (car virgules dans les messages)
    return ",".join(row[2:-3]) if len(row) >= 6 else (row[2] if len(row)>=3 else "")

rows = list(csv.reader(CSV_PATH.open(encoding="utf-8")))
rows = rows[1:]  # skip header

targets = []
for r in rows:
    if not r or len(r)<3: continue
    fpath = r[0]
    reason = reconstruct_reason(r)
    if "SyntaxError" in reason or "IndentationError" in reason:
        # try to parse a line number
        m = re.search(r"line\s+(\d+)", reason)
        n = int(m.group(1)) if m else None
        targets.append((fpath, reason, n))

# group by file
by_file = {}
for f, reason, ln in targets:
    by_file.setdefault(f, []).append((reason, ln))

def insert_after_line(lines, line_no, text):
    idx = max(0, min(len(lines), line_no))  # 1-based -> insert at index line_no
    lines.insert(idx, text)

def fix_def_missing_body(path: Path, line_no: int) -> bool:
    """Insert a 'pass' one line after the def: with proper indent, if no body."""
    try:
        lines = path.read_text(encoding="utf-8").splitlines(True)
    except Exception:
        return False
    if not (1 <= line_no <= len(lines)):
        return False
    def_line = lines[line_no-1]
    # compute base indent of 'def'
    base = len(def_line) - len(def_line.lstrip(' '))
    # if next meaningful line is already more indented, skip
    i = line_no
    while i < len(lines) and lines[i].strip()=="":
        i += 1
    if i < len(lines):
        nxt = lines[i]
        nxt_indent = len(nxt) - len(nxt.lstrip(' '))
        if nxt.strip() and nxt_indent > base:
            return False  # body exists
    insert_after_line(lines, line_no, " "*(base+4) + "pass\n")
    path.write_text("".join(lines), encoding="utf-8")
    return True

def close_string_at_line(path: Path, line_no: int) -> bool:
    """Conservative: if line has odd number of \" or ' → append closing quote."""
    try:
        lines = path.read_text(encoding="utf-8").splitlines(True)
    except Exception:
        return False
    if not (1 <= line_no <= len(lines)):
        return False
    s = lines[line_no-1]
    # If line already ends with quote, do nothing
    if s.rstrip().endswith(('"', "'")):
        return False
    # Count quotes ignoring escaped \" or \'
    def count_q(line, q):
        cnt = 0
        i = 0
        while i < len(line):
            if line[i] == '\\\\':
                i += 2
                continue
            if line[i] == q:
                cnt += 1
            i += 1
        return cnt
    changed=False
    if count_q(s, '"') % 2 == 1:
        lines[line_no-1] = s.rstrip("\n") + "\"\n"
        changed=True
    elif count_q(s, "'") % 2 == 1:
        lines[line_no-1] = s.rstrip("\n") + "'\n"
        changed=True
    else:
        # As a last resort, if the line seems to start a raw/triple-less string, add a "
        if ("\"" in s) and not s.rstrip().endswith("\""):
            lines[line_no-1] = s.rstrip("\n") + "\"\n"; changed=True
        elif ("'" in s) and not s.rstrip().endswith("'"):
            lines[line_no-1] = s.rstrip("\n") + "'\n"; changed=True
    if changed:
        path.write_text("".join(lines), encoding="utf-8")
    return changed

fix_count = 0
for fpath, issues in by_file.items():
    p = Path(fpath)
    if not p.exists():
        continue
    for reason, ln in issues:
        if ln is None:  # no line info → skip auto-fix, only report
            continue
        if "expected an indented block after function definition" in reason:
            if fix_def_missing_body(p, ln):
                print(f"[FIX:def-pass] {p}:{ln}")
                fix_count += 1
        elif "unterminated string literal" in reason:
            if close_string_at_line(p, ln):
                print(f"[FIX:string] {p}:{ln}")
                fix_count += 1

print(f"[RESULT] tiny_fixes={fix_count}")

# --- Emit a contextual report for remaining Syntax/Indent errors
REPORT = Path("zz-out/_step07_report.txt")
with REPORT.open("w", encoding="utf-8") as out:
    for fpath, issues in sorted(by_file.items()):
        p = Path(fpath)
        try:
            lines = p.read_text(encoding="utf-8").splitlines()
        except Exception:
            lines = []
        for reason, ln in issues:
            out.write(f"===== {fpath}\n")
            out.write(f"REASON: {reason}\n")
            if ln is not None and lines:
                lo = max(1, ln-6); hi = min(len(lines), ln+6)
                for i in range(lo, hi+1):
                    mark = ">>" if i==ln else "  "
                    out.write(f"{mark} {i:5d}: {lines[i-1]}\n")
            out.write("\n")
print(f"[REPORT] written zz-out/_step07_report.txt")
PY

echo "[STEP07] 2) Smoke après mini-fix"
tools/pass14_smoke_with_mapping.sh

echo "[STEP07] 3) Top erreurs (post-fix)"
awk -F, 'NR>1{
  n=NF; r=$3; for(i=4;i<=n-3;i++) r=r","$i;
  printf "%s: %s\n",$2,r
}' "$CSV" | LC_ALL=C sort | uniq -c | LC_ALL=C sort -nr | head -25

echo
echo "[INFO] Rapport détaillé: zz-out/_step07_report.txt"

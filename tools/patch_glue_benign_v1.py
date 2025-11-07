#!/usr/bin/env python3
from __future__ import annotations
import re, shutil
from pathlib import Path
from datetime import datetime

ROOT = Path("zz-scripts")
STAMP = datetime.now().strftime("%Y-%m-%dT%H%M%S")
BACK = Path(f"_autofix_sandbox/{STAMP}_benign_glue_backup")
BACK.mkdir(parents=True, exist_ok=True)

RX_FILES = lambda p: p.suffix == ".py"
RX_DOT_ARGP   = re.compile(r'(?m)^\s*\.\s*ArgumentParser\s*\(')
RX_DBL_COMMA  = re.compile(r'description\s*=\s*["\']\(?[Aa]utofix\)?["\']\s*,\s*,')
# Sécuritaire: uniquement à la colonne 0 (top-level strict)
RX_PARSE_TOP0 = re.compile(r'(?m)^(args\s*=\s*\w+\s*\.parse_args\s*\(\s*\)\s*)$')

def transform(text: str) -> tuple[str, dict]:
    changes = {}
    new = text

    def sub_one(rx, repl):
        nonlocal new
        before = new
        new = rx.sub(repl, new)
        return before != new

    if sub_one(RX_DOT_ARGP, "ArgumentParser("):
        changes[".ArgumentParser("] = True
    if sub_one(RX_DBL_COMMA, 'description="(autofix)",'):
        changes['description="(autofix)",,'] = True
    if sub_one(RX_PARSE_TOP0, r'# [autofix] disabled top-level parse: \1'):
        changes["top.parse_args()@col0"] = True

    return new, changes

def main():
    patched = 0; skipped = 0
    for p in ROOT.rglob("*.py"):
        if any(seg.startswith(("_attic", "_tmp")) for seg in p.parts):
            continue
        try:
            s = p.read_text(encoding="utf-8", errors="replace")
        except Exception:
            skipped += 1; continue
        new, changes = transform(s)
        if changes:
            dst = BACK / p.relative_to(ROOT)
            dst.parent.mkdir(parents=True, exist_ok=True)
            shutil.copy2(p, dst)
            p.write_text(new, encoding="utf-8")
            print(f"[patched] {p} :: " + ", ".join(changes))
            patched += 1
    print(f"Done. Patched files: {patched}; skipped: {skipped}; backup @ {BACK}")
if __name__ == "__main__":
    main()

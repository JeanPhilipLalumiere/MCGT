#!/usr/bin/env python3
from __future__ import annotations
import re, sys
from pathlib import Path

ROOTS = [Path("zz-scripts")]
RX_DOT_ARGP = re.compile(r'(?m)^\s*\.\s*ArgumentParser\s*\(')
RX_TOP_PARSE= re.compile(r'(?m)^\s*args\s*=\s*\w+\s*\.parse_args\s*\(\s*\)\s*$')
RX_DBL_COMMA= re.compile(r'description\s*=\s*["\']\(?[Aa]utofix\)?["\']\s*,\s*,')
hits = []

def scan_file(p: Path):
    try: s = p.read_text(encoding="utf-8", errors="replace")
    except Exception: return
    h = []
    if RX_DOT_ARGP.search(s):  h.append("dot.ArgumentParser(")
    if RX_TOP_PARSE.search(s): h.append("top.parse_args()")
    if RX_DBL_COMMA.search(s): h.append('description="(autofix)",,')
    if h: hits.append((p, h))

def main():
    for root in ROOTS:
        for p in root.rglob("*.py"):
            if any(seg.startswith("_attic") or seg.startswith("_tmp") for seg in p.parts):
                continue
            scan_file(p)
    print("# Audit argparse glue — lecture seule")
    for p, h in sorted(hits):
        print(f"- {p}: " + ", ".join(h))
    print(f"\nTotal fichiers concernés: {len(hits)}")
if __name__ == "__main__":
    main()

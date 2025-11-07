#!/usr/bin/env python3
from __future__ import annotations
import re, difflib, os
from pathlib import Path
from datetime import datetime

APPLY = os.environ.get("APPLY", "0") == "1"
ROOT = Path(".")
TS = datetime.now().strftime("%Y%m%dT%H%M%SZ")
OUT = Path(f".ci-out/cli_parser_name_fix_v1_{TS}"); OUT.mkdir(parents=True, exist_ok=True)

RX_PARSER_DEF = re.compile(r'^(?P<indent>\s*)(?P<name>\w+)\s*=\s*argparse\.ArgumentParser\(', re.M)
RX_IMPORT_ARGPARSE = re.compile(r'^\s*import\s+argparse\b', re.M)
RX_ADD_CALL = re.compile(r'add_common_plot_args\s*\(\s*(?P<arg>[^)]+)\)')
RX_PARSE_ARGS = re.compile(r'^\s*args\s*=\s*(?P<p>\w+)\.parse_args\(\)\s*$', re.M)

def patch(path: Path) -> dict:
    try:
        s = path.read_text(encoding="utf-8", errors="replace")
    except Exception as e:
        return {"path": str(path), "error": f"READ:{e}"}

    changed, mods, issues = False, [], []
    m_all = list(RX_PARSER_DEF.finditer(s))
    if not m_all:
        return {"path": str(path), "changed": False, "issues": ["NO_PARSER_DEF"]}

    parser_name = m_all[-1].group("name")  # choisir le dernier défini
    new = s

    # import argparse si absent
    if not RX_IMPORT_ARGPARSE.search(new):
        new = "import argparse\n" + new
        mods.append("ADD_IMPORT_ARGPARSE")

    # corriger add_common_plot_args(parser→<name>)
    def _repl_add(m):
        arg = m.group("arg").strip()
        return f"add_common_plot_args({parser_name})"
    new, n = RX_ADD_CALL.subn(_repl_add, new)
    if n: mods.append(f"FIX_ADD_CALL:{n}")

    # corriger args = parser.parse_args() → args = <name>.parse_args()
    def _repl_parse(m):
        return f"args = {parser_name}.parse_args()"
    new, n2 = RX_PARSE_ARGS.subn(_repl_parse, new)
    if n2: mods.append(f"FIX_PARSE_ARGS:{n2}")

    # si pas de parse_args du tout, en ajouter un après la dernière def du parser
    if not RX_PARSE_ARGS.search(new):
        last = m_all[-1].end()
        insert = "\nargs = %s.parse_args()\n" % parser_name
        new = new[:last] + insert + new[last:]
        mods.append("ADD_PARSE_ARGS")

    if new != s:
        diff = "".join(difflib.unified_diff(s.splitlines(True), new.splitlines(True),
                                            fromfile=str(path), tofile=str(path)+" (fixed)"))
        (OUT / (path.name + ".diff")).write_text(diff, encoding="utf-8")
        if APPLY:
            path.write_text(new, encoding="utf-8")
        changed = True

    return {"path": str(path), "changed": changed, "mods": mods, "issues": issues}

def main() -> int:
    targets = [p for p in Path("zz-scripts").rglob("*.py") if p.is_file()]
    rep = [patch(p) for p in targets]
    chg = sum(1 for r in rep if r.get("changed"))
    print(("# cli_parser_name_fix_v1 — APPLY" if APPLY else "# cli_parser_name_fix_v1 — DRY_RUN"))
    print(f"Targets: {len(targets)} | Changed: {chg}")
    print(f"Diffs -> {OUT}/")
    for r in rep[:80]:
        flags=[]
        if r.get("mods"): flags.append(f"mods={r['mods']}")
        if r.get("issues"): flags.append(f"issues={r['issues']}")
        print(f"- {r['path']} :: " + ("; ".join(flags) if flags else "OK"))
    return 0

if __name__ == "__main__":
    raise SystemExit(main())

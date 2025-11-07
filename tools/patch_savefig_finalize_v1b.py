#!/usr/bin/env python3
from __future__ import annotations
import os, sys, re, difflib
from pathlib import Path
from datetime import datetime

APPLY = os.environ.get("APPLY", "0") == "1"
ROOT = Path(".")
TS = datetime.now().strftime("%Y%m%dT%H%M%SZ")
OUTDIR = Path(f".ci-out/patch_savefig_v1b_{TS}")
OUTDIR.mkdir(parents=True, exist_ok=True)

RX_PARSE_ARGS   = re.compile(r'^\s*args\s*=\s*\w+\.parse_args\(\)\s*$', re.M)
RX_PARSER_DEF   = re.compile(r'^\s*(\w+)\s*=\s*argparse\.ArgumentParser\(', re.M)
RX_HAS_FINALIZE = re.compile(r'\bfinalize_plot_from_args\s*\(\s*args\s*\)')
RX_SAVEFIG_LINE = re.compile(r'^(?P<indent>\s*)plt\.savefig\s*\(', re.M)

def insert_after_last(match_iter, s: str, payload: str) -> tuple[str, bool]:
    mlist = list(match_iter)
    if not mlist:
        return s, False
    last = mlist[-1]
    pos = last.end()
    ins = "\n" if (pos < len(s) and s[pos] != "\n") else ""
    return s[:pos] + ins + payload + s[pos:], True

def comment_all_savefig_lines(s: str) -> tuple[str, int]:
    n_changes = 0
    def repl(m: re.Match) -> str:
        nonlocal n_changes
        n_changes += 1
        return f"{m.group('indent')}# [mcgt-homog] " + s[m.start():m.end()].lstrip()
    # On ne peut pas modifier la chaîne sur place pendant l'itération.
    lines = s.splitlines(True)
    for i, line in enumerate(lines):
        if RX_SAVEFIG_LINE.match(line) and not line.lstrip().startswith("#"):
            lines[i] = re.sub(r'^', '# [mcgt-homog] ', line, count=1)
            n_changes += 1
    return "".join(lines), n_changes

def patch_one(path: Path) -> dict:
    try:
        src = path.read_text(encoding="utf-8", errors="replace")
    except Exception as e:
        return {"path": str(path), "error": f"READ:{e}"}

    # Besoin d'un parser + parse_args → sinon on NE TOUCHE PAS (éviter de casser)
    has_parse = RX_PARSE_ARGS.search(src) is not None
    has_parser = RX_PARSER_DEF.search(src) is not None
    if not (has_parse or has_parser):
        return {"path": str(path), "changed": False, "issues": ["NO_PARSER_DEF"]}

    # Si parser défini mais pas parse_args, on l'injecte juste après la dernière définition de parser
    new = src
    mods, issues = [], []
    if (not has_parse) and has_parser:
        parser_defs = RX_PARSER_DEF.finditer(src)
        new, ok = insert_after_last(parser_defs, new, "args = parser.parse_args()\n" if "parser =" in src else "\n")
        if ok:
            mods.append("ADD_PARSE_ARGS")

    # Commenter toutes les lignes plt.savefig(...)
    new, n_c = comment_all_savefig_lines(new)
    if n_c > 0:
        mods.append(f"COMMENT_SAVEFIG:{n_c}")

    # Finalize en queue de fichier si absent
    if not RX_HAS_FINALIZE.search(new) and n_c > 0:
        new = new.rstrip() + "\n\n__mcgt_out = finalize_plot_from_args(args)\n"
        mods.append("ADD_FINALIZE")

    changed = (new != src)
    if changed:
        diff = "".join(difflib.unified_diff(src.splitlines(True), new.splitlines(True),
                                            fromfile=str(path), tofile=str(path)+" (patched)"))
        (OUTDIR / (path.name + ".diff")).write_text(diff, encoding="utf-8")
        if APPLY:
            bak = Path("_tmp/patch_savefig_v1b") / path.relative_to(ROOT)
            bak.parent.mkdir(parents=True, exist_ok=True)
            bak.write_text(src, encoding="utf-8")
            path.write_text(new, encoding="utf-8")
    return {"path": str(path), "changed": changed, "mods": mods, "issues": issues}

def main() -> int:
    targets = sorted(Path("zz-scripts").glob("chapter*/plot_*.py"))
    rep = [patch_one(p) for p in targets]
    chg = sum(1 for r in rep if r.get("changed"))
    nop = sum(1 for r in rep if r.get("issues") and "NO_PARSER_DEF" in r["issues"])
    print("# patch_savefig_finalize_v1b — DRY_RUN" if not APPLY else "# patch_savefig_finalize_v1b — APPLY")
    print(f"Targets: {len(targets)} | Changed: {chg} | NO_PARSER_DEF: {nop}")
    print(f"Diffs -> {OUTDIR}/")
    for r in rep[:80]:
        flags = []
        if r.get("mods"): flags.append(f"mods={r['mods']}")
        if r.get("issues"): flags.append(f"issues={r['issues']}")
        print(f"- {r['path']} :: " + ("; ".join(flags) if flags else "OK"))
    return 0

if __name__ == "__main__":
    sys.exit(main())

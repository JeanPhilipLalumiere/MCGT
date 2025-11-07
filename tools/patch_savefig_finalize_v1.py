#!/usr/bin/env python3
from __future__ import annotations
import os, sys, re, difflib, ast
from pathlib import Path
from datetime import datetime

APPLY = os.environ.get("APPLY", "0") == "1"
ROOT = Path(".")
TS = datetime.now().strftime("%Y%m%dT%H%M%SZ")
OUTDIR = Path(f".ci-out/patch_savefig_v1_{TS}")
OUTDIR.mkdir(parents=True, exist_ok=True)

RX_PARSER_DEF   = re.compile(r'^(\s*)(\w+)\s*=\s*argparse\.ArgumentParser\(', re.M)
RX_PARSE_ARGS   = re.compile(r'^\s*args\s*=\s*(\w+)\.parse_args\(\)\s*$', re.M)
RX_HAS_FINALIZE = re.compile(r'\bfinalize_plot_from_args\s*\(\s*args\s*\)')

def collect_top_savefig_locs(src: str) -> list[tuple[int,int,str]]:
    """Retourne [(lineno, end_lineno, literal_or_empty)] pour les plt.savefig top-level."""
    try:
        mod = ast.parse(src)
    except Exception:
        return []
    toplvl_exprs = [n for n in getattr(mod, "body", []) if isinstance(n, ast.Expr)]
    locs: list[tuple[int,int,str]] = []
    for n in toplvl_exprs:
        call = n.value
        if isinstance(call, ast.Call) and isinstance(call.func, ast.Attribute):
            if getattr(call.func.attr, "lower", lambda: "")().lower() == "savefig":
                if isinstance(call.func.value, ast.Name) and call.func.value.id == "plt":
                    # arg0 littéral ?
                    lit = ""
                    if call.args:
                        a0 = call.args[0]
                        if isinstance(a0, ast.Constant) and isinstance(a0.value, str):
                            lit = a0.value
                    lineno = getattr(n, "lineno", 0)
                    end = getattr(n, "end_lineno", lineno)
                    locs.append((lineno, end, lit))
    return locs

def insert_after(s: str, regex: re.Pattern, payload: str) -> tuple[str,bool]:
    m = list(regex.finditer(s))
    if not m:
        return s, False
    last = m[-1]
    pos = last.end()
    return s[:pos] + ("\n" if not s[pos:pos+1] == "\n" else "") + payload + s[pos:], True

def patch_one(path: Path) -> dict:
    try:
        src = path.read_text(encoding="utf-8", errors="replace")
    except Exception as e:
        return {"path": str(path), "error": f"READ:{e}"}

    mods, issues = [], []
    new = src

    locs = collect_top_savefig_locs(src)
    if not locs:
        return {"path": str(path), "changed": False, "mods": mods, "issues": issues}

    # S'assurer qu'il y a un parser.parse_args() -> 'args'
    if not RX_PARSE_ARGS.search(new):
        m_def = RX_PARSER_DEF.search(new)
        if m_def:
            indent, var = m_def.group(1), m_def.group(2)
            inj = f"{indent}args = {var}.parse_args()\n"
            new, ok = insert_after(new, RX_PARSER_DEF, inj)
            if ok: mods.append("ADD_PARSE_ARGS")
        else:
            issues.append("NO_PARSER_DEF")
            return {"path": str(path), "changed": False, "mods": mods, "issues": issues}

    # Préparer éventuel args.out si savefig avait un littéral
    preferred_out = ""
    for _, _, lit in locs:
        if lit:
            preferred_out = lit
            break

    tail_injections = []
    if preferred_out:
        tail_injections.append(
            "if not getattr(args, 'out', None):\n    args.out = %r\n" % preferred_out
        )

    # Finalize à la fin si absent
    if not RX_HAS_FINALIZE.search(new):
        tail_injections.append("__mcgt_out = finalize_plot_from_args(args)")
        mods.append("ADD_FINALIZE")

    if tail_injections:
        new = new.rstrip() + "\n\n" + "\n".join(tail_injections) + "\n"

    # Commenter les savefig top-level ciblés (idempotent)
    lines = new.splitlines(True)
    def comment_range(lo: int, hi: int):
        for i in range(lo-1, hi):
            if i < 0 or i >= len(lines): continue
            if "mcgt-homog" in lines[i]: continue
            lines[i] = re.sub(r'^', '# [mcgt-homog] ', lines[i], count=1)

    for lineno, end, _ in locs:
        if lineno > 0:
            comment_range(lineno, max(end, lineno))

    patched = "".join(lines)
    changed = patched != src
    if changed:
        diff = "".join(difflib.unified_diff(src.splitlines(True), patched.splitlines(True),
                                            fromfile=str(path), tofile=str(path)+" (patched)"))
        (OUTDIR / (path.name + ".diff")).write_text(diff, encoding="utf-8")
        if APPLY:
            bak = Path("_tmp/patch_savefig_v1") / path.relative_to(ROOT)
            bak.parent.mkdir(parents=True, exist_ok=True)
            bak.write_text(src, encoding="utf-8")
            path.write_text(patched, encoding="utf-8")

    return {"path": str(path), "changed": changed, "mods": mods, "issues": issues}

def main() -> int:
    targets = sorted(Path("zz-scripts").glob("chapter*/plot_*.py"))
    rep = [patch_one(p) for p in targets]
    chg = sum(1 for r in rep if r.get("changed"))
    no_parser = sum(1 for r in rep if "NO_PARSER_DEF" in r.get("issues", []))
    print("# patch_savefig_finalize_v1 — DRY_RUN" if not APPLY else "# patch_savefig_finalize_v1 — APPLY")
    print(f"Targets: {len(targets)} | Changed: {chg} | NO_PARSER_DEF: {no_parser}")
    print(f"Diffs -> {OUTDIR}/")
    for r in rep[:60]:
        flags = []
        if r.get("mods"): flags.append(f"mods={r['mods']}")
        if r.get("issues"): flags.append(f"issues={r['issues']}")
        print(f"- {r['path']} :: " + ("; ".join(flags) if flags else "OK"))
    return 0

if __name__ == "__main__":
    sys.exit(main())

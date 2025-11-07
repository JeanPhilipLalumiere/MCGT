#!/usr/bin/env python3
from __future__ import annotations
import re, sys, difflib, os
from pathlib import Path
from datetime import datetime

APPLY = os.environ.get("APPLY", "0") == "1"
ROOT = Path(".")
TS = datetime.utcnow().strftime("%Y%m%dT%H%M%SZ")
OUTDIR = Path(f".ci-out/patch_cli_v1_{TS}")
OUTDIR.mkdir(parents=True, exist_ok=True)

targets = sorted(Path("zz-scripts").glob("chapter*/plot_*.py"))

RX_HAS_IMPORT = re.compile(r'(?:from\s+_common\.cli\s+import\b|import\s+_common\.cli\b)')
RX_MAIN_GUARD = re.compile(r'if\s+__name__\s*==\s*[\'"]__main__[\'"]\s*:', re.M)
RX_PARSER_DEF = re.compile(r'^(\s*)(\w+)\s*=\s*argparse\.ArgumentParser\(', re.M)
RX_CALL_COMMON= re.compile(r'\badd_common_plot_args\s*\(')
RX_IMPORT_BLOCK= re.compile(r'^(?:\s*from\s+\S+\s+import\s+\S+|\s*import\s+\S+)\s*$', re.M)

def apply_patch(text: str, path: Path) -> tuple[str, dict]:
    issues, mods = [], []
    new = text

    # 1) Import commun
    if not RX_HAS_IMPORT.search(new):
        # Trouver fin du bloc d'import pour insérer juste après
        inserts_at = 0
        m_iter = list(RX_IMPORT_BLOCK.finditer(new))
        if m_iter:
            last = m_iter[-1]
            # étendre à la fin de son paragraphe
            inserts_at = last.end()
            if not new[inserts_at:inserts_at+1].endswith("\n"):
                inserts_at += 0
        import_line = "\nfrom _common.cli import add_common_plot_args, finalize_plot_from_args, init_logging\n"
        new = new[:inserts_at] + import_line + new[inserts_at:]
        mods.append("ADD_IMPORT")

    # 2) Injection add_common_plot_args(parser)
    if not RX_CALL_COMMON.search(new):
        m = RX_PARSER_DEF.search(new)
        if m:
            indent, var = m.group(1), m.group(2)
            insert_point = m.end()
            injection = f"\n{indent}add_common_plot_args({var})\n"
            new = new[:insert_point] + injection + new[insert_point:]
            mods.append("ADD_CALL")
        else:
            issues.append("NO_PARSER_DEF")

    # 3) Garde __main__
    if not RX_MAIN_GUARD.search(new):
        new = new.rstrip() + "\n\nif __name__ == \"__main__\":\n    pass\n"
        mods.append("ADD_MAIN_GUARD")

    return new, {"mods": mods, "issues": issues}

def main():
    report = []
    for p in targets:
        try:
            s = p.read_text(encoding="utf-8", errors="replace")
        except Exception as e:
            report.append({"path": str(p), "error": f"READ:{e}"})
            continue
        patched, meta = apply_patch(s, p)
        changed = (patched != s)
        if changed:
            # diff
            diff = "".join(difflib.unified_diff(s.splitlines(True), patched.splitlines(True),
                                                fromfile=str(p), tofile=str(p)+" (patched)"))
            (OUTDIR / (p.name + ".diff")).write_text(diff, encoding="utf-8")
            if APPLY:
                # sauvegarde simple .bak sous _tmp
                bak = Path("_tmp/patch_cli_v1") / p.relative_to(ROOT)
                bak.parent.mkdir(parents=True, exist_ok=True)
                bak.write_text(s, encoding="utf-8")
                p.write_text(patched, encoding="utf-8")
        report.append({"path": str(p), "changed": changed, **meta})

    # résumé
    add_import = sum(1 for r in report if "ADD_IMPORT" in r.get("mods", []))
    add_call   = sum(1 for r in report if "ADD_CALL" in r.get("mods", []))
    add_guard  = sum(1 for r in report if "ADD_MAIN_GUARD" in r.get("mods", []))
    no_parser  = sum(1 for r in report if "NO_PARSER_DEF" in r.get("issues", []))
    changed_n  = sum(1 for r in report if r.get("changed"))
    print("# patch_cli_common_v1 — DRY_RUN" if not APPLY else "# patch_cli_common_v1 — APPLY")
    print(f"Targets: {len(targets)} | Changed: {changed_n} | +import:{add_import}  +call:{add_call}  +guard:{add_guard}  NO_PARSER_DEF:{no_parser}")
    print(f"Diffs -> {OUTDIR}/")
    # détails (<=60)
    for r in report[:60]:
        flags = []
        for k in ("mods","issues","error"):
            v = r.get(k)
            if v: flags.append(f"{k}={v}")
        print(f"- {r['path']} :: " + ("; ".join(flags) if flags else "OK"))
    return 0

if __name__ == "__main__":
    sys.exit(main())

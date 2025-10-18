#!/usr/bin/env python3
from pathlib import Path
import json, re

ROOT = Path("zz-scripts")
OUT = Path("zz-manifests/sondage_summary.json")

TRIGS_CLI = (
    "parser.add_argument(", "parser.set_defaults(", "args = parser.parse_args(", "parser = argparse.ArgumentParser("
)

def prev_nonempty(lines, i):
    j=i-1
    while j>=0 and lines[j].strip()=="":
        j-=1
    return j

def line_opens_block(s: str) -> bool:
    return s.rstrip().endswith(":") and not s.lstrip().startswith("#")

def scan_file(p: Path) -> dict:
    txt = p.read_text(encoding="utf-8", errors="ignore")
    lines = txt.splitlines(True)
    has_savefig = bool(re.search(r"\.savefig\s*\(", txt))
    has_ax_table = "ax.table(" in txt or "ax_tab.table(" in txt
    guarded_table = ("except IndexError" in txt) or ("safe_make_table" in txt)
    uses_postparse = ("_common.postparse" in txt) or ("ensure_std_args(" in txt)
    has_cli = any(t in txt for t in TRIGS_CLI)
    has_main_guard = ("__name__" in txt and "__main__" in txt)
    # suspects d'indentation toplevel
    indent_suspects = []
    for i, raw in enumerate(lines):
        if raw[:1].isspace():
            ls = raw.lstrip()
            if any(ls.startswith(t) for t in TRIGS_CLI) or ls.startswith(("import ", "from ", "def ", "class ")):
                j = prev_nonempty(lines, i)
                prev = lines[j] if j>=0 else ""
                if not line_opens_block(prev):
                    indent_suspects.append(i+1)
    indents = [raw[:len(raw)-len(raw.lstrip(' \t'))] for raw in lines if raw[:1].isspace()]
    mix_tabs_spaces = any('\t' in i and ' ' in i for i in indents)
    return {
        "path": str(p),
        "has_savefig": has_savefig,
        "has_ax_table": has_ax_table,
        "guarded_table": guarded_table if has_ax_table else True,
        "uses_postparse": uses_postparse,
        "has_cli": has_cli,
        "has_main_guard": has_main_guard,
        "indent_suspects": indent_suspects[:30],
        "indent_suspects_count": len(indent_suspects),
        "mix_tabs_spaces": mix_tabs_spaces,
    }

def main():
    files = sorted([p for p in ROOT.rglob("*.py") if p.is_file()])
    res = [scan_file(p) for p in files]
    OUT.parent.mkdir(parents=True, exist_ok=True)
    OUT.write_text(json.dumps(res, indent=2, ensure_ascii=False), encoding="utf-8")
    total = len(res)
    cli_bad = sum(1 for r in res if r["indent_suspects_count"]>0)
    unguarded = sum(1 for r in res if r["has_ax_table"] and not r["guarded_table"])
    no_postparse = sum(1 for r in res if r["has_cli"] and not r["uses_postparse"])
    mix = sum(1 for r in res if r["mix_tabs_spaces"])
    print(f"[SCAN] {total} fichiers .py")
    print(f"- indent_suspects>0 : {cli_bad}")
    print(f"- ax.table non gardé : {unguarded}")
    print(f"- CLI sans ensure_std_args : {no_postparse}")
    print(f"- mix tabs/espaces : {mix}")
    print("\n[Top suspects]")
    for r in sorted(res, key=lambda r: r["indent_suspects_count"], reverse=True)[:10]:
        if r["indent_suspects_count"]==0: break
        print(f"* {r['path']}  (suspects={r['indent_suspects_count']}, mix_tabs_spaces={r['mix_tabs_spaces']})")

if __name__ == "__main__":
    main()

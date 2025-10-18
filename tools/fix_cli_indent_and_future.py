#!/usr/bin/env python3
from pathlib import Path
import json, re, sys

AUDIT = Path("zz-manifests/audit_sweep.json")
TRIGS = ("parser.add_argument(", "parser.set_defaults(", "args = parser.parse_args(")

def prev_code_line(lines, i):
    j = i-1
    while j >= 0 and lines[j].strip() == "":
        j -= 1
    return j

def fix_unexpected_indent_cli(p: Path) -> bool:
    """Dé-dente au toplevel les lignes CLI si la ligne précédente n'ouvre pas un bloc."""
    txt = p.read_text(encoding="utf-8", errors="ignore")
    lines = txt.splitlines(True)
    changed = False
    for i, raw in enumerate(lines):
        if raw[:1].isspace():
            ls = raw.lstrip()
            if ls.startswith(TRIGS):
                j = prev_code_line(lines, i)
                prev = lines[j].rstrip("\n") if j >= 0 else ""
                opens = prev.rstrip().endswith(":")
                if not opens:
                    # dé-dente cette ligne uniquement
                    lines[i] = ls
                    changed = True
    if changed:
        p.with_suffix(p.suffix + ".bak_cliindent").write_text(txt, encoding="utf-8")
        p.write_text("".join(lines), encoding="utf-8")
    return changed

def move_future_imports_top(p: Path) -> bool:
    """Remonte les 'from __future__ import ...' au tout début (après shebang + docstring)."""
    src = p.read_text(encoding="utf-8", errors="ignore")
    lines = src.splitlines(True)
    if not any("from __future__ import" in l for l in lines):
        return False

    i = 0
    # shebang
    if i < len(lines) and lines[i].startswith("#!"):
        i += 1
    # en-têtes encodage/commentaires vides
    while i < len(lines) and (lines[i].strip() == "" or lines[i].lstrip().startswith("#")):
        i += 1
    # docstring module
    def is_triple_quote(s): return s.lstrip().startswith(('"""',"'''"))
    if i < len(lines) and is_triple_quote(lines[i]):
        quote = lines[i].lstrip()[:3]
        i += 1
        while i < len(lines):
            if quote in lines[i]:
                i += 1
                break
            i += 1

    # collecter futures partout
    futures = []
    keep = []
    for l in lines:
        if re.match(r'\s*from\s+__future__\s+import\s+', l):
            if l not in futures:
                futures.append(l)
        else:
            keep.append(l)
    if not futures:
        return False

    # reconstruire : head(0..i) + futures + reste sans futures
    head = keep[:i]
    tail = keep[i:]
    # éviter doublons / conserver fin de ligne
    fut_block = [f if f.endswith("\n") else f + "\n" for f in futures]
    new = "".join(head + fut_block + tail)
    if new != src:
        p.with_suffix(p.suffix + ".bak_future").write_text(src, encoding="utf-8")
        p.write_text(new, encoding="utf-8")
        return True
    return False

def main():
    if not AUDIT.exists():
        print("[ERR] audit_sweep.json manquant : lancez tools/mcgt_sweeper.py d'abord.", file=sys.stderr)
        sys.exit(2)
    d = json.loads(AUDIT.read_text(encoding="utf-8"))
    # cibler d'abord les fichiers avec 'unexpected indent'
    targets = [f["path"] for f in d.get("files", []) if f.get("msg") == "unexpected indent"]
    changed_cli = 0
    for t in targets:
        p = Path(t)
        if p.suffix == ".py" and p.exists():
            if fix_unexpected_indent_cli(p):
                changed_cli += 1
    # corriger les imports __future__ dans tout le dépôt (peu coûteux)
    changed_future = 0
    for p in Path("zz-scripts").rglob("*.py"):
        if move_future_imports_top(p):
            changed_future += 1
    print(f"[OK] CLI dedented in {changed_cli} file(s); future imports normalized in {changed_future} file(s)")
if __name__ == "__main__":
    main()

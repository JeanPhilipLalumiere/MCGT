#!/usr/bin/env python3
from pathlib import Path
import json, sys

AUDIT = Path("zz-manifests/audit_sweep.json")

def prev_nonempty(lines, i):
    j = i - 1
    while j >= 0 and lines[j].strip() == "":
        j -= 1
    return j

def heal_file(p: Path) -> bool:
    src = p.read_text(encoding="utf-8", errors="ignore")
    lines = src.splitlines(True)
    changed = False
    # suivi de la profondeur de parenthèses/crochets/accolades
    bracket = 0

    for i, raw in enumerate(lines):
        # mettre à jour bracket avec la ligne précédente (contexte de continuation)
        if i > 0:
            prev = lines[i-1]
            in_str = None
            for c in prev:
                if in_str:
                    if c == in_str:
                        in_str = None
                else:
                    if c in ("'", '"'):
                        in_str = c
                    elif c in "([{":
                        bracket += 1
                    elif c in ")]}":
                        bracket = max(0, bracket - 1)
        # ligne courante
        if raw.strip() == "":
            continue
        ls = raw.lstrip()
        prev_i = prev_nonempty(lines, i)
        prev_line = lines[prev_i].rstrip("\n") if prev_i >= 0 else ""
        prev_opens = prev_line.rstrip().endswith(":") and not prev_line.lstrip().startswith("#")

        # Cas à soigner : indentation au niveau module, hors bloc ouvert, hors continuation
        if raw[:1].isspace() and not prev_opens and bracket == 0:
            # on dé-dente la ligne
            if ls != raw:
                lines[i] = ls
                changed = True

    if changed:
        p.with_suffix(p.suffix + ".bak_healindent").write_text(src, encoding="utf-8")
        p.write_text("".join(lines), encoding="utf-8")
    return changed

def main():
    if not AUDIT.exists():
        print("[ERR] audit_sweep.json manquant. Lancez d'abord tools/mcgt_sweeper.py.", file=sys.stderr)
        sys.exit(2)
    d = json.loads(AUDIT.read_text(encoding="utf-8"))
    targets = [f["path"] for f in d.get("files", []) if f.get("type")=="SyntaxError" and "unexpected indent" in f.get("msg","")]
    changed = 0
    for t in targets:
        p = Path(t)
        if p.suffix == ".py" and p.exists():
            if heal_file(p):
                changed += 1
    print(f"[OK] healed unexpected indent in {changed} file(s)")
if __name__ == "__main__":
    main()

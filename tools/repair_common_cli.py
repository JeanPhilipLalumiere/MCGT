#!/usr/bin/env python3
import argparse as _argparse, ast, sys
from pathlib import Path

TARGET = Path("zz-scripts/_common/cli.py")
TRIGS = (
    "parser = argparse.ArgumentParser(",
    "parser.add_argument(",
    "parser.set_defaults(",
    "args = parser.parse_args(",
)

def prev_nonempty(lines, i):
    j = i-1
    while j >= 0 and lines[j].strip()=="":
        j -= 1
    return j

def opens_block(s: str) -> bool:
    s = s.rstrip()
    return s.endswith(":") and not s.lstrip().startswith("#")

def bracket_depth_upto(text: str) -> int:
    depth = 0; in_str = None; esc = False
    for ch in text:
        if in_str:
            if esc: esc = False
            elif ch == "\\": esc = True
            elif ch == in_str: in_str = None
            continue
        if ch in ("'", '"'): in_str = ch
        elif ch in "([{": depth += 1
        elif ch in ")]}": depth = max(0, depth-1)
    return depth

def compiles_ok(src: str) -> bool:
    try:
        ast.parse(src); return True
    except Exception:
        return False

def main():
    ap = _argparse.ArgumentParser()
    ap.add_argument("--apply", action="store_true", help="appliquer la correction (sinon dry-run)")
    ap.add_argument("--context", type=int, default=8, help="lignes de contexte à afficher")
    args = ap.parse_args()

    if not TARGET.exists():
        print(f"[ERR] introuvable: {TARGET}", file=sys.stderr); sys.exit(2)

    text = TARGET.read_text(encoding="utf-8", errors="ignore")
    lines = text.splitlines(True)
    changed_ix = []

    print(f"[INFO] Sondage {TARGET} (lignes={len(lines)})")
    for i, raw in enumerate(lines):
        ls = raw.lstrip()
        if not raw[:1].isspace():
            continue
        if not any(ls.startswith(t) for t in TRIGS):
            continue
        j = prev_nonempty(lines, i)
        prev = lines[j] if j >= 0 else ""
        safe = (not opens_block(prev)) and (bracket_depth_upto(prev) == 0) and (j < 0 or not lines[j][:1].isspace())

        # contexte
        a, b = max(0, i-args.context), min(len(lines), i+args.context+1)
        print(f"\n--- contexte autour de la ligne {i+1} ---")
        for k in range(a, b):
            mark = ">>" if k == i else "  "
            print(f"{mark} {k+1:4d}: {lines[k].rstrip()}")

        if safe:
            changed_ix.append(i)

    if not changed_ix:
        print("\n[OK] Rien à corriger selon les garde-fous."); return

    print(f"\n[DRY-RUN] Candidats à dé-denter: { [ix+1 for ix in changed_ix] }")
    if not args.apply:
        return

    # apply
    bak = TARGET.with_suffix(TARGET.suffix + ".bak_cli_v3")
    if not bak.exists():
        bak.write_text(text, encoding="utf-8")

    for i in changed_ix:
        lines[i] = lines[i].lstrip()

    new_src = "".join(lines)
    if not compiles_ok(new_src):
        print("[ERR] La compilation échoue après patch — restauration backup.", file=sys.stderr)
        TARGET.write_text(bak.read_text(encoding="utf-8"), encoding="utf-8")
        sys.exit(1)

    TARGET.write_text(new_src, encoding="utf-8")
    print(f"[APPLY] Dé-dent appliqué sur {len(changed_ix)} ligne(s) → backup: {bak}")

if __name__ == "__main__":
    main()

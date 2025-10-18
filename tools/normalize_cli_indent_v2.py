#!/usr/bin/env python3
import argparse, ast
from pathlib import Path

TRIGS = (
    "parser = argparse.ArgumentParser(",
    "parser.add_argument(",
    "parser.set_defaults(",
    "args = parser.parse_args(",
)

def prev_nonempty(lines, i):
    j = i - 1
    while j >= 0 and lines[j].strip() == "":
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
        elif ch in ")]}": depth = max(0, depth - 1)
    return depth

def compiles_ok(p: Path) -> bool:
    try:
        src = p.read_text(encoding="utf-8", errors="ignore")
        ast.parse(src)
        return True
    except Exception:
        return False

def should_dedent(lines, i) -> bool:
    raw = lines[i]
    if not raw[:1].isspace():
        return False
    ls = raw.lstrip()
    if not ls.startswith(TRIGS):
        return False
    j = prev_nonempty(lines, i)
    prev = lines[j] if j >= 0 else ""
    # sécurité : pas dans un bloc en cours, ni une continuation de parenthèses
    if opens_block(prev): return False
    if bracket_depth_upto(prev) != 0: return False
    # top-level heuristique : ligne précédente non indentée (ou inexistante)
    if j >= 0 and lines[j][:1].isspace():
        return False
    return True

def process_file(p: Path, apply: bool):
    text = p.read_text(encoding="utf-8", errors="ignore")
    lines = text.splitlines(True)
    changed_ix = []
    for i in range(len(lines)):
        if should_dedent(lines, i):
            lines[i] = lines[i].lstrip()
            changed_ix.append(i+1)  # human line numbers
    if not changed_ix:
        return False, []
    if not apply:
        return True, changed_ix
    # backup + write + compile-check
    bak = p.with_suffix(p.suffix + ".bak_cli_v2")
    if not bak.exists():
        bak.write_text(text, encoding="utf-8")
    p.write_text("".join(lines), encoding="utf-8")
    if not compiles_ok(p):
        # revert
        p.write_text(bak.read_text(encoding="utf-8"), encoding="utf-8")
        return False, []
    return True, changed_ix

def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--apply", action="store_true", help="appliquer les corrections (sinon dry-run)")
    ap.add_argument("--limit-to", nargs="*", help="fichiers/dirs spécifiques", default=None)
    args = ap.parse_args()

    targets = []
    roots = [Path(".")] if not args.limit_to else [Path(x) for x in args.limit_to]
    for r in roots:
        if r.is_file() and r.suffix == ".py":
            targets.append(r)
        else:
            targets += list(r.rglob("*.py"))

    touched = 0; files = 0
    details = []
    for p in sorted(set(targets)):
        ok, ix = process_file(p, args.apply)
        if ix:
            files += 1
            touched += len(ix)
            details.append((str(p), ix))
    mode = "APPLY" if args.apply else "DRY-RUN"
    print(f"[{mode}] fichiers touchés: {files} ; lignes modifiées: {touched}")
    for path, ix in details[:50]:
        print(f"- {path}: {len(ix)} ligne(s) → {ix[:8]}{'...' if len(ix)>8 else ''}")

if __name__ == "__main__":
    main()

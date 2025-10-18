#!/usr/bin/env python3
import sys, re
from pathlib import Path

WS = re.compile(r'^([ \t]*)')
def indent_of(s: str) -> str:
    m = WS.match(s)
    return m.group(1) if m else ""

def dedent_block_after_line(p: Path, start_lineno: int) -> None:
    lines = p.read_text(encoding="utf-8").splitlines(True)
    i = start_lineno - 1
    if not (0 <= i < len(lines)):
        print(f"[SKIP] {p}: ligne {start_lineno} hors fichier")
        return

    base_indent = indent_of(lines[i])
    if base_indent == "":
        print(f"[INFO] {p}: ligne {start_lineno} déjà non indentée")
        return

    b = len(base_indent)
    j = i
    # Dé-dente les lignes du bloc courant (tant qu’au moins aussi indentées)
    while j < len(lines):
        s = lines[j]
        ind = indent_of(s)
        stripped = s.strip()
        if stripped == "":
            # ligne vide → on la dé-dente aussi (si assez d’indent) et continue
            if len(ind) >= b:
                lines[j] = s[b:]
                j += 1
                continue
            else:
                break
        if len(ind) >= b:
            if len(ind) == b and stripped.startswith(("except", "finally:")):
                # Supprime le except/finally orphelin + son bloc associé
                k = j + 1
                while k < len(lines):
                    indk = indent_of(lines[k])
                    if lines[k].strip() == "":
                        k += 1
                        continue
                    if len(indk) <= b:
                        break
                    k += 1
                del lines[j:k]
                print(f"[FIX] removed orphan handler at line {j+1}")
                break
            # dé-dente d’un niveau (exactement base_indent)
            lines[j] = s[b:]
            j += 1
            continue
        else:
            break

    p.write_text("".join(lines), encoding="utf-8")
    print(f"[FIX] dedented block starting at line {start_lineno} by {b} chars")

def main():
    if len(sys.argv) != 3:
        print("usage: tools/dedent_block_after_orphan_try.py FILE LINENO", file=sys.stderr)
        sys.exit(2)
    path = Path(sys.argv[1])
    lineno = int(sys.argv[2])
    if not path.exists():
        print(f"[ERR] not found: {path}", file=sys.stderr); sys.exit(2)

    # sauvegarde
    bak = path.with_suffix(path.suffix + ".bak_dedent")
    if not bak.exists():
        bak.write_text(path.read_text(encoding="utf-8"), encoding="utf-8")

    dedent_block_after_line(path, lineno)

    # compile à blanc
    try:
        compile(path.read_text(encoding="utf-8"), str(path), "exec")
        print("[OK ] compile passed")
    except SyntaxError as e:
        print(f"[KO ] {type(e).__name__}: {e}")

if __name__ == "__main__":
    main()

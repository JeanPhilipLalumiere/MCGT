#!/usr/bin/env python3
import sys
from pathlib import Path

def compile_for_indent(p: Path):
    try:
        compile(p.read_text(encoding="utf-8"), str(p), "exec")
        return True, None
    except IndentationError as e:
        return False, e
    except Exception:
        # pas une erreur d'indentation bloquante → on laisse tel quel
        return True, None

def dedent_once(p: Path, lineno: int) -> bool:
    lines = p.read_text(encoding="utf-8").splitlines(True)
    if 1 <= lineno <= len(lines):
        # retire tout le préfixe blanc (tabs/espaces) de cette ligne
        lines[lineno-1] = lines[lineno-1].lstrip()
        p.write_text("".join(lines), encoding="utf-8")
        return True
    return False

def fix_file(p: Path):
    if not p.exists():
        print(f"[SKIP] not found: {p}")
        return
    bak = p.with_suffix(p.suffix + ".bak")
    if not bak.exists():
        bak.write_text(p.read_text(encoding="utf-8"), encoding="utf-8")
    seen = set()
    fixed = 0
    for _ in range(999):
        ok, err = compile_for_indent(p)
        if ok:
            break
        ln = getattr(err, "lineno", None)
        if ln is None or ln in seen:
            print(f"[STOP] {p}: blocage (lineno={ln}); vérif manuelle conseillée")
            break
        if dedent_once(p, ln):
            fixed += 1
            seen.add(ln)
            print(f"[FIX] {p}:{ln} → dé-denté")
        else:
            print(f"[ERR] {p}: impossible de dé-denter ligne {ln}")
            break
    if fixed == 0:
        print(f"[OK ] {p}: pas d'indentation bloquante")
    else:
        print(f"[DONE] {p}: {fixed} ligne(s) corrigée(s)")

def main(argv):
    if len(argv) < 2:
        print("usage: fix_indent_auto.py FILE [FILE...]", file=sys.stderr)
        return 2
    for a in argv[1:]:
        fix_file(Path(a))
    return 0

if __name__ == "__main__":
    sys.exit(main(sys.argv))

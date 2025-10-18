#!/usr/bin/env python3
import ast, sys
from pathlib import Path

def compiles_ok(p: Path) -> bool:
    try:
        src = p.read_text(encoding="utf-8", errors="ignore")
        ast.parse(src)
        return True
    except Exception:
        return False

def main():
    root = Path(".")
    backups = list(root.rglob("*.bak_cli_dedent"))
    restored = 0
    skipped_ok = 0
    for bak in backups:
        orig = Path(str(bak).replace(".bak_cli_dedent", ""))
        if not orig.exists():
            continue
        cur_ok = compiles_ok(orig)
        bak_ok = compiles_ok(bak)
        if cur_ok:
            skipped_ok += 1
            continue
        if (not cur_ok) and bak_ok:
            orig.write_text(bak.read_text(encoding="utf-8"), encoding="utf-8")
            restored += 1
            print(f"[RESTORE] {orig}")
        else:
            # ni l’un ni l’autre ne compilent → on ne touche pas
            print(f"[KEEP] {orig} (current_ok={cur_ok}, backup_ok={bak_ok})")
    print(f"[SUMMARY] restored={restored}, kept_ok={skipped_ok}, backups={len(backups)}")

if __name__ == "__main__":
    main()

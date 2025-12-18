#!/usr/bin/env python3
from __future__ import annotations
import os, sys
from pathlib import Path

def normalize_file(p: Path, root: Path) -> bool:
    changed = False
    out_lines = []
    for raw in p.read_text(encoding="utf-8", errors="replace").splitlines(True):
        line = raw.rstrip("\n")
        if not line.strip():
            out_lines.append(raw)
            continue
        parts = line.split()
        if len(parts) < 2:
            out_lines.append(raw)
            continue
        h = parts[0]
        path = parts[-1]
        if os.path.isabs(path):
            rel = os.path.relpath(path, root)
            rel = rel.replace("\\", "/")
            new = f"{h}  {rel}\n"
            out_lines.append(new)
            changed |= (new != raw)
        else:
            out_lines.append(raw)
    if changed:
        p.write_text("".join(out_lines), encoding="utf-8")
    return changed

def main(argv: list[str]) -> int:
    root = Path(os.environ.get("GIT_TOP", "")) if os.environ.get("GIT_TOP") else None
    if not root or not root.exists():
        root = Path(os.popen("git rev-parse --show-toplevel").read().strip())
    if not root.exists():
        print("[ERR] root repo introuvable", file=sys.stderr)
        return 2

    paths = []
    for a in argv[1:]:
        if "*" in a or "?" in a:
            paths.extend([Path(x) for x in sorted(Path().glob(a))])
        else:
            paths.append(Path(a))

    if not paths:
        print("[ERR] aucun fichier fourni", file=sys.stderr)
        return 2

    any_changed = False
    for p in paths:
        if p.is_file():
            any_changed |= normalize_file(p, root)
    print("[OK] normalize done; changed =", any_changed)
    return 0

if __name__ == "__main__":
    raise SystemExit(main(sys.argv))

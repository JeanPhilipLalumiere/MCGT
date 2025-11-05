#!/usr/bin/env python3
import re
import sys
from pathlib import Path


def process(p: Path) -> bool:
    L = p.read_text(encoding="utf-8", errors="ignore").splitlines(True)

    has_import = any("import matplotlib.pyplot as plt" in s for s in L)
    has_axdef = any(re.search(r"\b(fig,\s*ax|ax)\s*=", s) for s in L)

    # Trouver première utilisation de ax.
    ax_use_idx = next((i for i, s in enumerate(L) if re.search(r"\bax\.", s)), None)
    if ax_use_idx is None:
        print("[OK] no ax.* usage in", p)
        return False

    # Chercher si fig/ax défini avant cette position
    has_ax_before = any(re.search(r"\b(fig,\s*ax|ax)\s*=", s) for s in L[:ax_use_idx])
    if has_ax_before:
        print("[OK] fig/ax already defined before first use in", p)
        return False

    # Point d’insertion: après le dernier import/docstring/shebang
    ins = 0
    if L and L[0].startswith("#!"):
        ins = 1
    # sauter docstring éventuel
    if ins < len(L) and L[ins].lstrip().startswith(("'''", '"""')):
        q = L[ins].lstrip()[:3]
        ins += 1
        while ins < len(L) and q not in L[ins]:
            ins += 1
        if ins < len(L):
            ins += 1
    # sauter les imports initiaux
    while ins < len(L) and L[ins].lstrip().startswith(("import ", "from ")):
        ins += 1

    lines_to_insert = []
    if not has_import:
        lines_to_insert.append("import matplotlib.pyplot as plt\n")
    lines_to_insert.append("fig, ax = plt.subplots()\n")
    L[ins:ins] = lines_to_insert

    p.write_text("".join(L), encoding="utf-8")
    print(f"[FIX] inserted fig, ax init in {p} at L{ins+1}")
    return True


if __name__ == "__main__":
    for arg in sys.argv[1:]:
        process(Path(arg))

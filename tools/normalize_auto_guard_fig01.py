#!/usr/bin/env python3
from pathlib import Path
import sys, re

if len(sys.argv) != 2:
    print("usage: normalize_auto_guard_fig01.py FILE", file=sys.stderr); sys.exit(2)
F = Path(sys.argv[1])
text = F.read_text(encoding="utf-8")
lines = text.splitlines(True)

# repère tous les démarreurs/finisseurs d'auto-guard
start_ix = [i for i,l in enumerate(lines) if l.lstrip().startswith("# --- auto-guard")]
end_ix   = [i for i,l in enumerate(lines) if l.lstrip().startswith("# --- end auto-guard")]

if not start_ix or not end_ix or start_ix[0] > end_ix[-1]:
    print("[NOTE] aucun bloc auto-guard à normaliser (ou repères incohérents).")
    sys.exit(0)

i0, i1 = start_ix[0], end_ix[-1]  # remplace du premier start au dernier end (inclus)

canonical = (
    "# --- auto-guard (canonical) ---\n"
    "if \"df\" not in globals():\n"
    "    import pandas as _pd, sys as _sys\n"
    "    _res = None\n"
    "    try:\n"
    "        _res = args.results\n"
    "    except Exception:\n"
    "        for _j, _a in enumerate(_sys.argv):\n"
    "            if _a == \"--results\" and _j + 1 < len(_sys.argv):\n"
    "                _res = _sys.argv[_j + 1]\n"
    "                break\n"
    "    if _res is None:\n"
    "        raise RuntimeError(\"Cannot infer --results (fig01)\")\n"
    "    df = _pd.read_csv(_res)\n"
    "# --- end auto-guard ---\n"
)

new_lines = lines[:i0] + [canonical] + lines[i1+1:]
bak = F.with_suffix(F.suffix + ".bak_guardnorm")
if not bak.exists():
    bak.write_text(text, encoding="utf-8")
F.write_text("".join(new_lines), encoding="utf-8")
print(f"[OK] auto-guard normalisé dans {F}")

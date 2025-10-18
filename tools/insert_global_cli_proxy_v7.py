#!/usr/bin/env python3
from pathlib import Path

# Fichiers ciblés (ajoute-en ici si besoin)
FILES = [
    Path("zz-scripts/chapter10/plot_fig03b_bootstrap_coverage_vs_n.py"),
    Path("zz-scripts/chapter10/plot_fig06_residual_map.py"),
]

SENTINEL = "# --- cli global proxy v7 ---"

# Défauts raisonnables pour ce chapitre (utilisés si non passés en CLI et non déjà présents)
COMMON_DEFAULTS = {
    # déjà rencontrés ou probables
    "p95_col": None,
    "m1_col": "phi0",
    "m2_col": "phi_ref_fpeak",

    # manquants vus dans tes logs récents
    "hires2000": False,
    "metric": "dp95",

    # déjà apparus plus tôt
    "mincnt": 1,
    "gridsize": 60,
    "figsize": "8,6",
    "dpi": 300,

    "title": "",
    "title_left": "",
    "title_right": "",

    "hist_x": 0,
    "hist_y": 0,
    "hist_scale": 1.0,

    "with_zoom": False,
    "zoom_x": None, "zoom_y": None, "zoom_dx": None, "zoom_dy": None,
    "zoom_center_n": None,

    "cmap": "viridis",
    "point_size": 10,

    # seuils / options souvent utiles
    "threshold": 0.0,
}

def insert_after_imports(path: Path, block: str) -> bool:
    s = path.read_text(encoding="utf-8")
    if SENTINEL in s:
        return False
    lines = s.splitlines(True)

    i = 0
    # shebang
    if i < len(lines) and lines[i].startswith("#!"):
        i += 1
    # blancs & commentaires
    while i < len(lines) and (lines[i].strip() == "" or lines[i].lstrip().startswith("#")):
        i += 1
    # docstring éventuelle
    if i < len(lines) and lines[i].lstrip().startswith(("'''", '"""')):
        q = lines[i].lstrip()[:3]
        i += 1
        while i < len(lines):
            if lines[i].strip().endswith(q):
                i += 1
                break
            i += 1
    # __future__ imports
    while i < len(lines) and lines[i].lstrip().startswith("from __future__ import"):
        i += 1
    # imports classiques (import/from)
    last = i
    while i < len(lines) and lines[i].lstrip().startswith(("import ", "from ")):
        last = i + 1
        i += 1

    lines.insert(last, block)
    path.write_text("".join(lines), encoding="utf-8")
    return True

def build_block():
    b = []
    b.append(SENTINEL + "\n")
    b.append("import sys as _sys, types as _types, re as _re\n")
    b.append("try:\n")
    b.append("    args  # noqa: F821  # peut ne pas exister\n")
    b.append("except NameError:\n")
    b.append("    args = _types.SimpleNamespace()\n\n")

    # table des défauts
    b.append("_COMMON_DEFAULTS = {\n")
    for k, v in COMMON_DEFAULTS.items():
        # sérialise proprement les valeurs Python
        if isinstance(v, str):
            b.append(f"    '{k}': {v!r},\n")
        else:
            b.append(f"    '{k}': {v},\n")
    b.append("}\n\n")

    # extraction CLI (--foo et --foo=bar, --no-foo -> False, flag seul -> True)
    b.append("def _v7_from_argv(flag_name: str):\n")
    b.append("    flag = '--' + flag_name.replace('_','-')\n")
    b.append("    for i,a in enumerate(_sys.argv):\n")
    b.append("        if a == flag and i+1 < len(_sys.argv):\n")
    b.append("            return _sys.argv[i+1]\n")
    b.append("        if a.startswith(flag + '='):\n")
    b.append("            return a.split('=',1)[1]\n")
    b.append("        if a == flag:\n")
    b.append("            return True\n")
    b.append("        if a == '--no-' + flag_name.replace('_','-'):\n")
    b.append("            return False\n")
    b.append("    return None\n\n")

    # cast simple
    b.append("def _v7_cast(val):\n")
    b.append("    if isinstance(val, (bool, int, float)) or val is None:\n")
    b.append("        return val\n")
    b.append("    s = str(val)\n")
    b.append("    sl = s.lower()\n")
    b.append("    if sl in ('true','yes','y','1'): return True\n")
    b.append("    if sl in ('false','no','n','0'): return False\n")
    b.append("    try:\n")
    b.append("        if any(ch in s for ch in ('.','e','E')):\n")
    b.append("            return float(s)\n")
    b.append("        return int(s)\n")
    b.append("    except Exception:\n")
    b.append("        return s\n\n")

    # proxy
    b.append("class _ArgsProxy:\n")
    b.append("    def __init__(self, base):\n")
    b.append("        object.__setattr__(self, '_base', base)\n")
    b.append("    def __getattr__(self, name):\n")
    b.append("        if hasattr(self._base, name):\n")
    b.append("            return getattr(self._base, name)\n")
    b.append("        v = _v7_from_argv(name)\n")
    b.append("        if v is None:\n")
    b.append("            v = _COMMON_DEFAULTS.get(name, None)\n")
    b.append("        else:\n")
    b.append("            v = _v7_cast(v)\n")
    b.append("        setattr(self._base, name, v)\n")
    b.append("        return v\n")
    b.append("    def __setattr__(self, name, value):\n")
    b.append("        if name == '_base':\n")
    b.append("            object.__setattr__(self, name, value)\n")
    b.append("        else:\n")
    b.append("            setattr(self._base, name, value)\n")
    b.append("args = _ArgsProxy(args)\n")
    b.append("# --- end cli global proxy v7 ---\n")
    return "".join(b)

def main():
    block = build_block()
    changed_any = False
    for p in FILES:
        if not p.exists(): 
            print(f"[MISS] {p}")
            continue
        if insert_after_imports(p, block):
            print(f"[PATCH] proxy v7 inserted -> {p}")
            changed_any = True
        else:
            print(f"[OK] proxy v7 already present -> {p}")
    if not changed_any:
        print("[NOTE] nothing to do")

if __name__ == "__main__":
    main()

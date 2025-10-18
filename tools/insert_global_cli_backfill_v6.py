#!/usr/bin/env python3
from pathlib import Path

FILES = {
    "plot_fig03b_bootstrap_coverage_vs_n.py": [("p95_col", "None")],
    "plot_fig06_residual_map.py": [
        ("m1_col", "'phi0'"),
        ("m2_col", "'phi_ref_fpeak'"),
    ],
}

SENTINEL = "# --- cli global backfill v6 ---"

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
    # imports classiques (import / from) — on s’arrête au premier non-import
    last = i
    while i < len(lines) and lines[i].lstrip().startswith(("import ", "from ")):
        last = i + 1
        i += 1

    lines.insert(last, block)
    path.write_text("".join(lines), encoding="utf-8")
    return True

def build_block(pairs):
    body = []
    body.append(SENTINEL + "\n")
    body.append("import sys as _sys, types as _types\n")
    body.append("try:\n")
    body.append("    args  # noqa: F821  # peut ne pas exister\n")
    body.append("except NameError:\n")
    body.append("    args = _types.SimpleNamespace()\n")
    body.append("\n")
    body.append("def _v6_arg_or_default(flag: str, default):\n")
    body.append("    # priorité au CLI si présent (sans supposer que le parser connaît le flag)\n")
    body.append("    for _j, _a in enumerate(_sys.argv):\n")
    body.append("        if _a == flag and _j + 1 < len(_sys.argv):\n")
    body.append("            return _sys.argv[_j + 1]\n")
    body.append("    return default\n")
    body.append("\n")
    for attr, pyval in pairs:
        flag = "--" + attr.replace("_", "-")
        body.append(f"if not hasattr(args, '{attr}'):\n")
        body.append(f"    args.{attr} = _v6_arg_or_default('{flag}', {pyval})\n")
    body.append("# --- end cli global backfill v6 ---\n")
    return "".join(body)

def main():
    root = Path("zz-scripts/chapter10")
    changed_any = False
    for rel, pairs in FILES.items():
        p = root / rel
        if not p.exists():
            print(f"[MISS] {p}")
            continue
        block = build_block(pairs)
        changed = insert_after_imports(p, block)
        if changed:
            bak = p.with_suffix(p.suffix + ".bak_global_v6")
            if not bak.exists():
                bak.write_text(p.read_text(encoding="utf-8"), encoding="utf-8")
            print(f"[PATCH] global backfill v6 inserted -> {p}")
            changed_any = True
        else:
            print(f"[OK] global backfill v6 already present -> {p}")
    if not changed_any:
        print("[NOTE] nothing to do")

if __name__ == "__main__":
    main()

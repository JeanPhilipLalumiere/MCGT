#!/usr/bin/env python3
from pathlib import Path

def insert_after_imports(path: Path, block: str, sentinel: str) -> bool:
    s = path.read_text(encoding="utf-8")
    if sentinel in s:
        return False
    lines = s.splitlines(True)

    i = 0
    # shebang
    if i < len(lines) and lines[i].startswith("#!"): i += 1
    # blancs & commentaires
    while i < len(lines) and (lines[i].strip()=="" or lines[i].lstrip().startswith("#")): i += 1
    # docstring éventuelle
    if i < len(lines) and lines[i].lstrip().startswith(("'''",'\"\"\"')):
        q = lines[i].lstrip()[:3]; i += 1
        while i < len(lines):
            if lines[i].strip().endswith(q): i += 1; break
            i += 1
    # __future__ imports
    while i < len(lines) and lines[i].lstrip().startswith("from __future__ import"): i += 1
    # imports classiques (import/from)
    last = i
    while i < len(lines) and lines[i].lstrip().startswith(("import ","from ")):
        last = i + 1; i += 1

    lines.insert(last, block)
    path.write_text("".join(lines), encoding="utf-8")
    return True

PATCH = """
# --- compat: argparse post-parse shim v3 ---
import argparse as _argparse

def _mcgt__augment(ns):
    # Valeurs par défaut sûres pour chap.10 (complète *sans écraser* l'existant)
    defaults = {
        "p95_col": None,                 # auto-détection si None
        "m1_col": "phi0",
        "m2_col": "phi_ref_fpeak",
        "ymin_coverage": None,
        "ymax_coverage": None,
        "mincnt": 1,
        "gridsize": 60,
        "figsize": None,
        "hist_x": 0,                     # fig04
        "hist_y": 0,
    }
    for k, v in defaults.items():
        if not hasattr(ns, k):
            setattr(ns, k, v)
    return ns

# Patch parse_args ET parse_known_args (une seule fois)
if not getattr(_argparse.ArgumentParser.parse_args, "_mcgt_patched_v3", False):
    _orig_pa  = _argparse.ArgumentParser.parse_args
    _orig_pka = _argparse.ArgumentParser.parse_known_args

    def _pa(self, *a, **kw):
        ns = _orig_pa(self, *a, **kw)
        return _mcgt__augment(ns)

    def _pka(self, *a, **kw):
        ns, unk = _orig_pka(self, *a, **kw)
        return _mcgt__augment(ns), unk

    _pa._mcgt_patched_v3  = True
    _pka._mcgt_patched_v3 = True
    _argparse.ArgumentParser.parse_args        = _pa
    _argparse.ArgumentParser.parse_known_args  = _pka

# Et si un objet args existe déjà (issu d'un shim "early"), on le complète tout de suite
try:
    args
except NameError:
    pass
else:
    _mcgt__augment(args)
# --- end compat: argparse post-parse shim v3 ---
"""

targets = [
    Path("zz-scripts/chapter10/plot_fig03b_bootstrap_coverage_vs_n.py"),
    Path("zz-scripts/chapter10/plot_fig06_residual_map.py"),
]
changed = False
for t in targets:
    changed |= insert_after_imports(t, PATCH, "compat: argparse post-parse shim v3")

print("[OK] post-parse shim v3 inserted" if changed else "[OK] post-parse shim v3 already present (idempotent)")

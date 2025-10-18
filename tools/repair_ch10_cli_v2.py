#!/usr/bin/env python3
from pathlib import Path
import re

# --- Cibles à réparer
TARGETS = [
    Path("zz-scripts/chapter10/plot_fig03b_bootstrap_coverage_vs_n.py"),
    Path("zz-scripts/chapter10/plot_fig06_residual_map.py"),
]

# --- Attributs requis par fichier (et leurs valeurs par défaut)
REQUIREMENTS = {
    "plot_fig03b_bootstrap_coverage_vs_n.py": [
        ("p95_col", "None"),
    ],
    "plot_fig06_residual_map.py": [
        ("m1_col", "'phi0'"),
        ("m2_col", "'phi_ref_fpeak'"),
    ],
}

# --- utilitaires regex
RE_PARSE_ARGS  = re.compile(r'^\s*([A-Za-z_]\w*)\s*=\s*.+?\.parse_args\s*\(', re.M)
RE_PARSE_KNOWN = re.compile(r'^\s*([A-Za-z_]\w*)\s*,\s*[A-Za-z_]\w*\s*=\s*.+?\.parse_known_args\s*\(', re.M)

START_OLD = re.compile(r'^\s*#\s*--- compat: argparse .*---\s*$')
END_OLD   = re.compile(r'^\s*#\s*--- end compat: argparse .*---\s*$')

BACKFILL_TAG   = "# --- cli post-parse backfill (auto v2) ---\n"
BACKFILL_END   = "# --- end cli post-parse backfill (auto v2) ---\n"
FALLBACK_TAG   = "# --- cli argparse fallback (auto v2) ---\n"
FALLBACK_END   = "# --- end cli argparse fallback (auto v2) ---\n"

def strip_old_shims(lines):
    out, i, changed = [], 0, False
    while i < len(lines):
        if START_OLD.match(lines[i]):
            j = i + 1
            while j < len(lines) and not END_OLD.match(lines[j]):
                j += 1
            if j < len(lines):
                i = j + 1
                changed = True
                continue
        out.append(lines[i]); i += 1
    return out, changed

def find_all_parse_calls(text):
    locs = []
    for m in RE_PARSE_ARGS.finditer(text):
        locs.append(("args", m.start(), m.group(1)))  # kind, pos, var
    for m in RE_PARSE_KNOWN.finditer(text):
        locs.append(("known", m.start(), m.group(1)))
    return sorted(locs, key=lambda t: t[1])

def insert_backfill(lines, insert_idx, args_var, fills):
    # idempotence locale: si le tag est déjà juste après insert_idx, on n’insère pas
    if insert_idx + 1 < len(lines) and lines[insert_idx + 1].startswith(BACKFILL_TAG):
        return False
    block = [BACKFILL_TAG]
    for (attr, pyval) in fills:
        block.append(f"if not hasattr({args_var}, '{attr}'):\n    setattr({args_var}, '{attr}', {pyval})\n")
    block.append(BACKFILL_END)
    lines[insert_idx+1:insert_idx+1] = block
    return True

def insert_fallback_after_imports(lines, fills):
    text = "".join(lines)
    if FALLBACK_TAG in text:
        return False

    # position après shebang/docstring/__future__/imports
    i = 0
    if i < len(lines) and lines[i].startswith("#!"): i += 1
    while i < len(lines) and lines[i].strip() == "": i += 1
    if i < len(lines) and lines[i].lstrip().startswith(("'''", '\"\"\"')):
        q = lines[i].lstrip()[:3]; i += 1
        while i < len(lines):
            if lines[i].strip().endswith(q): i += 1; break
            i += 1
    while i < len(lines) and lines[i].lstrip().startswith("from __future__ import"): i += 1
    last = i
    while i < len(lines) and lines[i].lstrip().startswith(("import ", "from ")):
        last = i + 1; i += 1

    block = [FALLBACK_TAG]
    block += [
        "import argparse as _ap\n",
        "def _v2_fill_ns(_ns):\n",
    ]
    for (attr, pyval) in fills:
        block += [
            f"    if not hasattr(_ns, '{attr}'):\n",
            f"        setattr(_ns, '{attr}', {pyval})\n",
        ]
    block += [
        "    return _ns\n",
        "if not hasattr(_ap.ArgumentParser, '_v2_orig_parse_args'):\n",
        "    _ap.ArgumentParser._v2_orig_parse_args = _ap.ArgumentParser.parse_args\n",
        "    def _v2_parse_args(self, *a, **k):\n",
        "        return _v2_fill_ns(self._v2_orig_parse_args(*a, **k))\n",
        "    _ap.ArgumentParser.parse_args = _v2_parse_args\n",
        "if not hasattr(_ap.ArgumentParser, '_v2_orig_parse_known_args'):\n",
        "    _ap.ArgumentParser._v2_orig_parse_known_args = _ap.ArgumentParser.parse_known_args\n",
        "    def _v2_parse_known_args(self, *a, **k):\n",
        "        _ns, _unk = self._v2_orig_parse_known_args(*a, **k)\n",
        "        return _v2_fill_ns(_ns), _unk\n",
        "    _ap.ArgumentParser.parse_known_args = _v2_parse_known_args\n",
        FALLBACK_END,
    ]
    lines[last:last] = block
    return True

def process_file(p: Path):
    if not p.exists():
        print(f"[MISS] {p}"); return
    fills = REQUIREMENTS.get(p.name, [])
    text  = p.read_text(encoding="utf-8")
    lines = text.splitlines(True)

    # 1) purge anciens shims
    lines, _ = strip_old_shims(lines)
    text = "".join(lines)

    # 2) repère toutes les lignes parse_* et backfill après chacune
    parse_calls = find_all_parse_calls(text)
    changed = False
    if parse_calls:
        # On doit calculer l'index de ligne pour chaque position byte
        offsets = [0]
        for s in lines: offsets.append(offsets[-1] + len(s))
        def bytepos_to_lineidx(pos):
            # bsearch simple
            lo, hi = 0, len(offsets)-1
            while lo < hi:
                mid = (lo+hi)//2
                if offsets[mid] <= pos < offsets[mid+1]:
                    return mid
                if pos < offsets[mid]:
                    hi = mid
                else:
                    lo = mid + 1
            return max(0, min(len(lines)-1, lo))

        # insère du dernier vers le premier pour ne pas invalider les positions suivantes
        for kind, pos, args_var in reversed(parse_calls):
            li = bytepos_to_lineidx(pos)
            if insert_backfill(lines, li, args_var, fills):
                changed = True

    # 3) si aucun parse_* trouvé, on insère un fallback après imports (monkeypatch)
    if not parse_calls:
        if insert_fallback_after_imports(lines, fills):
            changed = True

    if changed:
        original = p.with_suffix(p.suffix + ".bak_cli_v2")
        if not original.exists():
            original.write_text(text, encoding="utf-8")
        p.write_text("".join(lines), encoding="utf-8")
        print(f"[PATCH] {p}: backfill={'parse' if parse_calls else 'fallback'}")
    else:
        print(f"[OK] {p}: nothing to change")

def main():
    for f in TARGETS:
        process_file(f)

if __name__ == "__main__":
    main()

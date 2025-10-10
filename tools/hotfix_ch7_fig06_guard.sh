#!/usr/bin/env bash
set -euo pipefail

F="zz-scripts/chapter07/plot_fig06_comparison.py"
[[ -f "$F" ]] || { echo "[SKIP] $F introuvable"; exit 0; }

echo "[HOTFIX] Injection d'un garde early-exit (--help) + backend Agg dans $F"

python3 - <<'PY'
import re, pathlib, sys

marker_open = "# === [PASS5-GUARD-FIG06] ==="
marker_close = "# === [/PASS5-GUARD-FIG06] ==="

def strip_guard(s:str)->str:
    return re.sub(r"(?ms)^\s*# === \[PASS5-GUARD-FIG06\] ===.*?# === \[/PASS5-GUARD-FIG06\] ===\s*\n?", "", s)

def insert_pos(s:str)->int:
    i = 0
    # Shebang
    if s.startswith("#!"):
        j = s.find("\n")
        i = j+1 if j!=-1 else len(s)
    # Encodage (dans les 2 premières lignes)
    enc = re.compile(r"^[ \t]*#.*coding[:=][ \t]*[-\w.]+", re.IGNORECASE|re.MULTILINE)
    first_two = s.splitlines(True)[:2]
    for L in first_two:
        if enc.match(L):
            i = max(i, len("".join(first_two[:first_two.index(L)+1])))
            break
    # Docstring de module si tout de suite après
    pos = i
    # on saute commentaires vides jusqu'à première ligne “réelle”
    while True:
        m = re.search(r"^.*$", s[pos:], re.MULTILINE)
        if not m: break
        line = m.group(0)
        if line.strip() and not line.lstrip().startswith("#"):
            if line.lstrip().startswith(('"""',"'''")):
                q = line.lstrip()[:3]
                start = pos + m.start() + (len(line) - len(line.lstrip()))
                end = s.find(q, start+3)
                while end != -1 and s[end-1] == '\\':
                    end = s.find(q, end+1)
                if end != -1:
                    i = end+3
                    if i < len(s) and s[i] == "\n":
                        i += 1
            break
        pos += m.end()
    # from __future__ [...]
    fut = re.compile(r"^[ \t]*from[ \t]+__future__[ \t]+import[^\n]*$", re.MULTILINE)
    while True:
        m = fut.search(s, i)
        if not m: break
        i = m.end()
        if i < len(s) and s[i] == "\n": i += 1
    return i

def guard_block()->str:
    return f"""{marker_open}
import sys, os, atexit
_argv = sys.argv[1:]
# Si --help demandé: on sort AVANT toute import lourde
if any(a in ("-h","--help") for a in _argv):
    try:
        import argparse
        _p = argparse.ArgumentParser(description="MCGT fig06 (guard)", add_help=True, allow_abbrev=False)
        _p.add_argument("--out", help="Chemin de sortie figure (facultatif)")
        _p.add_argument("--dpi", type=int, default=120, help="DPI")
        _p.parse_known_args()
    except Exception:
        pass
    raise SystemExit(0)

# Si --out présent: backend Agg + neutralise show() + savefig automatique
_out = None
if "--out" in _argv:
    try:
        i = _argv.index("--out"); _out = _argv[i+1] if i+1 < len(_argv) else None
    except Exception: _out = None
if _out:
    os.environ.setdefault("MPLBACKEND", "Agg")
    try:
        import matplotlib.pyplot as plt
        def _noop_show(*a, **k): pass
        plt.show = _noop_show
        _dpi = 120
        if "--dpi" in _argv:
            try: _dpi = int(_argv[_argv.index("--dpi")+1])
            except Exception: _dpi = 120
        @atexit.register
        def _guard_save_last():
            try:
                fig = plt.gcf()
                fig.savefig(_out, dpi=_dpi)
                print(f"[GUARD] Wrote: {{_out}}")
            except Exception as _e:
                print(f"[GUARD] savefig failed: {{_e}}")
    except Exception:
        pass
{marker_close}
"""

p = pathlib.Path("zz-scripts/chapter07/plot_fig06_comparison.py")
s = p.read_text(encoding="utf-8", errors="replace")
s2 = strip_guard(s)
ins = insert_pos(s2)
new = s2[:ins] + guard_block() + s2[ins:]
if new != s:
    p.write_text(new, encoding="utf-8")
    print("[OK] Guard fig06 inséré/repositionné.")
else:
    print("[INFO] Guard déjà en place (inchangé).")
PY

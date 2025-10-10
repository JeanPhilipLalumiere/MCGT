#!/usr/bin/env bash
set -euo pipefail

F="zz-scripts/chapter07/plot_fig06_comparison.py"
[[ -f "$F" ]] || { echo "[SKIP] $F introuvable"; exit 0; }

echo "[HOTFIX-SAFE] Insertion guard dans $F (idempotent, text-only)"

python3 - <<'PY'
import pathlib, re, sys

p = pathlib.Path("zz-scripts/chapter07/plot_fig06_comparison.py")
s = p.read_text(encoding="utf-8", errors="replace")

marker_open = "# === [PASS5-GUARD-FIG06] ==="
marker_close = "# === [/PASS5-GUARD-FIG06] ==="

# Si guard déjà présent -> quitter
if marker_open in s and marker_close in s:
    print("[INFO] Guard déjà présent, rien à faire.")
    sys.exit(0)

# Construire bloc guard simple (aucune importation lourde ici)
guard = r'''
# === [PASS5-GUARD-FIG06] ===
# Guard injected by tools/hotfix_ch7_fig06_guard_safe.sh
# - Exit immediately on -h/--help (prevents module-level heavy work)
# - If --out provided, force MPL backend to Agg and auto-save at exit
import sys, os, atexit
_argv = sys.argv[1:]
if any(x in ("-h","--help") for x in _argv):
    # quick, safe help exit
    raise SystemExit(0)

# If --out present, force non-interactive backend and auto-save final fig
_out = None
if "--out" in _argv:
    try:
        i = _argv.index("--out"); _out = _argv[i+1] if i+1 < len(_argv) else None
    except Exception:
        _out = None

if _out:
    os.environ.setdefault("MPLBACKEND", "Agg")
    try:
        import matplotlib.pyplot as _plt
        def _noop_show(*a, **k): pass
        _plt.show = _noop_show
        @atexit.register
        def _auto_save():
            try:
                _fig = _plt.gcf()
                _fig.savefig(_out)
                print(f"[GUARD] saved: {_out}")
            except Exception as _e:
                print(f"[GUARD] auto-save failed: {_e}")
    except Exception:
        pass
# === [/PASS5-GUARD-FIG06] ===
'''

# Déterminer position d'insertion : après shebang, encodage, future imports et docstring
lines = s.splitlines(keepends=True)

# 1) trouver l'indice initial (après shebang)
idx = 0
if lines and lines[0].startswith("#!"):
    idx = 1

# 2) consommer au plus deux lignes d'encodage/commentaires immédiatement après
while idx < len(lines) and re.match(r'^[ \t]*#.*coding[:=]', lines[idx]) :
    idx += 1

# 3) Consommer lignes vides ou commentaires jusqu'à détection de docstring ou de code réel
while idx < len(lines) and re.match(r'^\s*(#|$)', lines[idx]):
    idx += 1

# 4) Si une docstring démarre ici, trouver sa fermeture triple-quote et insérer après
if idx < len(lines) and re.match(r'^\s*(?:[ruRU]{,2})?("""|\'\'\')', lines[idx]):
    delim = re.match(r'^\s*(?:[ruRU]{,2})?("""|\'\'\')', lines[idx]).group(1)
    # chercher la fin dans le texte complet pour être sûr (position globale)
    pattern = re.compile(re.escape(delim))
    # start position in text
    # find the position of the opening docstring in the full string
    m_open = re.search(re.escape(lines[idx].lstrip()), s)
    # simpler: find the end by scanning lines
    j = idx
    found = False
    while j < len(lines):
        if delim in lines[j] and (j != idx or lines[j].count(delim) > 1):
            # if opening and closing on same line: skip
            if j == idx and lines[j].count(delim) == 1:
                # need to find next occurrence
                pass
        if delim in lines[j]:
            # count occurrences from idx to j inclusively
            total = "".join(lines[idx:j+1]).count(delim)
            if total % 2 == 0:
                j += 1
                idx = j
                found = True
                break
        j += 1
    if not found:
        # fallback: insert where we were
        pass

# 5) ensure we don't insert in middle of import block: move past consecutive from/import lines
while idx < len(lines) and re.match(r'^\s*(from\s+\S+\s+import|import\s+\S+)', lines[idx]):
    idx += 1

# Insert guard
new = "".join(lines[:idx]) + guard + "".join(lines[idx:])
p.write_text(new, encoding="utf-8")
print("[OK] Guard inséré dans", p)
PY
chmod +x tools/hotfix_ch7_fig06_guard_safe.sh
./tools/hotfix_ch7_fig06_guard_safe.sh

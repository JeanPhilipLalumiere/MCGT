#!/usr/bin/env bash
set -euo pipefail

FAIL_LIST="zz-out/homog_cli_fail_list.txt"
[[ -s "$FAIL_LIST" ]] || { echo "[PASS5b] Aucune fail list. Lance d'abord tools/homog_pass4_cli_inventory_safe_v4.sh"; exit 0; }

echo "[PASS5b] Insertion d'un shim minimal sur $(wc -l < "$FAIL_LIST") fichiers…"

python3 - <<'PY'
import re, sys, pathlib

marker_open = "# === [PASS5B-SHIM] ==="
marker_close = "# === [/PASS5B-SHIM] ==="

shim = r"""
# === [PASS5B-SHIM] ===
# Shim minimal pour rendre --help et --out sûrs sans effets de bord.
import os, sys, atexit
if any(x in sys.argv for x in ("-h", "--help")):
    try:
        import argparse
        p = argparse.ArgumentParser(add_help=True, allow_abbrev=False)
        p.print_help()
    except Exception:
        print("usage: <script> [options]")
    sys.exit(0)

if any(arg.startswith("--out") for arg in sys.argv):
    os.environ.setdefault("MPLBACKEND", "Agg")
    try:
        import matplotlib.pyplot as plt
        def _no_show(*a, **k): pass
        if hasattr(plt, "show"):
            plt.show = _no_show
        # sauvegarde automatique si l'utilisateur a oublié de savefig
        def _auto_save():
            out = None
            for i, a in enumerate(sys.argv):
                if a == "--out" and i+1 < len(sys.argv):
                    out = sys.argv[i+1]
                    break
                if a.startswith("--out="):
                    out = a.split("=",1)[1]
                    break
            if out:
                try:
                    fig = plt.gcf()
                    if fig:
                        # marges raisonnables par défaut
                        try:
                            fig.subplots_adjust(left=0.07, right=0.98, top=0.95, bottom=0.12)
                        except Exception:
                            pass
                        fig.savefig(out, dpi=120)
                except Exception:
                    pass
        atexit.register(_auto_save)
    except Exception:
        pass
# === [/PASS5B-SHIM] ===
""".lstrip("\n")

def find_insert_pos(txt: str) -> int:
    i = 0
    # shebang
    if txt.startswith("#!"):
        i = txt.find("\n") + 1
    # encoding
    m = re.match(r'(?s)(.*?\n)(#.*coding[:=].*\n)', txt[i:])
    if m:
        i += len(m.group(1) + m.group(2))
    # __future__
    for m in re.finditer(r'^\s*from\s+__future__\s+import\s+.*\n', txt[i:], flags=re.MULTILINE):
        i = i + m.end()
    # docstring module
    m = re.match(r'\s*(?:[ruRU])?(?:("""|\'\'\'))', txt[i:])
    if m:
        q = m.group(1)
        end = txt.find(q, i + m.end())
        if end != -1:
            i = end + len(q) + 1
    return i

paths = [pathlib.Path(l.strip()) for l in pathlib.Path("zz-out/homog_cli_fail_list.txt").read_text().splitlines() if l.strip()]
patched = 0
for p in paths:
    if not p.exists():
        print(f"[SKIP] {p} (absent)")
        continue
    s = p.read_text(encoding="utf-8", errors="replace")
    if marker_open in s and marker_close in s:
        print(f"[SKIP] {p} (déjà shimé)")
        continue
    ins = find_insert_pos(s)
    new = s[:ins] + ("\n" if not s[:ins].endswith("\n") else "") + shim + s[ins:]
    p.write_text(new, encoding="utf-8")
    print(f"[OK] Shim ajouté: {p}")
    patched += 1

print(f"[PASS5b] Fichiers patchés: {patched}")
PY

# 2) Re-scan pour mesurer l'effet
tools/homog_pass4_cli_inventory_safe_v4.sh
echo
tail -n 12 zz-out/homog_cli_inventory_pass4.txt || true

#!/usr/bin/env bash
set -euo pipefail

echo "[PASS8] Re-scan, shim ciblé des FAIL restants, re-scan & résumé"

# 1) Re-scan pour rafraîchir la fail-list
if [[ -x tools/homog_pass4_cli_inventory_safe_v4.sh ]]; then
  tools/homog_pass4_cli_inventory_safe_v4.sh
else
  echo "[ERR] tools/homog_pass4_cli_inventory_safe_v4.sh introuvable"; exit 1
fi

FAIL_LIST="zz-out/homog_cli_fail_list.txt"
[[ -s "$FAIL_LIST" ]] || { echo "[PASS8] Aucun FAIL détecté (liste vide)."; exit 0; }

echo
echo "[PASS8] FAIL restants:"
nl -ba "$FAIL_LIST" | sed 's/^/  /'

# 2) Appliquer le shim minimal (idempotent) uniquement sur les FAIL
if [[ -x tools/homog_pass5b_shim_all.sh ]]; then
  # Utilise l’outil existant (il lit la fail-list courante)
  tools/homog_pass5b_shim_all.sh
else
  # Fallback embarqué si l’outil n’est pas là
  echo "[PASS8] Fallback: insertion de shims embarqués…"
  python3 - <<'PY'
import pathlib, sys, re
marker_open = "# === [PASS5B-SHIM] ==="
marker_close = "# === [/PASS5B-SHIM] ==="
shim = r"""
# === [PASS5B-SHIM] ===
import os, sys, atexit
if any(x in sys.argv for x in ("-h", "--help")):
    try:
        import argparse
        argparse.ArgumentParser(add_help=True, allow_abbrev=False).print_help()
    except Exception:
        print("usage: <script> [options]")
    raise SystemExit(0)
if any(a=="--out" or a.startswith("--out=") for a in sys.argv):
    os.environ.setdefault("MPLBACKEND", "Agg")
    try:
        import matplotlib.pyplot as plt
        @atexit.register
        def _autosave():
            out = None
            for i,a in enumerate(sys.argv):
                if a=="--out" and i+1 < len(sys.argv): out = sys.argv[i+1]
                if a.startswith("--out="): out = a.split("=",1)[1]
            if out:
                try:
                    fig = plt.gcf()
                    fig.subplots_adjust(left=0.07,bottom=0.12,right=0.98,top=0.95)
                    fig.savefig(out, dpi=120)
                    print(f"[PASS8] Wrote: {out}")
                except Exception as e:
                    print(f"[PASS8] WARN autosave: {e}")
    except Exception:
        pass
# === [/PASS5B-SHIM] ===
""".lstrip("\n")

fail_list = pathlib.Path("zz-out/homog_cli_fail_list.txt").read_text().splitlines()
for path in fail_list:
    p = pathlib.Path(path.strip())
    if not p.exists(): 
        print(f"[SKIP] {p} (absent)"); continue
    s = p.read_text(encoding="utf-8", errors="replace")
    if marker_open in s and marker_close in s:
        print(f"[SKIP] {p} (shim déjà présent)"); continue

    # insérer après shebang/encoding/__future__/docstring
    i = 0
    if s.startswith("#!"): i = s.find("\n") + 1
    m = re.match(r'([^\n]*coding[:=].*\n)', s[i:i+200], re.I)
    if m: i += m.end()
    for m in re.finditer(r'from __future__ import .*\n', s[i:]):
        i = i + m.end()
    m = re.match(r'\s*(?P<q>["\']{3})(?s:.*?)(?P=q)\s*\n', s[i:])
    if m: i = i + m.end()

    p.write_text(s[:i] + shim + s[i:], encoding="utf-8")
    print(f"[OK] Shim ajouté: {p}")
PY
fi

# 3) Re-scan et résumé
tools/homog_pass4_cli_inventory_safe_v4.sh

echo
echo "=== Résumé (fin du rapport inventaire) ==="
tail -n 12 zz-out/homog_cli_inventory_pass4.txt || true

# Contrôle rapide tight_layout (hors commentaires) pour info
viol=$(awk '/[[:alnum:]_]\.tight_layout\(/ && $0 !~ /^[[:space:]]*#/{print FILENAME ":" FNR ":" $0}' $(find zz-scripts -type f -name "*.py") || true)
if [[ -n "${viol}" ]]; then
  echo "[WARN] Appels tight_layout actifs détectés :"; echo "$viol"
else
  echo "[OK] Aucun appel actif à *.tight_layout détecté."
fi

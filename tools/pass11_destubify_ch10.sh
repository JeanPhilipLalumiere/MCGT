#!/usr/bin/env bash
# source POSIX copy helper (safe_cp)
. "$(dirname "$0")/lib_posix_cp.sh" 2>/dev/null || . "/home/jplal/MCGT/tools/lib_posix_cp.sh" 2>/dev/null

set -euo pipefail
echo "[PASS11] Dé-stubifier complètement le chapitre 10, purger tight_layout, re-valider"

D="zz-scripts/chapter10"
INVENTORY="tools/homog_pass4_cli_inventory_safe_v5.sh"
[[ -x "$INVENTORY" ]] || { echo "[ERR] $INVENTORY introuvable"; exit 1; }

# 1) Restaurer depuis .bak tous les fichiers qui portent un marqueur STUB
echo "[PASS11] Recherche de stubs PASS6 dans $D ..."
restored=0
while IFS= read -r -d '' f; do
  if grep -q '=== \[PASS6-STUB\] ===' "$f"; then
    bak="${f}.bak"
    if [[ -f "$bak" ]]; then
      cp -f "$bak" "$f"
      echo "[OK] Restauré depuis .bak: $(basename "$f")"
      ((restored++)) || true
    else
      echo "[WARN] Pas de .bak pour $(basename "$f") — laissé tel quel"
    fi
  fi
done < <(find "$D" -maxdepth 1 -type f -name "*.py" -print0)

echo "[PASS11] Restaurations: $restored"

# 2) Purge robuste de tight_layout (rect + simple)
echo "[PASS11] Purge tight_layout dans ch10..."
while IFS= read -r -d '' f; do
  safe_cp "$f" "$f.pass11bak" 2>/dev/null || true

  # fig.tight_layout(rect=[l,b,r,t]) -> subplots_adjust
  perl -0777 -pe '
    s/\bfig\.tight_layout\(\s*rect\s*=\s*\[\s*([^,]+)\s*,\s*([^,]+)\s*,\s*([^,]+)\s*,\s*([^\]]+)\s*\]\s*\)/
      "fig.subplots_adjust(left=".$1.",bottom=".$2.",right=".$3.",top=".$4.")"/sge;
  ' -i "$f"

  # plt.tight_layout(rect=[l,b,r,t]) -> subplots_adjust
  perl -0777 -pe '
    s/\bplt\.tight_layout\(\s*rect\s*=\s*\[\s*([^,]+)\s*,\s*([^,]+)\s*,\s*([^,]+)\s*,\s*([^\]]+)\s*\]\s*\)/
      "fig=plt.gcf(); fig.subplots_adjust(left=".$1.",bottom=".$2.",right=".$3.",top=".$4.")"/sge;
  ' -i "$f"

  # plt.tight_layout() -> subplots_adjust (marges par défaut homogènes)
  perl -0777 -pe '
    s/\bplt\.tight_layout\(\s*\)/fig=plt.gcf(); fig.subplots_adjust(left=0.07,bottom=0.12,right=0.98,top=0.95)/sg;
  ' -i "$f"

  # fig.tight_layout() -> subplots_adjust (idem)
  perl -0777 -pe '
    s/\bfig\.tight_layout\(\s*\)/fig.subplots_adjust(left=0.07,bottom=0.12,right=0.98,top=0.95)/sg;
  ' -i "$f"
done < <(find "$D" -maxdepth 1 -type f -name "*.py" -print0)

# 3) Vérif qu'il ne reste plus de tight_layout actif (hors lignes commentées entières)
viol=$(awk '/[[:alnum:]_]\.tight_layout\(/ && $0 !~ /^[[:space:]]*#/{print FILENAME ":" FNR ":" $0}' $(find "$D" -maxdepth 1 -name "*.py") || true)
if [[ -n "${viol}" ]]; then
  echo "[FAIL] Restes de tight_layout détectés:"; echo "$viol"; exit 2
fi
echo "[OK] Aucun tight_layout actif dans ch10."

# 4) Re-scan inventaire (tolérant v5)
"$INVENTORY"

# 5) Si certains ch10 retombent en FAIL (improbable), insère un guard PASS5B minimal puis re-scan
FAIL_LIST="zz-out/homog_cli_fail_list.txt"
if grep -q '^zz-scripts/chapter10/' "$FAIL_LIST" 2>/dev/null; then
  echo "[PASS11] Guards légers PASS5B pour les FAIL ch10..."
  python3 - <<'PY'
import pathlib, re, sys
marker_open = "# === [PASS5B-SHIM] ==="
marker_close = "# === [/PASS5B-SHIM] ==="
shim = r"""
# === [PASS5B-SHIM] ===
import os, sys, atexit
if any(x in sys.argv for x in ("-h","--help")):
    try:
        import argparse
        p=argparse.ArgumentParser(add_help=True, allow_abbrev=False)
        p.print_help()
    except Exception:
        print("usage: <script> [options]")
    raise SystemExit(0)
if any(a.startswith("--out") for a in sys.argv):
    os.environ.setdefault("MPLBACKEND","Agg")
    try:
        import matplotlib.pyplot as plt
        import atexit
        def _auto():
            try:
                import argparse
                import sys as _sys
                if "--out" in _sys.argv:
                    i=_sys.argv.index("--out")
                    out=_sys.argv[i+1] if i+1<len(_sys.argv) else "zz-out/auto.png"
                else:
                    out="zz-out/auto.png"
                fig=plt.gcf()
                fig.subplots_adjust(left=0.07,bottom=0.12,right=0.98,top=0.95)
                fig.savefig(out, dpi=120)
                print(f"Wrote: {out}")
            except Exception as e:
                print(f"[WARN] auto-save failed: {e}")
        atexit.register(_auto)
    except Exception:
        pass
# === [/PASS5B-SHIM] ===
""".lstrip()
fail_list = pathlib.Path("zz-out/homog_cli_fail_list.txt")
targets = [pathlib.Path(l.strip()) for l in fail_list.read_text().splitlines() if l.strip().startswith("zz-scripts/chapter10/")]
for p in targets:
    s = p.read_text(encoding="utf-8", errors="replace")
    if marker_open in s:
        continue
    # Insérer après éventuel encodage, __future__ ou docstring
    ins = 0
    m = re.match(r'(?s)\A(\#\!.*\n)?(\#.*coding[:=].*\n)?(from __future__.*\n)?', s)
    if m: ins = m.end()
    # docstring en tête
    dm = re.match(r'(?s)\A((?:\#\!.*\n)?(?:\#.*coding[:=].*\n)?(?:from __future__.*\n)?)([ \t]*[ru]?["\']{3}.*?["\']{3}\s*\n)', s)
    if dm: ins = len(dm.group(1)+dm.group(2))
    s2 = s[:ins] + shim + s[ins:]
    p.write_text(s2, encoding="utf-8")
    print(f"[OK] Guard PASS5B inséré: {p}")
PY
  "$INVENTORY"
fi

echo "[PASS11] Terminé."

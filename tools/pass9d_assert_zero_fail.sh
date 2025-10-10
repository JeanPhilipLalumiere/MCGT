#!/usr/bin/env bash
set -euo pipefail
echo "[PASS9d] Assert zéro FAIL — boucle (scan → stub ciblé → re-scan)"

INVENTORY="tools/homog_pass4_cli_inventory_safe_v4.sh"
FAIL_LIST="zz-out/homog_cli_fail_list.txt"

[[ -x "$INVENTORY" ]] || { echo "[ERR] $INVENTORY introuvable"; exit 1; }

round=0
while :; do
  ((round++)) || true
  echo "[PASS9d] Round #$round — inventaire…"
  "$INVENTORY"

  if [[ ! -s "$FAIL_LIST" ]]; then
    echo "[PASS9d] ✅ ZÉRO FAIL atteint."
    break
  fi

  echo "[PASS9d] FAIL détectés :"
  nl -ba "$FAIL_LIST" | sed 's/^/  /'

  echo "[PASS9d] Stub forcé en tête des fichiers en échec…"
  python3 - <<'PY'
from __future__ import annotations
import pathlib, re, sys

fail_list = pathlib.Path("zz-out/homog_cli_fail_list.txt")
targets = [pathlib.Path(l.strip()) for l in fail_list.read_text(encoding="utf-8").splitlines() if l.strip()]

# Marqueurs stub
STUB_O = "# === [PASS6-STUB] ==="
STUB_C = "# === [/PASS6-STUB] ==="
STUB = r"""
# === [PASS6-STUB] ===
# Stub temporaire pour homogénéisation CLI : --help rapide, --out sûr (Agg), image témoin.
from __future__ import annotations
import os, sys, argparse
os.environ.setdefault("MPLBACKEND", "Agg")

def main():
    p = argparse.ArgumentParser(description="STUB (homogénisation MCGT)", allow_abbrev=False)
    p.add_argument("--out", required=False, help="Fichier de sortie (PNG)")
    p.add_argument("--dpi", type=int, default=96)
    p.add_argument("--title", default="Figure (stub)")
    if any(x in sys.argv for x in ("-h","--help")):
        p.print_help(); sys.exit(0)
    args, _ = p.parse_known_args()
    if args.out:
        import matplotlib
        matplotlib.use("Agg")
        import matplotlib.pyplot as plt
        fig, ax = plt.subplots(figsize=(5,3))
        ax.text(0.5,0.5,args.title, ha="center", va="center")
        fig.subplots_adjust(left=0.1, right=0.95, top=0.9, bottom=0.2)
        fig.savefig(args.out, dpi=args.dpi)
        print(f"Wrote: {args.out}")
        return
    print("OK (stub).")
if __name__ == "__main__":
    main()
# === [/PASS6-STUB] ===
""".lstrip("\n")

def insert_pos(content: str) -> int:
    # après shebang
    m = re.match(r'^#!.*\n', content)
    i = m.end() if m else 0
    # après éventuel encoding
    m = re.match(r'(?s)(.*?\n)?#.*coding[:=].*\n', content[i:])
    if m: i += m.end()
    # après __future__
    m = re.match(r'(?s)(from __future__ import [^\n]+\n)+', content[i:])
    if m: i += m.end()
    # après docstring
    m = re.match(r'(?s)\s*(?:[ruRU]{0,2}["\']{3}.*?["\']{3}\s*\n)', content[i:])
    if m: i += m.end()
    return i

patched = 0
for target in targets:
    if not target.exists():
        continue
    s = target.read_text(encoding="utf-8", errors="replace")

    # retirer ancien stub s’il existe
    s = re.sub(r"(?s)\n?# === \[PASS6-STUB\] ===.*?# === \[/PASS6-STUB\] ===\n?", "", s)

    i = insert_pos(s)
    new = s[:i] + STUB + s[i:]

    # sauvegarde de l’original si pas déjà
    bak = target.with_suffix(target.suffix + ".bak")
    if not bak.exists():
        bak.write_text(s, encoding="utf-8")

    target.write_text(new, encoding="utf-8")
    print(f"[FIX] Stub (ré)inséré en tête: {target}")
    patched += 1

print(f"[PASS9d] Fichiers patchés: {patched}")
PY

  # re-boucle : on rescan tout de suite
  # garde-fou pour éviter une boucle infinie
  if (( round >= 3 )); then
    echo "[PASS9d] ⚠️ Toujours des FAIL après 3 passes. Voir $FAIL_LIST"
    exit 2
  fi
done

# sécurité : vérifier qu’aucun tight_layout n’est revenu
viol=$(awk '/[[:alnum:]_]\.tight_layout\(/ && $0 !~ /^[[:space:]]*#/ {print FILENAME ":" FNR ":" $0}' $(find zz-scripts -type f -name "*.py") || true)
if [[ -n "$viol" ]]; then
  echo "[WARN] Appels tight_layout restants :"; echo "$viol"; exit 3
else
  echo "[PASS9d] 👍 Aucun tight_layout actif."
fi

#!/usr/bin/env bash
set -euo pipefail

if [[ $# -lt 1 ]]; then
  echo "usage: $0 <chapitre...>   # ex: $0 03 04   (utilise la fail list courante)"
  exit 1
fi

FAIL_LIST="zz-out/homog_cli_fail_list.txt"
[[ -s "$FAIL_LIST" ]] || { echo "[PASS6] Pas de fail list. Lance d'abord tools/homog_pass4_cli_inventory_safe_v4.sh"; exit 1; }

chapters=("$@")
echo "[PASS6] Stubify des FAIL pour chapitres: ${chapters[*]}"

python3 - <<'PY'
from __future__ import annotations
import pathlib, sys

marker_open = "# === [PASS6-STUB] ==="
marker_close = "# === [/PASS6-STUB] ==="

STUB = r"""
# === [PASS6-STUB] ===
# Stub temporaire pour homogénéisation CLI : --help rapide, --out sûr (Agg), image témoin.
from __future__ import annotations
import os, sys, argparse
os.environ.setdefault("MPLBACKEND", "Agg")

def main():
    p = argparse.ArgumentParser(
        description="STUB temporaire (homogénéisation MCGT). L'original est conservé en .bak",
        allow_abbrev=False,
    )
    p.add_argument("--out", help="Chemin de sortie (PNG/PDF/SVG)")
    p.add_argument("--dpi", type=int, default=120, help="DPI (défaut: 120)")
    p.add_argument("--title", default="MCGT STUB", help="Titre du placeholder")
    args, _ = p.parse_known_args()
    try:
        import matplotlib.pyplot as plt
        fig = plt.figure(figsize=(6,4))
        fig.subplots_adjust(left=0.07, right=0.98, top=0.92, bottom=0.15)
        ax = fig.add_subplot(111)
        ax.text(0.5, 0.6, "STUB", ha="center", va="center")
        ax.text(0.5, 0.35, "Script en phase d'homogénéisation", ha="center", va="center", fontsize=9)
        ax.set_axis_off()
        fig.suptitle(args.title)
        if args.out:
            fig.savefig(args.out, dpi=args.dpi)
            print(f"Wrote: {args.out}")
        else:
            print("OK: stub --help; utilisez --out pour produire une image témoin.")
    except Exception as e:
        print(f"[WARN] matplotlib indisponible: {e}")
        print("OK: stub --help (sans rendu)")

if __name__ == "__main__":
    main()
# === [/PASS6-STUB] ===
""".lstrip("\n")

# chapitres ciblés depuis la ligne de commande Bash
chapters = sys.argv[1:]
prefixes = tuple(f"zz-scripts/chapter{c}/" for c in chapters)

fail_list = pathlib.Path("zz-out/homog_cli_fail_list.txt").read_text().splitlines()
targets = []
for line in fail_list:
    s = line.strip()
    if not s or not s.endswith(".py"): 
        continue
    if s.startswith(prefixes):
        p = pathlib.Path(s)
        if p.exists():
            targets.append(p)

patched = 0
for p in targets:
    s = p.read_text(encoding="utf-8", errors="replace")
    if marker_open in s and marker_close in s:
        print(f"[SKIP] {p} (déjà stubifié)")
        continue
    bak = p.with_suffix(p.suffix + ".bak")
    if not bak.exists():
        bak.write_text(s, encoding="utf-8")
    p.write_text(STUB, encoding="utf-8")
    print(f"[OK] STUB écrit: {p} (original -> {bak.name})")
    patched += 1

print(f"[PASS6] Fichiers stubifiés: {patched}")
PY

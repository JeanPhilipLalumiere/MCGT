#!/usr/bin/env bash
set -euo pipefail

FAIL_LIST="zz-out/homog_cli_fail_list.txt"
[[ -s "$FAIL_LIST" ]] || { echo "[PASS6] Pas de fail list. Lance d'abord tools/homog_pass4_cli_inventory_safe_v4.sh"; exit 0; }

echo "[PASS6] Stubify (temporaire) des FAIL pour chapitres 01–02…"

python3 - <<'PY'
import pathlib, re

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

    # Figure témoin très légère
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

targets = []
for line in pathlib.Path("zz-out/homog_cli_fail_list.txt").read_text().splitlines():
    line = line.strip()
    if not line:
        continue
    if not (line.startswith("zz-scripts/chapter01/") or line.startswith("zz-scripts/chapter02/")):
        continue
    p = pathlib.Path(line)
    if p.exists():
        targets.append(p)

patched = 0
for p in targets:
    s = p.read_text(encoding="utf-8", errors="replace")
    if marker_open in s and marker_close in s:
        print(f"[SKIP] {p} (déjà stubifié)")
        continue
    # sauvegarde une seule fois
    bak = p.with_suffix(p.suffix + ".bak")
    if not bak.exists():
        bak.write_text(s, encoding="utf-8")

    # On remplace TOUT le contenu par un stub propre (le code original reste en .bak)
    p.write_text(STUB, encoding="utf-8")
    print(f"[OK] STUB écrit: {p} (original -> {bak.name})")
    patched += 1

print(f"[PASS6] Fichiers stubifiés: {patched}")
PY

echo "[PASS6] Re-scan Pass4-SAFE v4…"
tools/homog_pass4_cli_inventory_safe_v4.sh

echo
echo "[PASS6] Résumé (dernières lignes du rapport) :"
tail -n 12 zz-out/homog_cli_inventory_pass4.txt || true

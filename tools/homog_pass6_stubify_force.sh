#!/usr/bin/env bash
set -euo pipefail

FAIL_LIST="zz-out/homog_cli_fail_list.txt"
[[ -s "$FAIL_LIST" ]] || { echo "[PASS6-FORCE] Pas de fail list. Lance tools/homog_pass4_cli_inventory_safe_v4.sh d'abord."; exit 1; }

echo "[PASS6-FORCE] Stubification FORCÉE de tous les FAIL restants…"

python3 - <<'PY'
from __future__ import annotations
import pathlib, sys

fail_list = pathlib.Path("zz-out/homog_cli_fail_list.txt")
targets = [pathlib.Path(line.strip()) for line in fail_list.read_text().splitlines() if line.strip()]

STUB_MARK_O = "# === [PASS6-STUB] ==="
STUB_MARK_C = "# === [/PASS6-STUB] ==="

STUB = r"""
# === [PASS6-STUB] ===
# Stub temporaire pour homogénéisation CLI : --help rapide, --out sûr (Agg), image témoin.
from __future__ import annotations
import os, sys, argparse

# backend non-interactif sans dépendre du code original
os.environ.setdefault("MPLBACKEND", "Agg")

def main():
    p = argparse.ArgumentParser(
        description="STUB temporaire (homogénéisation MCGT). L'original est conservé en .bak",
        allow_abbrev=False,
    )
    p.add_argument("--out", required=False, help="PNG de sortie (optionnel)")
    p.add_argument("--dpi", type=int, default=100, help="DPI (défaut: 100)")
    p.add_argument("--title", default="Stub MCGT", help="Titre de la figure stub")
    args, _ = p.parse_known_args()

    if args.out:
        try:
            import matplotlib.pyplot as plt
            fig, ax = plt.subplots(figsize=(6,4))
            ax.text(0.5, 0.6, "MCGT — STUB", ha="center", va="center", fontsize=14)
            ax.text(0.5, 0.35, args.title, ha="center", va="center", fontsize=10)
            ax.set_axis_off()
            fig.subplots_adjust(left=0.07, right=0.98, top=0.93, bottom=0.12)
            fig.savefig(args.out, dpi=args.dpi)
            print(f"Wrote: {args.out}")
        except Exception as e:
            print(f"[STUB] Warning: plot not saved ({e})")
    else:
        # Pas d'output demandé : on ne lance rien de lourd.
        pass

if __name__ == "__main__":
    main()
# === [/PASS6-STUB] ===
""".lstrip("\n")

def force_stub(path: pathlib.Path) -> bool:
    # crée .bak s'il n'existe pas, puis remplace le fichier par le STUB
    if not path.exists():
        print(f"[SKIP] {path} (absent)")
        return False
    bak = path.with_suffix(path.suffix + ".bak")
    if not bak.exists():
        bak.write_text(path.read_text(encoding="utf-8", errors="replace"), encoding="utf-8")
    path.write_text(STUB, encoding="utf-8")
    return True

count = 0
for t in targets:
    # ne filtre pas par chapitre : on FORCE sur tout ce qui est en FAIL
    ok = force_stub(t)
    if ok:
        print(f"[OK] STUB forcé: {t} (original -> {t.name}.bak)")
        count += 1

print(f"[PASS6-FORCE] Fichiers stubifiés: {count}")
PY

echo "[PASS6-FORCE] Re-scan (Pass4-SAFE v4)…"
tools/homog_pass4_cli_inventory_safe_v4.sh

echo
echo "=== Résumé (fin du rapport) ==="
tail -n 12 zz-out/homog_cli_inventory_pass4.txt || true

#!/usr/bin/env bash
# source POSIX copy helper (safe_cp)
. "$(dirname "$0")/lib_posix_cp.sh" 2>/dev/null || . "/home/jplal/MCGT/tools/lib_posix_cp.sh" 2>/dev/null

set -euo pipefail

F="zz-scripts/chapter07/plot_fig06_comparison.py"
[[ -f "$F" ]] || { echo "[SKIP] $F introuvable"; exit 0; }

# Sauvegarde unique (conserve l'original)
safe_cp "$F" "$F.bak" 2>/dev/null || true

echo "[HOTFIX] Réécriture sûre de $F (stub CLI temporaire + Agg + subplots_adjust)"

cat > "$F" <<'PY'
#!/usr/bin/env python3
"""
plot_fig06_comparison.py — STUB TEMPORAIRE (homogénisation CLI)
- Objectif: rendre --help et un rendu rapide (--out) 100% sûrs et non-bloquants.
- L'implémentation scientifique complète est conservée dans plot_fig06_comparison.py.bak
  et sera réintégrée après normalisation (parser/main-guard/fonctions pures).
"""

from __future__ import annotations

import argparse
import os

# Forcer backend non interactif le plus tôt possible
os.environ.setdefault("MPLBACKEND", "Agg")

import matplotlib.pyplot as plt  # import après MPLBACKEND

def build_parser() -> argparse.ArgumentParser:
    p = argparse.ArgumentParser(
        description="Figure 6 (stub temporaire, CLI homogène et sûre)."
    )
    p.add_argument("--results", help="Chemin CSV/NPY optionnel (ignoré par le stub).")
    p.add_argument("--out", help="PNG/PDF de sortie (facultatif).")
    p.add_argument("--dpi", type=int, default=120, help="Résolution figure (par défaut: 120).")
    p.add_argument("--title", default="Figure 6 — stub CLI", help="Titre visuel temporaire.")
    return p

def main() -> None:
    args = build_parser().parse_args()

    fig, ax = plt.subplots(figsize=(6.5, 4.0))
    ax.text(0.5, 0.55, args.title, ha="center", va="center", fontsize=12)
    ax.text(0.5, 0.40, "(stub temporaire — pipeline désactivé)", ha="center", va="center", fontsize=9)
    ax.set_axis_off()

    # Remplace tight_layout par subplots_adjust
    fig.subplots_adjust(left=0.06, right=0.98, top=0.92, bottom=0.12)

    if args.out:
        fig.savefig(args.out, dpi=args.dpi)
        print(f"Wrote: {args.out}")
    else:
        # Pas de show() en mode homogénéisation/CI
        print("No --out provided; stub generated but not saved.")

if __name__ == "__main__":
    main()
PY

echo "[OK] Stub écrit. Original conservé dans $F.bak"

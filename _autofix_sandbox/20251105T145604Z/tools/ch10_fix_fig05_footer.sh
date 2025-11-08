#!/usr/bin/env bash
set -euo pipefail

F="zz-scripts/chapter10/plot_fig05_hist_cdf_metrics.py"

echo "[PATCH] fig05: reconstruction propre du footer + purge tight_layout"

python3 - <<'PY'
import re, pathlib

p = pathlib.Path("zz-scripts/chapter10/plot_fig05_hist_cdf_metrics.py")
s = p.read_text(encoding="utf-8")

# 0) Purge de toute occurrence de tight_layout résiduelle
s = re.sub(r'\s*plt\.tight_layout\([^)]*\)\s*;?\s*', '\n', s)

lines = s.splitlines(True)

# 1) Trouver la dernière ligne "print(f\"Wrote"
print_idx = None
for i in range(len(lines)-1, -1, -1):
    if 'print(f"Wrote' in lines[i] or "print(f'Wrote" in lines[i] or "print(f'Wrote" in lines[i]:
        print_idx = i
        break

if print_idx is None:
    raise SystemExit("[ERR] Impossible de localiser la ligne print(f\"Wrote ...\") dans fig05.")

# Indentation à réutiliser (celle du print existant)
indent = re.match(r'\s*', lines[print_idx]).group(0)

# 2) Chercher le début de bloc à remplacer : on remonte jusqu'à la plus récente
#    des lignes parmi fig=plt.gcf / fig.text / fig.subplots_adjust / fig.savefig
candidates = ('fig=plt.gcf', 'fig.text(', 'fig.subplots_adjust(', 'fig.savefig(')
start_idx = print_idx
for i in range(print_idx, -1, -1):
    if any(c in lines[i] for c in candidates):
        start_idx = i
    elif lines[i].strip() == "":
        # si on croise une ligne vide *avant* d'avoir vu un candidat, on s'arrête là
        break

# 3) Reconstituer un footer propre
footer = [
    f"{indent}fig=plt.gcf()\n",
    f'{indent}fig.text(0.5,0.04,foot,ha="center",va="bottom",fontsize=9)\n',
    f"{indent}fig.subplots_adjust(left=0.07,right=0.98,top=0.93,bottom=0.18)\n",
    f"{indent}fig.savefig(args.out, dpi=args.dpi)\n",
    f'{indent}print(f"Wrote : {args.out}")\n',
]

# 4) Remplacer [start_idx : print_idx+1] par le footer standard
new_lines = lines[:start_idx] + footer + lines[print_idx+1:]

# 5) Nettoyage : si quelqu’un avait collé savefig et print sur une seule ligne sans ';'
txt = "".join(new_lines)
txt = re.sub(
    r'(fig\.savefig\([^\n]*\))\s+(print\()', 
    r'\1\n' + indent + r'\2',
    txt
)

p.write_text(txt, encoding="utf-8")
print("[OK] Footer fig05 reconstruit et tight_layout purgé.")
PY

echo "[TEST] Re-génère fig05"
OUT_DIR="zz-out/chapter10"
DATA_DIR="zz-data/chapter10"
python3 "$F" --results "$DATA_DIR/dummy_results.csv" --out "$OUT_DIR/fig05_hist_cdf.png" --bins 40 --dpi 120

echo "[DONE] fig05 OK."

#!/usr/bin/env bash
set -euo pipefail

F="zz-scripts/chapter10/plot_fig05_hist_cdf_metrics.py"

echo "[PATCH] fig05: normalisation indentation + suppression des ';' sur les appels fig.*"

python3 - <<'PY'
import io, re, sys, pathlib
p = pathlib.Path("zz-scripts/chapter10/plot_fig05_hist_cdf_metrics.py")
s = p.read_text(encoding="utf-8")

# 1) Supprimer les ';' en fin de statements fig.* (si restant)
s = re.sub(r';\s*([\r\n])', r'\1', s)

# 2) Forcer l'indentation à 4 espaces pour les lignes clés fig=plt.gcf(), fig.text, fig.subplots_adjust, fig.savefig, print("Wrote")
def reindent(line: str) -> str:
    return "    " + line.lstrip()

lines = s.splitlines(True)
keys = ( "fig=plt.gcf()", "fig.text(", "fig.subplots_adjust(", "fig.savefig(", 'print(f"Wrote' )

for i, line in enumerate(lines):
    if any(k in line for k in keys):
        # Enlève tous les ';' résiduels sur la ligne
        line = line.replace(';', '')
        # Réindente à 4 espaces
        lines[i] = reindent(line)

# 3) Assurer l’ordre minimal des 4 appels (si l’utilisateur les a réordonnés), sans être trop intrusif.
#    On cherche un petit bloc compact contenant ces 3-5 lignes et on le réécrit dans l’ordre souhaité.
joined = "".join(lines)

# motif permissif capturant un bloc fin: fig.* lignes puis print Wrote
block_re = re.compile(
    r'(?P<prefix>[\s\S]*?)'
    r'(?P<block>'
    r'(?:(?:[ \t]*fig=plt\.gcf\(\).*\n)|'
    r'(?:[ \t]*fig\.text\(.*\)\s*\n)|'
    r'(?:[ \t]*fig\.subplots_adjust\(.*\)\s*\n)|'
    r'(?:[ \t]*fig\.savefig\(.*\)\s*\n)|'
    r'(?:[ \t]*print\(\s*f"Wrote\s*:.*\)\s*\n))+'
    r')'
    r'(?P<suffix>[\s\S]*)$',
    re.M
)

m = block_re.match(joined)
if m:
    prefix, block, suffix = m.group('prefix'), m.group('block'), m.group('suffix')
    # On ré-extrait les éléments du bloc pour reconstruire dans l'ordre propre
    has_gcf = "fig=plt.gcf()" in block
    has_text = "fig.text(" in block
    has_adj  = "fig.subplots_adjust(" in block
    has_save = "fig.savefig(" in block
    has_print= 'print(f"Wrote' in block

    new_block_lines = []
    if has_gcf:
        new_block_lines.append('    fig=plt.gcf()\n')
    if has_text:
        # garder la ligne originale fig.text(...) si possible
        m_text = re.search(r'^[ \t]*fig\.text\(.*\)\s*$', block, re.M)
        new_block_lines.append('    ' + m_text.group(0).lstrip() + '\n' if m_text else '    fig.text(0.5,0.04,foot,ha="center",va="bottom",fontsize=9)\n')
    if has_adj:
        m_adj = re.search(r'^[ \t]*fig\.subplots_adjust\(.*\)\s*$', block, re.M)
        new_block_lines.append('    ' + m_adj.group(0).lstrip() + '\n' if m_adj else '    fig.subplots_adjust(left=0.07,right=0.98,top=0.93,bottom=0.18)\n')
    if has_save:
        m_save = re.search(r'^[ \t]*fig\.savefig\(.*\)\s*$', block, re.M)
        new_block_lines.append('    ' + m_save.group(0).lstrip() + '\n' if m_save else '    fig.savefig(args.out, dpi=args.dpi)\n')
    if has_print:
        m_print = re.search(r'^[ \t]*print\(.*\)\s*$', block, re.M)
        new_block_lines.append('    ' + m_print.group(0).lstrip() + '\n' if m_print else '    print(f"Wrote : {args.out}")\n')

    joined = prefix + "".join(new_block_lines) + suffix

p.write_text(joined, encoding="utf-8")
print("[OK] fig05 normalisé.")
PY

echo "[TEST] Re-génère fig05 sans warning tight_layout ni erreur d indentation"
OUT_DIR="zz-out/chapter10"
DATA_DIR="zz-data/chapter10"
python3 "$F" --results "$DATA_DIR/dummy_results.csv" --out "$OUT_DIR/fig05_hist_cdf.png" --bins 40 --dpi 120

echo "[DONE] fig05 corrigé et testé."

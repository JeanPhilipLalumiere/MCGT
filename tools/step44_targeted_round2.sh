#!/usr/bin/env bash
set -euo pipefail
export PYTHONPATH="${PYTHONPATH:-}:$PWD"

tools/pass14_smoke_with_mapping.sh >/dev/null || true
tools/step32_report_remaining.sh   >/dev/null || true

python3 - <<'PY'
from pathlib import Path
import re, sys

lst = Path("zz-out/_remaining_files.lst")
if not lst.exists():
    print("[step44] rien à faire"); sys.exit(0)
files = [p for p in lst.read_text(encoding="utf-8").splitlines() if p and Path(p).exists()]

def ensure_import(s: str, mod: str) -> str:
    if re.search(rf'(?m)^\s*import\s+{re.escape(mod)}\b', s): return s
    m = re.search(r'(?ms)^(\s*(?:from\s+[^\n]+\n|import\s+[^\n]+\n)+)', s)
    return (m.group(0) + f"import {mod}\n" + s[m.end():]) if m else f"import {mod}\n{s}"

# ---- correctifs généraux ----

def fix_to_csv_call(s: str) -> str:
    # ...to_csv()base / "file"...  -> ...to_csv(base / "file" ...
    return re.sub(r'to_csv\(\)\s*([A-Za-z_][A-Za-z0-9_]*)\s*/', r'to_csv(\1 /', s)

def close_np_exp_if_open(s: str) -> str:
    # ... np.exp(  \n   -> np.exp(0)
    return re.sub(r'(?m)np\.exp\(\s*$','np.exp(0)', s)

def collapse_double_close_paren(s: str) -> str:
    # transforme ")\n    )\n" -> ")\n"
    return re.sub(r'(?ms)\)\s*\)\s*\n', ')\n', s)

def strip_leading_paren_commas(s: str) -> str:
    # lignes parasites commençant par "),"
    return re.sub(r'(?m)^\s*\),\s*', '', s)

def split_stuck_newline_after_close(s: str) -> str:
    # ")DH_calc" -> ")\nDH_calc", idem pour ")jalons"
    s = re.sub(r'\)\s*DH_calc', ')\nDH_calc', s)
    s = re.sub(r'\)\s*jalons', ')\njalons', s)
    return s

def remove_stray_raise(s: str) -> str:
    return re.sub(r'(?m)^\s*raise\s*$', '', s)

def remove_trypass_blocks(s: str) -> str:
    # supprime les blocs "try: pass ... except Exception: pass" factices
    return re.sub(
        r'(?ms)^(\s*)try:\s*\n\1\s*pass[^\n]*\n\1\s*except\s+Exception\s*:\s*\n\1\s*pass[^\n]*\n',
        '', s
    )

def fix_pcolormesh_any(s: str) -> str:
    # ax.pcolormesh()alpha_edges, q0_edges, chi2_mat, … -> ligne propre
    return re.sub(
        r'(?m)ax\.pcolormesh\(\).*',
        'ax.pcolormesh(alpha_edges, q0_edges, chi2_mat, shading="auto")',
        s
    )

def close_ax_plot_blocks(s: str) -> str:
    # si un bloc ax.plot( ... \n ... \n ax.xxx commence sans ')' -> ajoute ')'
    lines = s.splitlines(True)
    out = []
    open_plot = False
    indent = ''
    for idx, ln in enumerate(lines):
        if re.match(r'^\s*ax\.plot\(', ln):
            open_plot = True
            indent = re.match(r'^(\s*)', ln).group(1)
            out.append(ln); continue
        if open_plot and re.match(r'^\s*ax\.', ln):
            # insère une fermeture avant cette ligne
            if len(out) and not out[-1].rstrip().endswith(')'):
                out.append(indent + ')\n')
            open_plot = False
            out.append(ln); continue
        out.append(ln)
    # si fin de fichier et encore ouvert
    if open_plot and (not out[-1].rstrip().endswith(')')):
        out.append(indent + ')\n')
    return ''.join(out)

def remove_stray_except_lines(s: str) -> str:
    # 'except Exception:' sans corps
    return re.sub(r'(?m)^\s*except\s+Exception(?:\s+as\s+\w+)?\s*:\s*$', '', s)

# ---- correctifs ciblés par fichier ----

def fix_ch1_plot01_data_path(s: str) -> str:
    # data_path = (pathlib.Path(__file__).resolve().parents[2]  -> remet une affectation complète
    s = re.sub(
        r'(?ms)^(\s*)data_path\s*=\s*\(pathlib\.Path\(__file__\)\.resolve\(\)\.parents\[\s*2\s*\]\s*\)?[^\n]*?(?:\n\s*/[^\n]*\n)*',
        r'\1data_path = pathlib.Path(__file__).resolve().parents[2] / "zz-data" / "chapter01" / "01_optimized_data.csv"\n',
        s
    )
    return s

def fix_ch6_argparse_export_derivative(s: str) -> str:
    # remplace la ligne orpheline:  "--export-derivative", help=...
    return re.sub(
        r'(?m)^\s*"--export-derivative"\s*,\s*help\s*=\s*"[^"]*"\s*,?\s*$',
        'parser.add_argument("--export-derivative", action="store_true", help="Export derivative Δχ2/Δℓ")',
        s
    )

def fix_ch6_blocks_dict(s: str) -> str:
    # remplace inconditionnellement la section blocks par une version minimale correcte
    if "# --- Blocks definitions ---" not in s:
        return s
    indent = re.search(r'(?m)^(\s*)# --- Blocks definitions ---', s).group(1)
    replacement = (
        f'{indent}# --- Blocks definitions ---\n'
        f'{indent}blocks = {{\n'
        f'{indent}    "in": (0.05, Ymid, "pdot_plateau_z.dat", "#d7d7d7"),\n'
        f'{indent}    "scr": (0.36, Ymid, "generate_chapter06_data.py", "#a9dfbf"),\n'
        f'{indent}    "data": (0.70, Ymid, "data", "#cccccc"),\n'
        f'{indent}}}\n'
    )
    # remplace depuis la ligne 'blocks =' (si présente) sinon insère après l'entête
    if re.search(r'(?m)^\s*blocks\s*=\s*\{', s):
        s = re.sub(r'(?ms)^\s*#\s*---\s*Blocks definitions\s*---.*?(?=^\S|\Z)', replacement, s)
    else:
        s = re.sub(r'(?m)^(\s*#\s*---\s*Blocks definitions\s*---\s*\n)', r'\1' + replacement, s)
    return s

def fix_argparse_outdir_stubs(s: str) -> str:
    # supprime la ligne littérale '".ci-out"),' et garantit un add_argument propre
    s = re.sub(r'(?m)^\s*"\.ci-out"\),\s*$', '', s)
    if not re.search(r'(?m)parser\.add_argument\(\s*"--outdir"', s):
        s = ensure_import(s, "pathlib")
        s += '\nparser.add_argument("--outdir", type=pathlib.Path, default=pathlib.Path(".ci-out"))\n'
    return s

def fix_sorted_pngs_block(s: str) -> str:
    # retire les doubles ')' après sorted(...) et s’assure qu’on a l’import glob/os
    s = ensure_import(s, "os")
    s = ensure_import(s, "glob")
    s = collapse_double_close_paren(s)
    return s

def fix_axplot_commas_T(s: str) -> str:
    # en ch04: lignes qui commencent par '),T,' deviennent 'T,'
    return re.sub(r'(?m)^\s*\),\s*T\s*,', 'T,', s)

changed = 0
for p in files:
    fp = Path(p)
    s = fp.read_text(encoding='utf-8', errors='replace')

    orig = s

    # génériques
    s = fix_to_csv_call(s)
    s = close_np_exp_if_open(s)
    s = strip_leading_paren_commas(s)
    s = split_stuck_newline_after_close(s)
    s = fix_pcolormesh_any(s)
    s = close_ax_plot_blocks(s)
    s = remove_trypass_blocks(s)
    s = remove_stray_raise(s)
    s = remove_stray_except_lines(s)

    # spécifiques
    if fp.name == "plot_fig01_early_plateau.py":
        s = fix_ch1_plot01_data_path(s)

    if fp.name == "plot_fig00_spectrum.py":
        s = fix_sorted_pngs_block(s)

    if fp.name == "plot_fig04_pipeline_diagram.py":
        # rien d’autre ici pour l’instant (le dict blocks concerne ch06)
        pass

    if fp.name == "generate_data_chapter06.py":
        s = fix_ch6_argparse_export_derivative(s)

    if fp.name == "plot_fig01_cmb_dataflow_diagram.py":
        s = fix_ch6_blocks_dict(s)

    if fp.name in ("plot_fig04_delta_rs_vs_params.py", "plot_fig03_invariant_I1.py", "plot_fig04_dcs2_vs_k.py"):
        s = fix_argparse_outdir_stubs(s)

    if fp.name == "plot_fig04_relative_deviations.py":
        s = fix_axplot_commas_T(s)

    # enregistre si modifié
    if s != orig:
        fp.write_text(s, encoding='utf-8')
        changed += 1
        print(f"[STEP44-FIX] {p}")

print(f"[RESULT] step44_files_changed={changed}")
PY

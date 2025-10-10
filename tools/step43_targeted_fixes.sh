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
    print("[step43] rien à faire"); sys.exit(0)
files = [p for p in lst.read_text(encoding="utf-8").splitlines() if p and Path(p).exists()]

def ensure_import(s: str, mod: str) -> str:
    if re.search(rf'(?m)^\s*import\s+{re.escape(mod)}\b', s): return s
    # après les imports existants, sinon tout en haut
    m = re.search(r'(?ms)^(\s*(?:from\s+[^\n]+\n|import\s+[^\n]+\n)+)', s)
    return (m.group(0) + f"import {mod}\n" + s[m.end():]) if m else f"import {mod}\n{s}"

def drop_orphan_path_fragments(s: str) -> str:
    # lignes seules du type  / "zz-data", / "chapterXX", …
    return re.sub(r'(?m)^\s*/\s*"[^"\n]+"\s*,?\s*$', '', s)

def fix_multiline_path_assign(s: str) -> str:
    # Ferme les assignments style:
    # var = (pathlib.Path(__file__).resolve().parents[2]
    #        / "a" / "b" / "c")
    def add_closing(m):
        block = m.group(0)
        # Si le bloc ne contient pas déjà ')', ajoute une ligne de fermeture
        return block + ("" if block.rstrip().endswith(')') else m.group('i') + ")\n")
    pat = re.compile(
        r'(?ms)^(?P<i>\s*)(?P<var>\w+)\s*=\s*\(\s*pathlib\.Path\(\s*__file__\s*\)\.resolve\(\)\.parents\[\s*\d+\s*\]\s*(?:\n\s*/\s*"[^"\n]+"\s*)+\n'
    )
    return pat.sub(add_closing, s)

def fix_pngs_sorted_block(s: str) -> str:
    # Remplace un bloc 'pngs = sorted(' éclaté en version propre
    s = ensure_import(s, "glob")
    s = re.sub(
        r'(?ms)^(\s*)pngs\s*=\s*sorted\s*\(.*?reverse\s*=\s*True.*?(?:\)|$)',
        r'\1pngs = sorted(\n\1    glob.glob(os.path.join(_default_dir, "*.png")),\n\1    key=os.path.getmtime,\n\1    reverse=True\n\1)\n',
        s
    )
    # cas éclaté sans parenthèses repérables : de la ligne 'pngs = sorted' jusqu’à la 1re ligne contenant 'reverse=True'
    s = re.sub(
        r'(?ms)^(\s*)pngs\s*=\s*sorted[^\n]*\n.*?reverse\s*=\s*True[^\n]*\n',
        r'\1pngs = sorted(\n\1    glob.glob(os.path.join(_default_dir, "*.png")),\n\1    key=os.path.getmtime,\n\1    reverse=True\n\1)\n',
        s
    )
    return s

def fix_argv_out_try(s: str) -> str:
    # Transforme le couple i=_argv.index("--out") / _out=... + except orphelin en try/except
    s = re.sub(
        r'(?ms)^\s*i\s*=\s*_argv\.index\(\s*"--out"\s*\)\s*\n\s*_out\s*=\s*_argv\[\s*i\+1\s*\][^\n]*\n\s*except\s+Exception\s*:\s*\n\s*pass[^\n]*',
        'try:\n    i = _argv.index("--out")\n    _out = _argv[i+1] if i+1 < len(_argv) else None\nexcept Exception:\n    pass',
        s
    )
    return s

def fix_possible_paths_block(s: str) -> str:
    return re.sub(
        r'(?ms)^(\s*)possible_paths\s*=\s*\[\s*\n\s*"zz-data/chapter04/04_dimensionless_invariants\.csv"\s*,\s*\n\s*"/mnt/data/04_dimensionless_invariants\.csv"\s*,\s*\n\s*df\s*=\s*None',
        r'\1possible_paths = [\n\1    "zz-data/chapter04/04_dimensionless_invariants.csv",\n\1    "/mnt/data/04_dimensionless_invariants.csv",\n\1]\n\1df = None',
        s
    )

def close_pchip_calls(s: str) -> str:
    # Ajoute une ')' manquante après PchipInterpolator(... extrapolate=...)
    s = re.sub(
        r'(?ms)(PchipInterpolator\(\s*\n.*?extrapolate\s*=\s*(?:True|False)\s*,?\s*\n)',
        r'\1)', s
    )
    return s

def remove_gibberish_anyline(s: str) -> str:
    # Ligne résiduelle 'and not any( k, in, c.lower(), for, k, in( "d", "deriv" ))'
    return re.sub(r'(?m)^\s*and\s+not\s+any\(\s*k,\s*in,.*$', '', s)

def fix_argparse_header_ch6(s: str) -> str:
    # Ajoute ')' suite à "parser = argparse.ArgumentParser(" + description=...
    s = re.sub(
        r'(?ms)^(\s*parser\s*=\s*argparse\.ArgumentParser\()\s*\n(\s*description\s*=\s*"[^"]*")\s*\n',
        r'\1\n\2\n)\n',
        s
    )
    return s

def fix_pdot_tail(s: str) -> str:
    # Réécrit la terminaison main() > args/try/except propre
    return re.sub(
        r'(?ms)args\s*=\s*parser\.parse_args\(\).*?\Z',
        'args = parser.parse_args()\n'
        'try:\n'
        '    _main(args)\n'
        'except SystemExit:\n'
        '    pass\n'
        'except Exception as e:\n'
        '    print(f"[CLI seed] main() a levé: {e}", file=sys.stderr)\n'
        '    traceback.print_exc()\n',
        s
    )

def fix_blocks_data_close(s: str) -> str:
    # Clôt le dict blocks si "data": ( est laissé ouvert
    s = re.sub(
        r'(?m)^(\s*"data"\s*:\s*\()\s*$',
        r'\10.70, Ymid, "data", "#cccccc"),\n}',
        s
    )
    return s

def close_plot_before_next_ax(s: str) -> str:
    # Ajoute un ')' manquant juste avant la prochaine ligne qui commence par 'ax.' ou 'plt.'
    s = re.sub(
        r'(?ms)^(?P<i>\s*ax\.plot\([^\n]*\n(?:^(?!\s*(?:ax|plt)\.).*\n)+)(?=^\s*(?:ax|plt)\.)',
        lambda m: m.group('i').rstrip('\n') + ')\n',
        s
    )
    return s

def fix_pcolormesh_block(s: str) -> str:
    # Répare pcolormesh éclaté
    return re.sub(
        r'(?ms)ax\.pcolormesh\)[^\n]*\n',
        'ax.pcolormesh(alpha_edges, q0_edges, chi2_mat, shading="auto")\n',
        s
    )

def fix_except_pass_indent(s: str) -> str:
    # Uniformise except/finally/else/elif + pass indenté
    return re.sub(r'(?m)^(\s*(?:except[^\n]*|finally|else|elif[^\n]*):\s*)\n\s*pass\b', r'\1\n    pass', s)

def drop_stray_except_in_ch7(fp: Path, s: str) -> str:
    if fp.name not in ("plot_fig01_cs2_heatmap.py", "plot_fig02_delta_phi_heatmap.py"):
        return s
    # Supprime 'except Exception:' ou 'except Exception as e:' isolés
    s = re.sub(r'(?m)^\s*except\s+Exception(?:\s+as\s+\w+)?\s*:\s*$', '# stray except removed', s)
    return s

changed = 0
for p in files:
    fp = Path(p)
    s = fp.read_text(encoding='utf-8', errors='replace')

    s2 = s
    s2 = drop_orphan_path_fragments(s2)
    s2 = fix_multiline_path_assign(s2)
    s2 = fix_pngs_sorted_block(s2)
    s2 = fix_argv_out_try(s2)
    s2 = fix_possible_paths_block(s2)
    s2 = close_pchip_calls(s2)
    s2 = remove_gibberish_anyline(s2)
    s2 = fix_argparse_header_ch6(s2)
    if fp.name == "generate_pdot_plateau_vs_z.py":
        s2 = fix_pdot_tail(s2)
    if fp.name == "plot_fig01_cmb_dataflow_diagram.py":
        s2 = fix_blocks_data_close(s2)
    if fp.name == "plot_fig03_delta_cls_relative.py":
        s2 = close_plot_before_next_ax(s2)
    if fp.name == "plot_fig05_delta_chi2_heatmap.py":
        s2 = fix_pcolormesh_block(s2)
    s2 = fix_except_pass_indent(s2)
    s2 = drop_stray_except_in_ch7(fp, s2)

    if s2 != s:
        fp.write_text(s2, encoding='utf-8')
        changed += 1
        print(f"[STEP43-FIX] {p}")

print(f"[RESULT] step43_files_changed={changed}")
PY

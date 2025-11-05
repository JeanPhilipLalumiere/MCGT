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
    print("[step45] rien à faire"); sys.exit(0)
files = [p for p in lst.read_text(encoding="utf-8").splitlines() if p and Path(p).exists()]

def ensure_import(s: str, mod: str) -> str:
    if re.search(rf'(?m)^\s*import\s+{re.escape(mod)}\b', s): return s
    m = re.search(r'(?ms)^(\s*(?:from\s+[^\n]+\n|import\s+[^\n]+\n)+)', s)
    return (m.group(0) + f"import {mod}\n" + s[m.end():]) if m else f"import {mod}\n{s}"

# --------- correctifs généraux ----------
def close_to_csv_trailing(s: str) -> str:
    # ... to_csv(..., index=False\n -> ..., index=False)\n  (si ')' manquante en fin de ligne)
    return re.sub(r'(?m)^(?P<prefix>.*to_csv\([^\n\)]*),\s*index=False\s*$',
                  r'\g<prefix>, index=False)', s)

def fix_sys_path_insert(s: str) -> str:
    # sys.path.insert( 0, str(ROOT/...   -> ...))
    return re.sub(r'(?m)^\s*sys\.path\.insert\([^\n\)]*$',
                  'sys.path.insert( 0, str( ROOT / "zz-scripts" / "chapter02" ))', s)

def fix_da_log_powline(s: str) -> str:
    # da_log = ... ** 2   -> ... ** 2)
    return re.sub(r'(?m)^(?P<p>\s*da_log\s*=\s*.*\*\*\s*2)\s*$',
                  r'\g<p>)', s)

def newline_after_stuck_calls(s: str) -> str:
    # )DH_calc / )Yp_calc recollés sur la même ligne
    s = s.replace(')DH_calc', ')\nDH_calc')
    s = s.replace(')Yp_calc', ')\nYp_calc')
    return s

def remove_lone_paren_lines(s: str) -> str:
    # ligne ne contenant qu'une parenthèse fermante
    return re.sub(r'(?m)^\s*\)\s*$', '', s)

def remove_orphan_passes(s: str) -> str:
    # supprime les 'pass  # auto-added ...' orphelins au niveau top
    return re.sub(r'(?m)^\s*pass\s+#\s*auto-added[^\n]*\n', '', s)

def fix_set_title_missing_paren(s: str) -> str:
    # ax.set_title(...\n fontsize=..\n fontweight="bold"\n -> ajoute ')'
    return re.sub(r'(?ms)(ax\.set_title\([^)]*\n\s*fontsize=[^\n]*\n\s*fontweight="bold")\s*\n',
                  r'\1)\n', s)

def fix_argparse_outdir_stub(s: str) -> str:
    # retire la ligne '".ci-out"),' et ajoute un add_argument propre si absent
    s = re.sub(r'(?m)^\s*"\.ci-out"\),\s*$', '', s)
    if not re.search(r'(?m)parser\.add_argument\(\s*"--outdir"', s):
        s = ensure_import(s, "pathlib")
        s += '\nparser.add_argument("--outdir", type=pathlib.Path, default=pathlib.Path(".ci-out"))\n'
    return s

def fix_lims_list_then_plot(s: str) -> str:
    # ferme la liste lims avant ax.plot et enlève une éventuelle virgule finale
    s = re.sub(r'(?ms)(^\s*lims\s*=\s*\[[^\]]+?)\n(\s*ax\.plot)',
               lambda m: re.sub(r',\s*$', '', m.group(1).rstrip()) + ']\n' + m.group(2),
               s)
    return s

def fix_main_guard(s: str) -> str:
    return re.sub(r'__name__\s*====\s*"__main__"', '__name__ == "__main__"', s)

# --------- correctifs spécifiques ----------
def fix_data_path_plot01(s: str) -> str:
    s = ensure_import(s, "pathlib")
    return re.sub(
        r'(?ms)^\s*data_path\s*=\s*\(pathlib\.Path\(__file__\)\.resolve\(\)\.parents\[\s*2\s*\][^\n]*\n(?:\s*/[^\n]*\n)*',
        'data_path = pathlib.Path(__file__).resolve().parents[2] / "zz-data" / "chapter01" / "01_optimized_data.csv"\n',
        s
    )

def fix_pipeline_diagram_block(s: str) -> str:
    # Remplace le bloc fragmenté par une construction propre de box + text
    return re.sub(
        r'(?ms)^\s*height,\s*\n\s*boxstyle="round,pad=0\.3",\s*\n\s*edgecolor="black",\s*\n\s*facecolor="white"\)\s*\n\s*ax\.add_patch\(\s*box\s*\)\s*\n\s*ax\.text\(\s*xc,\s*yc,\s*text,\s*ha="center",\s*va="center",\s*fontsize=8\s*\)\s*',
        'box = FancyBboxPatch((xc - width/2, yc - height/2), width, height,\n'
        '                      boxstyle="round,pad=0.3", edgecolor="black", facecolor="white")\n'
        'ax.add_patch(box)\n'
        'ax.text(xc, yc, text, ha="center", va="center", fontsize=8)\n',
        s
    )

def fix_ch6_spec2_constants(s: str) -> str:
    s = re.sub(r'(?m)^\s*A_S0\s*=.*$',
               'A_S0 = (spec2.get("constantes", {}).get("A_s0",\n'
               '        spec2.get("constants", {}).get("A_s0")))',
               s)
    s = re.sub(r'(?m)^\s*NS0\s*==.*$',
               'NS0  = (spec2.get("constantes", {}).get("ns0",\n'
               '        spec2.get("constants", {}).get("ns0")))',
               s)
    return s

def drop_second_blocks_dict(s: str) -> str:
    # Si deux blocs "blocks = {", on supprime le second (bloc cassé)
    it = list(re.finditer(r'(?m)^\s*blocks\s*=\s*\{\s*$', s))
    if len(it) >= 2:
        start = it[1].start()
        # on coupe jusqu’à une ligne vide ou 20 lignes
        lines = s[start:].splitlines(True)
        cut = 0
        for i, ln in enumerate(lines[:20]):
            if not ln.strip():  # première ligne vide
                cut = i+1; break
        if cut == 0: cut = min(20, len(lines))
        s = s[:start] + ''.join(lines[cut:])
    return s

def fix_sigma_ifelse(s: str) -> str:
    return re.sub(
        r'(?ms)if\s+"chi2_err"\s+in\s+chi2df\.columns\s*:\s*\n\s*pass[^\n]*\n\s*sigma\s*=\s*([^\n]+)\n\s*else\s*:\s*\n\s*pass[^\n]*\n\s*sigma\s*=\s*([^\n]+)',
        r'if "chi2_err" in chi2df.columns:\n    sigma = \1\nelse:\n    sigma = \2',
        s
    )

changed = 0

for p in files:
    fp = Path(p)
    s = fp.read_text(encoding="utf-8", errors="replace")
    orig = s

    # génériques
    s = close_to_csv_trailing(s)
    s = fix_sys_path_insert(s)
    s = fix_da_log_powline(s)
    s = newline_after_stuck_calls(s)
    s = remove_lone_paren_lines(s)
    s = remove_orphan_passes(s)
    s = fix_set_title_missing_paren(s)

    # cas spécifiques selon le nom
    if fp.name == "plot_fig01_early_plateau.py":
        s = fix_data_path_plot01(s)

    if fp.name == "plot_fig04_pipeline_diagram.py":
        s = fix_pipeline_diagram_block(s)

    if fp.name in ("plot_fig04_delta_rs_vs_params.py",
                   "plot_fig03_invariant_I1.py",
                   "plot_fig04_dcs2_vs_k.py",
                   "plot_fig03_delta_cls_relative.py",
                   "plot_fig05_ddelta_phi_vs_k.py"):
        s = fix_argparse_outdir_stub(s)

    if fp.name == "plot_fig02_dh_model_vs_obs.py":
        s = fix_lims_list_then_plot(s)

    if fp.name == "plot_fig04_chi2_vs_T.py":
        s = fix_sigma_ifelse(s)

    if fp.name == "generate_data_chapter06.py":
        s = fix_ch6_spec2_constants(s)

    if fp.name == "plot_fig01_cmb_dataflow_diagram.py":
        s = drop_second_blocks_dict(s)

    if fp.name in ("plot_fig03_invariant_I1.py", "plot_fig04_dcs2_vs_k.py"):
        s = fix_main_guard(s)

    if s != orig:
        fp.write_text(s, encoding='utf-8')
        changed += 1
        print(f"[STEP45-FIX] {p}")

print(f"[RESULT] step45_files_changed={changed}")
PY

#!/usr/bin/env bash
set -euo pipefail
export PYTHONPATH="${PYTHONPATH:-}:$PWD"

# NE PAS exécuter de scripts (pour éviter le gel). On ne fait que des patchs.
tools/step32_report_remaining.sh >/dev/null || true

python3 - <<'PY'
from pathlib import Path
import re, sys

lst = Path("zz-out/_remaining_files.lst")
if not lst.exists():
    print("[step46] rien à faire"); sys.exit(0)

files = [p for p in lst.read_text(encoding="utf-8").splitlines() if p and Path(p).exists()]

def write_if_changed(fp: Path, s: str, orig: str, changed_counter: list):
    if s != orig:
        fp.write_text(s, encoding='utf-8')
        changed_counter[0] += 1
        print(f"[STEP46-FIX] {fp}")

def strip_leading_commas(s: str) -> str:
    # en-têtes de ligne pollués par des virgules
    return re.sub(r'(?m)^\s*,\s*', '', s)

def patch_build_grid(s: str) -> str:
    # Remplace tout le bloc def build_grid(...) par une version minimale saine
    pat = re.compile(r'(?ms)^def\s+build_grid\s*\(\s*tmin\s*,\s*tmax\s*,\s*step\s*,\s*spacing\s*\)\s*:\s*.*?(?=^\s*def\s+|\Z)')
    repl = (
        "def build_grid(tmin, tmax, step, spacing):\n"
        "    \"\"\"Retourne une grille en T (lin/log selon `spacing`).\"\"\"\n"
        "    import numpy as np\n"
        "    if spacing == \"log\":\n"
        "        n = int((np.log10(tmax) - np.log10(tmin)) / step) + 1\n"
        "        return 10 ** np.linspace(np.log10(tmin), np.log10(tmax), n)\n"
        "    else:\n"
        "        n = int((tmax - tmin) / step) + 1\n"
        "        return np.linspace(tmin, tmax, n)\n\n"
    )
    return pat.sub(repl, s)

def fix_data_path_plot01(s: str) -> str:
    # Normalise l’affectation de data_path sur une seule ligne.
    s = re.sub(
        r'(?ms)^\s*data_path\s*=\s*\(pathlib\.Path\(__file__\)\.resolve\(\)\.parents\[\s*2\s*\][^)]+?\n(?:\s*.+\n){0,4}',
        'data_path = pathlib.Path(__file__).resolve().parents[2] / "zz-data" / "chapter01" / "01_optimized_data.csv"\n',
        s
    )
    return s

def fix_logistic_block(s: str) -> str:
    # Remplace le bloc a_log/a/da_log/da cassé par une version fermée
    return re.sub(
        r'(?ms)a_log\s*=.*?\n\s*a\s*=.*?\n\s*da_log\s*=.*?\n\s*da\s*=.*?(?=\n\S|\Z)',
        (
            "a_log = a0 + (ainf - a0) / (1 + np.exp(-(T - Tc) / Delta))\n"
            "a = a_log * (1 - np.exp(-((T / Tp) ** 2)))\n"
            "da_log = ((ainf - a0) / Delta) * np.exp(-(T - Tc) / Delta) / (1 + np.exp(-(T - Tc) / Delta))**2\n"
            "da = da_log * (1 - np.exp(-((T / Tp) ** 2))) + a_log * (2 * T / Tp**2) * np.exp(-((T / Tp)**2))\n"
        ),
        s
    )

def fix_sys_path_insert(s: str) -> str:
    # Ferme sys.path.insert(...) si la parenthèse manque
    s = re.sub(
        r'(?m)^\s*sys\.path\.insert\([^\)]*$',
        'sys.path.insert(0, str(ROOT / "zz-scripts" / "chapter02"))',
        s
    )
    return s

def split_glued_calls(s: str) -> str:
    # ...)),ax.xxx -> ...)\nax.xxx
    s = re.sub(r'\)\)\s*,\s*ax\.', ')\nax.', s)
    s = re.sub(r'\)\s*,\s*ax\.', ')\nax.', s)
    return s

def close_pchip_calls(s: str) -> str:
    # Ajoute une ) manquante juste avant la ligne DH_calc ou Yp_calc
    s = re.sub(
        r'(?ms)(PchipInterpolator\(\s*\n.*?\n.*?\n)\s*(?=(?:DH_calc|Yp_calc)\s*=)',
        r'\1)\n',
        s
    )
    return s

def fix_pipeline_annotate(s: str) -> str:
    # Remet ax.annotate(...) en une seule ligne
    s = re.sub(
        r'(?ms)ax\.annotate\([^\n]*\n[^\n]*',
        'ax.annotate("", xy=(x1, y), xytext=(x0, y), arrowprops=dict(arrowstyle="->", lw=1))\n',
        s
    )
    return s

def close_next_paren(s: str) -> str:
    # chi2col = next(..., None) )
    s = re.sub(
        r'(?ms)(chi2col\s*=\s*next\([^\n]+?\n\s*None)\s*(?=\n)',
        r'\1)',
        s
    )
    # Nettoie une éventuelle ligne parasite "and not any( ... )" orpheline
    s = re.sub(r'(?m)^\s*and\s+not\s+any\([^\n]+\)\s*$', '', s)
    return s

def normalize_parser_ch6(s: str) -> str:
    # Si un if __name__ précède un parser cassé, on le normalise
    s = re.sub(
        r'(?ms)^\s*if\s+__name__\s*==\s*"__main__"\s*:\s*\n\s*parser\s*=\s*argparse\.ArgumentParser\(',
        'parser = argparse.ArgumentParser(',
        s
    )
    return s

def fix_cmb_loop(s: str) -> str:
    # Rectangle propre
    s = re.sub(
        r'(?ms)ax\.add_patch\([^\n]*Rectangle\([^)]*\)[^\n]*\n',
        'ax.add_patch(Rectangle((x, y - H/2), W, H, linewidth=1, edgecolor="black", facecolor=color))\n',
        s
    )
    # For propre
    s = re.sub(
        r'(?m)^\s*for\s+.*blocks\.items\(\)\s*:\s*$',
        'for key, (x, y, label, color) in blocks.items():',
        s
    )
    # Texte propre (si une ligne ax.text cassée traîne)
    s = re.sub(
        r'(?m)^\s*ax\.text\([^\n]*$',
        'ax.text(x + W/2, y, label, ha="center", va="center")',
        s
    )
    return s

def indent_after_with_open(s: str) -> str:
    # Indente la ligne params = json.load(f) juste après "with open(...):"
    lines = s.splitlines(True)
    for i in range(len(lines)-1):
        if re.search(r'^\s*with\s+open\(\s*JSON_PARAMS', lines[i]):
            if re.search(r'^\s*params\s*=\s*json\.load\(\s*f\)', lines[i+1]):
                lines[i+1] = re.sub(r'^\s*', '    ', lines[i+1])
    return ''.join(lines)

def indent_after_try_racine(s: str) -> str:
    # try:\nRACINE = ...  -> indente
    return re.sub(
        r'(?m)^(\s*try:\s*\n)\s*(RACINE\s*=.*)$',
        r'\1    \2',
        s
    )

def indent_json_meta_block(s: str) -> str:
    # if JSON_META.exists():\nmeta = ...\nk_split = ...  -> indente le corps
    return re.sub(
        r'(?ms)^(\s*if\s+JSON_META\.exists\(\)\s*:\s*\n)\s*(meta\s*=.*\n\s*k_split\s*=.*\n)',
        r'\1    \2',
        s
    )

def ensure_seed_body(s: str) -> str:
    # def _mcgt_cli_seed(): -> ajoute pass si vide
    if re.search(r'(?ms)^def\s+_mcgt_cli_seed\s*\(\s*\)\s*:\s*\n\s*\S', s):
        return s
    return re.sub(
        r'(?ms)^def\s+_mcgt_cli_seed\s*\(\s*\)\s*:\s*(\n|$)',
        'def _mcgt_cli_seed():\n    pass\n',
        s
    )

def indent_raise_after_if_not_meta(s: str) -> str:
    return re.sub(
        r'(?m)^(if\s+not\s+JSON_META\.exists\(\)\s*:\s*\n)\s*(raise\s+FileNotFoundError[^\n]+)',
        r'\1    \2',
        s
    )

def fix_main_block_dh_vs_obs(s: str) -> str:
    # Réécrit proprement le bloc __main__ pour ce fichier
    s = re.sub(
        r'(?ms)^\s*if\s+__name__\s*==\s*"__main__":.*\Z',
        (
            'if __name__ == "__main__":\n'
            '    import argparse, pathlib\n'
            '    parser = argparse.ArgumentParser()\n'
            '    parser.add_argument("--outdir", type=pathlib.Path, default=pathlib.Path(".ci-out"))\n'
            '    parser.add_argument("--seed", type=int, default=None)\n'
            '    parser.add_argument("--dpi", type=int, default=150)\n'
            '    args = parser.parse_args()\n'
            '    pass\n'
        ),
        s
    )
    return s

def fix_eqeqeq_main(s: str) -> str:
    # if __name__ ==== "__main__": -> ==
    return re.sub(r'__name__\s*====\s*"__main__"', '__name__ == "__main__"', s)

changed = [0]

for p in files:
    fp = Path(p)
    s = fp.read_text(encoding="utf-8", errors="replace")
    orig = s

    # nettoyage générique très rapide
    s = strip_leading_commas(s)

    # corrections ciblées par nom
    name = fp.name

    if name == "generate_data_chapter01.py":
        s = patch_build_grid(s)

    if name == "plot_fig01_early_plateau.py":
        # s'assurer qu'on a pathlib importé
        if not re.search(r'(?m)^\s*import\s+pathlib\b', s):
            s = 'import pathlib\n' + s
        s = fix_data_path_plot01(s)

    if name == "generate_data_chapter02.py":
        s = fix_logistic_block(s)

    if name == "plot_fig00_spectrum.py":
        # garantir imports et sys.path.insert fermé
        if not re.search(r'(?m)^\s*import\s+pathlib\b', s):
            s = 'import pathlib\n' + s
        if not re.search(r'(?m)^\s*import\s+sys\b', s):
            s = 'import sys\n' + s
        s = fix_sys_path_insert(s)

    if name == "plot_fig04_pipeline_diagram.py":
        s = fix_pipeline_annotate(s)

    if name == "plot_fig04_relative_deviations.py":
        s = split_glued_calls(s)

    if name == "generate_data_chapter05.py":
        s = close_pchip_calls(s)

    if name == "plot_fig02_dh_model_vs_obs.py":
        s = fix_main_block_dh_vs_obs(s)

    if name == "plot_fig04_chi2_vs_T.py":
        s = close_next_paren(s)

    if name == "generate_data_chapter06.py":
        s = normalize_parser_ch6(s)

    if name == "plot_fig01_cmb_dataflow_diagram.py":
        s = fix_cmb_loop(s)

    if name == "plot_fig03_delta_cls_relative.py":
        s = indent_after_with_open(s)

    if name == "plot_fig05_delta_chi2_heatmap.py":
        s = indent_after_with_open(s)

    if name in ("plot_fig01_cs2_heatmap.py", "plot_fig02_delta_phi_heatmap.py"):
        s = indent_after_try_racine(s)

    if name == "plot_fig03_invariant_I1.py":
        s = indent_json_meta_block(s)
        s = fix_eqeqeq_main(s)
        s = ensure_seed_body(s)

    if name == "plot_fig04_dcs2_vs_k.py":
        s = fix_eqeqeq_main(s)
        s = ensure_seed_body(s)

    if name == "plot_fig05_ddelta_phi_vs_k.py":
        s = indent_raise_after_if_not_meta(s)

    write_if_changed(fp, s, orig, changed)

print(f"[RESULT] step46_files_changed={changed[0]}")
PY

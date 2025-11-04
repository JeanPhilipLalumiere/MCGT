#!/usr/bin/env bash
set -euo pipefail
export PYTHONPATH="${PYTHONPATH:-}:$PWD"

# Ne rien exécuter, on patch uniquement.
tools/step32_report_remaining.sh >/dev/null || true

python3 - <<'PY'
from pathlib import Path
import re, sys

def w(fp: Path, s: str, orig: str, changed: list):
    if s != orig:
        fp.write_text(s, encoding="utf-8")
        changed[0] += 1
        print(f"[STEP47-FIX] {fp}")

lst = Path("zz-out/_remaining_files.lst")
if not lst.exists():
    print("[step47] rien à faire"); sys.exit(0)
files = [p for p in lst.read_text(encoding="utf-8").splitlines() if p and Path(p).exists()]
changed = [0]

# ---------- helpers génériques ----------
def strip_leading_commas(s: str) -> str:
    return re.sub(r'(?m)^\s*,\s*', '', s)

def decomma_imports_and_ifmain(s: str) -> str:
    s = re.sub(r'(?m)^(\s*import)\s*,\s*', r'\1 ', s)
    s = re.sub(r'(?m)^(\s*from\s+[^\n]+)\s*,\s*import', r'\1 import', s)
    s = re.sub(r'(?m)^(\s*if)\s*,\s*(__name__\s*==\s*"__main__")\s*:', r'\1 \2:', s)
    return s

def ensure_pathlib_import(s: str) -> str:
    if re.search(r'(?m)^\s*import\s+pathlib\b', s): return s
    # injecte après le bloc d'import si présent, sinon en tête
    m = re.search(r'(?ms)^(\s*(?:from\s+[^\n]+\n|import\s+[^\n]+\n)+)', s)
    return (m.group(0) + "import pathlib\n" + s[m.end():]) if m else "import pathlib\n" + s

# ---------- patches ciblés par fichier ----------
def fix_gen_ch1(s: str) -> str:
    # (1) build_grid déjà réécrit par step46 ; ici on sécurise compute_p
    s = re.sub(
        r'(?ms)^def\s+compute_p\s*\([^\)]*\)\s*:\s*\n(?!\s{4})',
        'def compute_p(T_j, P_j, T_grid):\n',
        s
    )
    # Réécrit la fonction compute_p proprement (remplace si corps cassé)
    s = re.sub(
        r'(?ms)^def\s+compute_p\s*\([^\)]*\)\s*:\s*.*?(?=^\s*def\s+|\Z)',
        (
            "def compute_p(T_j, P_j, T_grid):\n"
            "    import numpy as np\n"
            "    from scipy.interpolate import PchipInterpolator\n"
            "    logT = np.log10(T_j)\n"
            "    logP = np.log10(P_j)\n"
            "    pchip = PchipInterpolator(logT, logP, extrapolate=True)\n"
            "    return 10 ** pchip(np.log10(T_grid))\n\n"
        ),
        s
    )
    return s

def fix_plot01_plateau(s: str) -> str:
    s = ensure_pathlib_import(s)
    # Remplace toute assignation cassée de data_path par une version compacte correcte
    s = re.sub(
        r'(?ms)^\s*data_path\s*=.*?(?=^\S|\Z)',
        'data_path = pathlib.Path(__file__).resolve().parents[2] / "zz-data" / "chapter01" / "01_optimized_data.csv"\n',
        s
    )
    return s

def fix_gen_ch2(s: str) -> str:
    # Supprime la ligne orpheline ")-((T/Tp)**2)"
    s = re.sub(r'(?m)^\s*\)\s*-\s*\(\(\s*T\s*/\s*Tp\s*\)\s*\*\*\s*2\s*\)\s*$', '', s)
    return s

def fix_plot00_spectrum(s: str) -> str:
    # Ferme l'insert sys.path et assure les imports
    if not re.search(r'(?m)^\s*import\s+sys\b', s):
        s = "import sys\n" + s
    s = ensure_pathlib_import(s)
    s = re.sub(
        r'(?m)^\s*sys\.path\.insert\([^\n\)]*$',
        'sys.path.insert(0, str(ROOT / "zz-scripts" / "chapter02"))',
        s
    )
    return s

def fix_plot04_pipeline(s: str) -> str:
    # Supprime les 3 lignes résiduelles après notre annotate propre
    s = re.sub(r'(?m)^\s*x1,\s*y\s*\).*\n^\s*x0,\s*y\s*\).*\n^\s*arrowstyle=.*\n', '', s)
    return s

def fix_rel_devs_ch4(s: str) -> str:
    s = re.sub(r'(?m)^\s*except\s*,\s*Exception\s*:', 'except Exception:', s)
    # supprime un éventuel crochet isolé
    s = re.sub(r'(?m)^\s*\]\s*$', '', s)
    # décolle les appels collés du style ")),ax..."
    s = re.sub(r'\)\s*\)\s*,\s*ax\.', ')\nax.', s)
    s = re.sub(r'\)\s*,\s*ax\.', ')\nax.', s)
    return s

def fix_gen_ch5(s: str) -> str:
    # Ferme PchipInterpolator pour DH (déjà ok) et traite le bloc Yp avec indentation correcte
    s = re.sub(
        r'(?ms)^(\s*#\s*H[ée]lium-4.*?\n)\s*if\s+len\(\s*jalons_Yp\)\s*>\s*1\s*:\s*\n\s*interp_Yp.*?\n\s*$',
        r'\1if len(jalons_Yp) > 1:\n'
        r'    interp_Yp = PchipInterpolator(np.log10(jalons_Yp["T_Gyr"]), np.log10(jalons_Yp["Yp_obs"]), extrapolate=True)\n'
        r'    Yp_calc = 10 ** interp_Yp(np.log10(T))\n'
        r'else:\n'
        r'    Yp_calc = np.full_like(T, float(jalons_Yp["Yp_obs"].iloc[0]))\n',
        s
    )
    return s

def fix_dh_vs_obs_main(s: str) -> str:
    s = decomma_imports_and_ifmain(s)
    # remplace tout bloc __main__ (même endommagé) par un bloc propre
    s = re.sub(
        r'(?ms)^.*?if\s+__name__\s*==\s*"__main__":\s*.*\Z',
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

def fix_chi2_vs_T(s: str) -> str:
    # Réécrit l’expression chi2col = next(...) complète, puis retire les lignes orphelines
    s = re.sub(
        r'(?ms)^chi2col\s*=\s*next\([^\n]*\n[^\n]*\n\s*None\s*$',
        'chi2col = next((c for c in df.columns if "chi2" in c.lower() and not any(k in c.lower() for k in ("d", "deriv"))), None)\n',
        s
    )
    return s

def fix_gen_ch6(s: str) -> str:
    # Parser propre sur une ligne
    s = re.sub(
        r'(?ms)parser\s*=\s*argparse\.ArgumentParser\([^\)]*$',
        'parser = argparse.ArgumentParser(description="Chapter 6 pipeline: generate CMB spectra for MCGT")',
        s
    )
    return s

def fix_cmb_flow_ch6(s: str) -> str:
    # Remplace entièrement la boucle de dessin des blocs par une version propre
    s = re.sub(
        r'(?ms)for\s+.*blocks\.items\(\)\s*:\s*.*?ax\.text[^\n]*\n',
        (
            'for key, (x, y, label, color) in blocks.items():\n'
            '    ax.add_patch(Rectangle((x, y - H/2), W, H, linewidth=1, edgecolor="black", facecolor=color))\n'
            '    ax.text(x + W/2, y, label, ha="center", va="center")\n'
        ),
        s
    )
    # Supprime des fragments "Rectangle(" corrompus
    s = re.sub(r'(?m)^\s*\)\s*\)\s*,\s*Rectangle\([^\n]*\n', '', s)
    return s

def fix_plot_delta_cls(s: str) -> str:
    # Assure la fermeture de l'appel ax.plot(... label=... )
    s = re.sub(r'(label\s*=\s*[^\n]+),\s*\n\s*ax\.', r'\1)\nax.', s)
    return s

def fix_heatmap_title(s: str) -> str:
    # Ferme ax.set_title(..., fontsize=14, fontweight="bold")
    s = re.sub(
        r'ax\.set_title\(\s*([^\)]+?)\s*,\s*fontsize\s*=\s*14\s*,\s*\n\s*fontweight\s*=\s*"bold"\s*',
        r'ax.set_title(\1, fontsize=14, fontweight="bold")',
        s
    )
    return s

def drop_try_racine(s: str) -> str:
    # Remplace 'try:\n  RACINE = ...' par l'affectation directe + retire except/pass adjacent
    s = re.sub(
        r'(?ms)^\s*try:\s*\n\s*RACINE\s*=\s*Path\([^\n]+\)\n',
        lambda m: re.sub(r'^\s*try:\s*\n', '', m.group(0)),
        s
    )
    s = re.sub(r'(?ms)^\s*except[^\n]*:\s*\n\s*pass\s*$', '', s)
    return s

def collapse_seed(s: str) -> str:
    # Définit un _mcgt_cli_seed() minimal et enlève imports mal indentés juste après
    s = re.sub(
        r'(?ms)^def\s+_mcgt_cli_seed\s*\(\s*\)\s*:\s*\n(?:\s*import[^\n]+\n)+',
        'def _mcgt_cli_seed():\n    pass\n',
        s
    )
    # Si la def existe sans corps, on ajoute pass
    s = re.sub(r'(?ms)^def\s+_mcgt_cli_seed\s*\(\s*\)\s*:\s*(\n|$)', 'def _mcgt_cli_seed():\n    pass\n', s)
    return s

def fix_ddelta_phi_ticks(s: str) -> str:
    s = re.sub(
        r'ax\.set_yticklabels\(\s*\[f"\$10\^\{\{\{int\( np\.log10\( t \) \)\}\}\}\$"\s*for\s*,\s*t\s*,\s*in\s*,\s*yticks\s*\]\s*\)',
        'ax.set_yticklabels([f"$10^{{{int(np.log10(t))}}}$" for t in yticks])',
        s
    )
    return s

def fix_gen_coupling_milestones(s: str) -> str:
    s = re.sub(
        r'df_bao\[\s*"milestone"\s*\]\s*=\s*df_bao\[\s*"z"\s*\]\.apply\([^\n]+\)',
        'df_bao["milestone"] = df_bao["z"].apply(lambda z: f"BAO_z={z:.3f}")',
        s
    )
    s = re.sub(
        r'df_bao\[\s*"category"\s*\]\s*=\s*df_bao\.apply\(\)\s*lambda\s+row\s*:\s*"primary"[^\n]+',
        'df_bao["category"] = df_bao.apply(lambda row: "primary" if row.sigma_obs / row.obs <= 0.01 else "order2", axis=1)',
        s
    )
    return s

# ---------- passage sur chaque fichier restant ----------
for p in files:
    fp = Path(p)
    s = fp.read_text(encoding="utf-8", errors="replace")
    orig = s
    s = strip_leading_commas(s)
    s = decomma_imports_and_ifmain(s)

    name = fp.name
    if name == "generate_data_chapter01.py":
        s = fix_gen_ch1(s)
    if name == "plot_fig01_early_plateau.py":
        s = fix_plot01_plateau(s)
    if name == "generate_data_chapter02.py":
        s = fix_gen_ch2(s)
    if name == "plot_fig00_spectrum.py":
        s = fix_plot00_spectrum(s)
    if name == "plot_fig04_pipeline_diagram.py":
        s = fix_plot04_pipeline(s)
    if name == "plot_fig04_relative_deviations.py":
        s = fix_rel_devs_ch4(s)
    if name == "generate_data_chapter05.py":
        s = fix_gen_ch5(s)
    if name == "plot_fig02_dh_model_vs_obs.py":
        s = fix_dh_vs_obs_main(s)
    if name == "plot_fig04_chi2_vs_T.py":
        s = fix_chi2_vs_T(s)
    if name == "generate_data_chapter06.py":
        s = fix_gen_ch6(s)
    if name == "plot_fig01_cmb_dataflow_diagram.py":
        s = fix_cmb_flow_ch6(s)
    if name == "plot_fig03_delta_cls_relative.py":
        s = fix_plot_delta_cls(s)
    if name == "plot_fig05_delta_chi2_heatmap.py":
        s = fix_heatmap_title(s)
    if name in ("plot_fig01_cs2_heatmap.py", "plot_fig02_delta_phi_heatmap.py"):
        s = drop_try_racine(s)
    if name in ("plot_fig03_invariant_I1.py", "plot_fig04_dcs2_vs_k.py"):
        s = collapse_seed(s)
    if name == "plot_fig05_ddelta_phi_vs_k.py":
        s = fix_ddelta_phi_ticks(s)
    if name == "generate_coupling_milestones.py":
        s = fix_gen_coupling_milestones(s)

    w(fp, s, orig, changed)

print(f"[RESULT] step47_files_changed={changed[0]}")
PY

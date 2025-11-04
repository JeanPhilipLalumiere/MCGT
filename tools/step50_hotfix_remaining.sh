#!/usr/bin/env bash
set -euo pipefail
export PYTHONPATH="${PYTHONPATH:-}:$PWD"

python3 - <<'PY'
from pathlib import Path
import re, sys

def wchg(p: Path, new: str, old: str, counter: list):
    if new != old:
        p.write_text(new, encoding="utf-8")
        counter[0] += 1
        print(f"[STEP50-FIX] {p}")

lst = Path("zz-out/_remaining_files.lst")
if not lst.exists():
    print("[step50] rien à faire"); sys.exit(0)

files = [Path(x) for x in lst.read_text(encoding="utf-8").splitlines()
         if x and Path(x).exists()]

changed = [0]

# Remplacement littéral (évite l’interprétation des backslashes en \D, \1, …)
def sub_literal(s: str, pattern: str, replacement: str, flags=0) -> str:
    rgx = re.compile(pattern, flags)
    return rgx.sub(lambda m, r=replacement: r, s)

# Helpers
def ensure_main_has_pass(s: str) -> str:
    return re.sub(
        r'(?m)^(\s*if\s+__name__\s*==\s*"__main__"\s*:\s*)$',
        r'\1\n    pass',
        s
    )

def fix_params_get_none(s: str) -> str:
    # ...get("alpha" None) -> ...get("alpha", None)
    s = re.sub(r'get\(\s*(".*?")\s+None\s*\)', r'get(\1, None)', s)
    return s

def fix_sys_path_insert(s: str) -> str:
    # ligne incomplète -> ligne complète
    return re.sub(
        r'(?m)^\s*sys\.path\.insert\([^)]*$',
        'sys.path.insert(0, str(ROOT / "zz-scripts" / "chapter02"))',
        s
    )

def dedent_keys(s: str, keys: list[str]) -> str:
    for k in keys:
        s = re.sub(rf'(?m)^\s+{re.escape(k)}', k, s)
    return s

for p in files:
    s0 = p.read_text(encoding="utf-8", errors="replace")
    s  = s0
    fn = p.name

    # Nettoyage générique
    s = ensure_main_has_pass(s)
    s = fix_params_get_none(s)
    s = re.sub(r'(?m)^\s*from\s*,\s*', 'from ', s)
    s = re.sub(r'(?m)^\s*import\s*,\s*', 'import ', s)

    # === Correctifs ciblés par fichier ===

    if fn == "plot_fig01_early_plateau.py":
        # Supprime les 3 lignes orphelines après 'return pngs[:1]'
        s = re.sub(r'(?m)^\s*glob\.glob\(os\.path\.join\(_default_dir,\s*"\*\.png"\)\),?\s*$', '', s)
        s = re.sub(r'(?m)^\s*key=os\.path\.getmtime,?\s*$', '', s)
        s = re.sub(r'(?m)^\s*reverse=True\s*$', '', s)

    if fn == "generate_data_chapter02.py":
        # Indentation sûre sur la fin de l’objectif
        s = re.sub(r'(?m)^(if\s+prim_mask\[ mask\]\.any\(\)\s*:\s*)$', r'    \1', s)
        s = re.sub(r'(?m)^(excess\s*=)', r'    \1', s)
        s = re.sub(r'(?m)^(penalty\s*=)', r'    \1', s)
        s = re.sub(r'(?m)^(return\s+np\.sum\(\(.*)', r'    \1', s)

    if fn == "plot_fig00_spectrum.py":
        s = fix_sys_path_insert(s)

    if fn == "plot_fig04_relative_deviations.py":
        # from matplotlib.ticker  import ,LogLocator -> propre
        s = re.sub(
            r'(?m)^\s*from\s+matplotlib\.ticker\s+import\s*,?\s*LogLocator\s*$',
            'from matplotlib.ticker import LogLocator',
            s
        )

    if fn == "generate_data_chapter05.py":
        # Corrige l’indentation de la branche Yp dans la boucle
        s = re.sub(r'(?m)^\s*if\s+pd\.notna\(row\.get\("Yp_obs"\)\)\s*:\s*$', '    if pd.notna(row.get("Yp_obs")):', s)
        s = re.sub(r'(?m)^\s*if\s+len\(\s*jalons_Yp\)\s*>\s*1\s*:\s*$', '        if len(jalons_Yp) > 1:', s)
        s = re.sub(r'(?m)^\s*yp_pred\s*=\s*10\s*\*\*\s*interp_Yp', r'            yp_pred = 10 ** interp_Yp', s)
        s = re.sub(r'(?m)^\s*else\s*:\s*$', '        else:', s)

    if fn == "plot_fig04_chi2_vs_T.py":
        # Remplace la ligne next(..., None) mal parenthésée
        s = re.sub(
            r'(?m)^\s*chi2col\s*=.*$',
            'chi2col = next((c for c in chi2df.columns if "chi2" in c.lower() and not any(k in c.lower() for k in ("d","deriv"))), None)',
            s
        )

    if fn == "generate_data_chapter06.py":
        # Dé-décale des lignes qui étaient indentées par erreur
        s = dedent_keys(s, ["SPEC2FILE = ", "with open(", "spec2 = ", "A_S0 = "])

    if fn == "plot_fig01_cmb_dataflow_diagram.py":
        # Retire la '}' orpheline et toute ligne parser=... injectée
        s = re.sub(r'(?m)^\s*\}\s*$', '', s)
        s = re.sub(r'(?m)^\s*parser\s*=\s*argparse\.ArgumentParser\(.*$', '', s)

    if fn == "plot_fig03_delta_cls_relative.py":
        # Ne garde qu’un _mcgt_cli_seed vide et valide
        s = re.sub(r'(?s)def\s+_mcgt_cli_seed\s*\([^)]*\)\s*:\s*.*\Z', 'def _mcgt_cli_seed():\n    pass\n', s)

    if fn == "plot_fig05_delta_chi2_heatmap.py":
        # Fixe params.get(...) et le titre avec backslashes (remplacement LITTÉRAL)
        s = fix_params_get_none(s)
        s = sub_literal(
            s,
            r'ax\.set_title\([^\n]*\)\s*",\s*\n\s*fontsize=14,',
            'ax.set_title(r"Carte de chaleur $\\\\Delta\\\\chi^2$ (Chapitre 6)", fontsize=14,'
        )

    if fn == "plot_fig04_dcs2_vs_k.py":
        # ax.set_ylim( 1e-8 None) -> ax.set_ylim(1e-8, None)
        s = re.sub(r'ax\.set_ylim\(\s*1e-8\s+None\s*\)', 'ax.set_ylim(1e-8, None)', s)

    if fn == "generate_coupling_milestones.py":
        # Complète axis=1)
        s = re.sub(r'(?m)df_sn\[\s*"category"\s*\]\s*=\s*df_sn\.apply\(.*axis=1\s*$', r'\g<0>)', s)

    if fn == "plot_fig03_mu_vs_z.py":
        # json.loads()( DATA_DIR / "08_coupling_params.json").read_text(…) -> version correcte
        s = re.sub(
            r'params\s*=\s*json\.loads\(\)\s*\(\s*DATA_DIR\s*/\s*"08_coupling_params\.json"\s*\)\.read_text\(\s*encoding\s*=\s*"utf-8"\s*\)',
            'params = json.loads((DATA_DIR / "08_coupling_params.json").read_text(encoding="utf-8"))',
            s
        )
        s = re.sub(r'q0star\s*=\s*params\.get\("q0star_optimal"\s*None\)', 'q0star = params.get("q0star_optimal", None)', s)

    if fn == "plot_fig04_chi2_heatmap.py":
        # Niveaux + cont/clabel propres (remplacements littéraux)
        s = sub_literal(s, r'levels\s*=\s*chi2min\s*\+\s*np\.array\([^)]+\)', 'levels = chi2min + np.array([2.30, 6.17, 11.8])')
        s = sub_literal(s, r'ax\.contour\(\)\s*p1,', 'ax.contour(p1,')
        s = sub_literal(s, r'ax\.clabel\([^\n]*', 'ax.clabel(cont, fmt={lvl: f"{int(lvl - chi2min)}" for lvl in levels}, fontsize=10, inline=True)')

    # Séparateur manquant dans set_ylim(X None) générique
    s = re.sub(r'(set_ylim\(\s*[^,\s]+)\s+None', r'\1, None', s)

    wchg(p, s, s0, changed)

print(f"[RESULT] step50_files_changed={changed[0]}")
PY

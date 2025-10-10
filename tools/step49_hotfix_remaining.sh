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
        print(f"[STEP49-FIX] {p}")

lst = Path("zz-out/_remaining_files.lst")
if not lst.exists():
    print("[step49] rien à faire"); sys.exit(0)

files = [Path(x) for x in lst.read_text(encoding="utf-8").splitlines()
         if x and Path(x).exists()]

changed = [0]

# --------- helpers NON-pathologiques (sans .* non borné) ----------
def ensure_main_has_pass(s: str) -> str:
    # ajoute un 'pass' si if __name__...: nu
    return re.sub(
        r'(?m)^(\s*if\s+__name__\s*==\s*"__main__"\s*:\s*)$',
        r'\1\n    pass',
        s
    )

def fix_params_get_none(s: str) -> str:
    # params.get("alpha" None) -> params.get("alpha", None)
    return re.sub(r'params\.get\("([A-Za-z0-9_]+)"\s+None\)',
                  r'params.get("\1", None)', s)

def tidy_import_commas(s: str) -> str:
    # import / from pollués par des virgules en tête
    s = re.sub(r'(?m)^\s*from\s*,\s*', 'from ', s)
    s = re.sub(r'(?m)^\s*import\s*,\s*', 'import ', s)
    return s

def fix_sys_path_insert(s: str) -> str:
    # .../chapter02"  sans parenthèses fermées -> version complète
    s = re.sub(r'(?m)^\s*sys\.path\.insert\([^)]*$',
               'sys.path.insert(0, str(ROOT / "zz-scripts" / "chapter02"))',
               s)
    return s

def simple_line_fix(s: str, pattern: str, repl: str) -> str:
    return re.sub(pattern, repl, s)

# ---------- boucle fichiers ----------
for p in files:
    s0 = p.read_text(encoding="utf-8", errors="replace")
    s  = s0
    fn = p.name

    # nettoyages généraux
    s = tidy_import_commas(s)
    s = ensure_main_has_pass(s)
    s = fix_params_get_none(s)

    # --- ciblages d’après ton dernier état d’erreurs ---

    if fn == "plot_fig01_early_plateau.py":
        # fonction _smoke_copy_latest correctement indentée + retour
        if "def _smoke_copy_latest" in s:
            s = re.sub(
                r'(?m)^def\s+_smoke_copy_latest\s*\(\s*\)\s*:\s*\n\s*try\s*:\s*$',
                'def _smoke_copy_latest():\n    try:',
                s
            )
            # corps minimal (si pas de return)
            if "return pngs[:1]" not in s:
                s = s.replace(
                    "pngs = sorted(",
                    "pngs = sorted("
                )
                # injecte un petit bloc de retour (sans chercher à supprimer ce qui existe)
                s = re.sub(
                    r'(?m)^\s*pngs\s*=\s*sorted\([^\n]*\n\s*',
                    '        pngs = sorted(glob.glob(os.path.join(_default_dir, "*.png")), key=os.path.getmtime, reverse=True)\n        return pngs[:1]\n',
                    s
                )
            if "except Exception" not in s:
                s += "\n    except Exception:\n        return []\n"

    if fn == "generate_data_chapter02.py":
        # fenêtre savgol binaire (virgules parasites)
        s = simple_line_fix(
            s,
            r'window\s*=\s*21\s*if\s*\(\s*len\(\s*dP\s*\)\s*>\s*21\s*,and\s*,21\s*%\s*2\s*==\s*1\)\s*else\s*\(\s*len\(\s*dP\s*\)\s*-\s*1\)',
            'window = 21 if (len(dP) > 21 and 21 % 2 == 1) else (len(dP) - 1)'
        )
        # bloc objective/penalty (juste la ligne “return … + penalty” bien formée)
        s = simple_line_fix(
            s,
            r'return\s+np\.sum\(\(\s*weights\[\s*mask\s*\]\s*\*\s*eps\s*\)\s*\*\s*2\)\s*\+\s*penalty',
            'return float(np.sum((weights[mask] * eps) ** 2) + penalty)'
        )

    if fn == "plot_fig00_spectrum.py":
        s = fix_sys_path_insert(s)

    if fn == "plot_fig04_relative_deviations.py":
        # import LogLocator propre
        s = simple_line_fix(s,
            r'from\s*,\s*matplotlib\.ticker\s*import\s*,\s*LogLocator',
            'from matplotlib.ticker import LogLocator'
        )

    if fn == "generate_data_chapter05.py":
        # bloc “jalons.iterrows()” : corrige l’indentation ‘if Yp_obs’ qui suivait
        s = simple_line_fix(
            s,
            r'(?m)^\s*if\s+pd\.notna\(\s*row\[\s*"Yp_obs"\s*\]\s*\)\s*:\s*$',
            '    if pd.notna(row.get("Yp_obs")):'
        )

    if fn == "plot_fig04_chi2_vs_T.py":
        # next((...), None) bien parenthésé + bon df
        s = simple_line_fix(
            s,
            r'chi2col\s*=\s*next\(\(c\s+for\s+c\s+in\s+chi2df\.columns[^\)]*\)\s*None\)',
            'chi2col = next((c for c in chi2df.columns if "chi2" in c.lower() and not any(k in c.lower() for k in ("d","deriv"))), None)'
        )
        s = simple_line_fix(
            s,
            r'chi2col\s*=\s*next\(\(c\s+for\s+c\s+in\s+df\.columns[^\)]*\)\s*None\)',
            'chi2col = next((c for c in chi2df.columns if "chi2" in c.lower() and not any(k in c.lower() for k in ("d","deriv"))), None)'
        )

    if fn == "generate_data_chapter06.py":
        # ArgumentParser sur une seule ligne
        s = simple_line_fix(
            s,
            r'(?m)^\s*parser\s*=\s*argparse\.ArgumentParser\([^\)]*$',
            'parser = argparse.ArgumentParser(description="Chapter 6 pipeline: generate CMB spectra for MCGT")'
        )
        # dé-décaler les lignes qui avaient une indentation en trop
        s = simple_line_fix(s, r'(?m)^\s+SPEC2FILE\s*=\s*', 'SPEC2FILE = ')
        s = simple_line_fix(s, r'(?m)^\s+with\s+open\(', 'with open(')
        s = simple_line_fix(s, r'(?m)^\s+spec2\s*=\s*', 'spec2 = ')
        s = simple_line_fix(s, r'(?m)^\s+A_S0\s*=\s*', 'A_S0 = ')

    if fn == "plot_fig01_cmb_dataflow_diagram.py":
        # supprime les restes de parser seed cassé (sécurisé, ligne à ligne)
        s = simple_line_fix(s, r'(?m)^\s*parser\s*=\s*argparse\.ArgumentParser\(.*$', '')

    if fn == "plot_fig03_delta_cls_relative.py":
        # params.get(..., None)
        s = fix_params_get_none(s)

    if fn == "plot_fig05_delta_chi2_heatmap.py":
        # titre/laTeX en une seule ligne propre (et pas de seconde ligne orpheline)
        s = simple_line_fix(
            s,
            r'ax\.set_title\([^\n]*\)\s*",\s*\n\s*fontsize=14,',
            'ax.set_title(r"Carte de chaleur $\\Delta\\chi^2$ (Chapitre 6)", fontsize=14,'
        )

    if fn == "plot_fig04_dcs2_vs_k.py":
        s = simple_line_fix(s, r'ax\.set_ylim\(\s*1e-8\s+None\s*\)', 'ax.set_ylim(1e-8, None)')

    if fn == "generate_coupling_milestones.py":
        # ... axis=1) manquant
        s = simple_line_fix(s, r'axis=1\s*$', 'axis=1)')

    if fn == "plot_fig03_mu_vs_z.py":
        s = simple_line_fix(
            s,
            r'params\s*=\s*json\.loads\(\(\s*DATA_DIR\s*/\s*"08_coupling_params\.json"\s*\)\.read_text\(\s*encoding\s*=\s*"utf-8"\s*\)\)',
            'params = json.loads((DATA_DIR / "08_coupling_params.json").read_text(encoding="utf-8"))'
        )
        s = simple_line_fix(s, r'q0star\s*=\s*params\.get\("q0star_optimal"\s*None\)', 'q0star = params.get("q0star_optimal", None)')

    if fn == "plot_fig04_chi2_heatmap.py":
        s = simple_line_fix(s, r'levels\s*=\s*chi2min\s*\+\s*np\.array\([^)]+\)', 'levels = chi2min + np.array([2.30, 6.17, 11.8])')
        s = simple_line_fix(s, r'ax\.contour\(\)\s*p1\s*,', 'ax.contour(p1,')
        s = simple_line_fix(s, r'ax\.clabel\([^\n]*', 'ax.clabel(cont, fmt={lvl: f"{int(lvl - chi2min)}" for lvl in levels}, fontsize=10, inline=True)')

    if fn == "generate_mcgt_raw_phase.py":
        # ferme le dict _CPN si nécessaire (minimale)
        if re.search(r'(?m)^_CPN\s*=\s*\{\s*$', s) and not re.search(r'(?m)^\}', s):
            s += "\n}\n"

    if fn == "qc_wrapped_vs_unwrapped.py":
        # multi-line print mal reconstitué → version compacte
        s = simple_line_fix(
            s,
            r'(?ms)for\s+s\s+in\s+summary\s*:\s*pass\s*change\s*=\s*\([^)]+\)\s*print\([^\n]+\)\s*print\([^\n]+\)\s*return\s+0',
            ('for s in summary:\n'
             '    change = (s["p95_raw"] - s["p95_circ"]) / (s["p95_raw"] + 1e-12)\n'
             '    print(f"id={s[\'id\']:5d}  raw={s[\'p95_raw\']:.6f}  circ={s[\'p95_circ\']:.6f}  unwrap={s[\'p95_unwrap\']:.6f}  delta%={(change*100):+.2f}%")\n'
             'print("\\nFichiers écrits dans:", os.path.abspath(args.outdir))\n'
             'return 0')
        )

    if fn == "recompute_p95_circular.py":
        # def main non indenté
        s = simple_line_fix(s, r'(?m)^\s+def\s+main\(', 'def main(')

    wchg(p, s, s0, changed)

print(f"[RESULT] step49_files_changed={changed[0]}")
PY

#!/usr/bin/env bash
set -euo pipefail
export PYTHONPATH="${PYTHONPATH:-}:$PWD"

python3 - <<'PY'
from pathlib import Path
import re, sys

def wchg(p: Path, s: str, s0: str, n: list[int]):
    if s != s0:
        p.write_text(s, encoding="utf-8")
        n[0] += 1
        print(f"[STEP52-FIX] {p}")

lst = Path("zz-out/_remaining_files.lst")
if not lst.exists():
    print("[step52] rien à faire"); sys.exit(0)

files = [Path(x) for x in lst.read_text(encoding="utf-8").splitlines() if x and Path(x).exists()]
changed = [0]

for p in files:
    s0 = p.read_text(encoding="utf-8", errors="replace")
    s  = s0
    fn = p.name

    # ---------- Garde __main__ sans corps -> ajouter pass ----------
    s = re.sub(r'(?ms)^(\s*if\s+__name__\s*==\s*"__main__"\s*:\s*)(\n(?!\s).*)?',
               r'\1\n    pass\n', s)

    # ---------- set_ylim(X None) -> set_ylim(X, None) ----------
    s = re.sub(r'(set_ylim\(\s*[^,\s]+)\s+None', r'\1, None', s)

    # =============================================================
    # FICHIERS SPÉCIFIQUES
    # =============================================================

    # 1) chap01 / early_plateau : seulement s'assurer que le if __main__ a un corps
    if fn == "plot_fig01_early_plateau.py":
        pass  # règle générique ci-dessus suffit

    # 2) chap02 / generate_data_chapter02 : bloc penalty correctement indenté + return
    if fn == "generate_data_chapter02.py":
        s = re.sub(
            r'(?ms)^(?P<ind>\s*)(?P<eps>eps\s*=\s*\(.*?\)\s*/\s*P_ref\[.*?\]\s*)\n(?:(?P=ind).*\n){0,8}',
            (lambda m:
             f"{m.group('ind')}{m.group('eps')}\n"
             f"{m.group('ind')}penalty = 0.0\n"
             f"{m.group('ind')}if prim_mask[ mask].any():\n"
             f"{m.group('ind')}    excess = np.max( np.abs( eps[ prim_mask[ mask ] ] )) - thresh_primary\n"
             f"{m.group('ind')}    penalty = 1e8 * max(0, excess) ** 2\n"
             f"{m.group('ind')}return np.sum(( weights[ mask ] * eps ) ** 2) + penalty\n"
            ),
            s, count=1)

    # 3) chap02 / plot_fig00_spectrum : parenthèse manquante + boucle for active
    if fn == "plot_fig00_spectrum.py":
        s = re.sub(r'(?m)^\s*fig,\s*ax\s*=\s*plt\.subplots\(\s*figsize=\(\s*6\s*,\s*4\s*\)\s*$',
                   'fig, ax = plt.subplots(figsize=(6, 4))', s)
        # retirer éventuelle ligne ax.loglog(...) errante
        s = re.sub(r'(?m)^\s*ax\.loglog\(\s*k\s*,\s*P_R\(\s*k\s*,\s*alpha\s*\)\s*,.*\)\s*$', '', s)
        # transformer for…pass en for + appel loglog
        s = re.sub(r'(?ms)^\s*for\s+alpha\s+in\s+alphas\s*:\s*\n\s*pass\s*$',
                   'for alpha in alphas:\n    ax.loglog(k, P_R(k, alpha), label=f"α = {alpha}")', s)

    # 4) chap04 / relative_deviations : réparer épilogue try
    if fn == "plot_fig04_relative_deviations.py":
        s = re.sub(
            r'(?ms)# \[MCGT POSTPARSE EPILOGUE v2\].*$',
            '# [MCGT POSTPARSE EPILOGUE v2]\n'
            'try:\n'
            '    import os, sys\n'
            '    _here = os.path.abspath(os.path.dirname(__file__))\n'
            'except Exception:\n'
            '    pass\n',
            s
        )

    # 5) chap05 / generate_data_chapter05 : indentation sous le if Yp
    if fn == "generate_data_chapter05.py":
        # sous-bloc à 8/12 espaces
        s = re.sub(r'(?m)^\s*if\s+len\( *jalons_Yp *\)\s*>\s*1\s*:\s*$', '        if len(jalons_Yp) > 1:', s)
        s = re.sub(r'(?m)^\s*yp_pred\s*=\s*10\s*\*\*\s*interp_Yp', '            yp_pred = 10 ** interp_Yp', s)
        s = re.sub(r'(?m)^\s*else\s*:\s*$', '        else:', s)

    # 6) chap05 / plot_fig04_chi2_vs_T : ligne next(..., None) bien parenthésée
    if fn == "plot_fig04_chi2_vs_T.py":
        s = re.sub(
            r'(?m)^\s*chi2col\s*=.*$',
            'chi2col = next((c for c in chi2df.columns if "chi2" in c.lower() and not any(k in c.lower() for k in ("d","deriv"))), None)',
            s
        )

    # 7) chap06 / generate_data_chapter06 : dé-denter le commentaire isolé
    if fn == "generate_data_chapter06.py":
        s = re.sub(r'(?m)^\s+# Note:\s*chapter02.*$', '# Note: chapter02 path uses English folder name "chapter02" and spec file', s)
        for k in ['SPEC2FILE = ', 'with open', 'spec2 = ', 'A_S0 = ']:
            s = re.sub(rf'(?m)^\s+{re.escape(k)}', k, s)

    # 8) chap06 / dataflow_diagram : suptitle correct
    if fn == "plot_fig01_cmb_dataflow_diagram.py":
        s = re.sub(
            r'(?m)^\s*fig\.suptitle\)\s*".*$',
            'fig.suptitle("Pipeline de génération des données CMB (Chapitre 6)", fontsize=14, fontweight="bold", y=0.96)',
            s
        )

    # 9) chap06 / heatmap : remettre ax.text SOUS la condition, en f-string/axes
    if fn == "plot_fig05_delta_chi2_heatmap.py":
        # si pattern: "if ...: pass\nax.text(...", on le remet dedans
        s = re.sub(
            r'(?ms)(^\s*if\s+ALPHA\s+is\s+not\s+None\s+and\s+Q0STAR\s+is\s+not\s+None\s*:\s*\n)\s*pass\s*\n\s*ax\.text\(',
            r'\1    ax.text(',
            s
        )
        # string raw -> f-string
        s = s.replace(r'"$\alpha={ALPHA},\ q_0^*={Q0STAR}$"', 'rf"$\\alpha={ALPHA},\\ q_0^*={Q0STAR}$"')
        # garantir transform=axes (si non présent)
        s = re.sub(r'ax\.text\(\s*0\.03\s*,\s*0\.95\s*,\s*([rf]".*?")\s*,\s*',
                   r'ax.text(0.03, 0.95, \1, transform=ax.transAxes, ', s)

    # 10) chap07 / dcs2_vs_k : supprimer vieille ligne return résiduelle
    if fn == "plot_fig04_dcs2_vs_k.py":
        s = s.replace('return r"$10^{{{int(np.log10(x))}}}$"', '')
        # s'assurer qu'on a bien le formatter en place
        s = re.sub(r'(?s)def\s+pow_fmt\(.*?\)\s*:\s*.*?return.*\n',
                   'def pow_fmt(x, pos):\n'
                   '    if x <= 0 or not np.isfinite(x):\n'
                   '        return ""\n'
                   '    return r"$10^{%d}$" % int(np.log10(x))\n',
                   s, count=1)

    # 11) chap07 / ddelta_phi_vs_k : garantir un docstring initial pour tolérer future import
    if fn == "plot_fig05_ddelta_phi_vs_k.py":
        if not s.lstrip().startswith('"""'):
            s = '"""MCGT Chapitre 7 — ΔΔφ vs k."""\n' + s

    # 12) chap08 : (les lignes signalées semblent déjà correctes après nos passes)

    # 13) chap09 / generate_mcgt_raw_phase : écraser proprement le dict _CPN
    if fn == "generate_mcgt_raw_phase.py":
        s = re.sub(r'(?s)_CPN\s*=\s*\{.*?\}', '_CPN = {0: 1, 2: (3715/756 + 55/9), 3: -16*np.pi}', s, count=1)

    # 14) chap09 / figs : basicConfig multi-ligne -> appel simple fermé
    if fn in ("plot_fig01_phase_overlay.py", "plot_fig02_residual_phase.py",
              "plot_fig03_hist_absdphi_20_300.py", "plot_fig04_absdphi_milestones_vs_f.py",
              "plot_fig05_scatter_phi_at_fpeak.py"):
        # retirer lignes orphelines format= / datefmt= si présentes
        s = re.sub(r'(?m)^\s*format\s*=\s*".*",\s*$', '', s)
        s = re.sub(r'(?m)^\s*datefmt\s*=\s*".*",\s*$', '', s)
        # s'assurer que la ligne basicConfig est fermée
        s = re.sub(r'(?m)^(\s*logging\.basicConfig\([^\)]*)\s*$', r'\1)', s)

    # 15) chap10 / qc_wrapped_vs_unwrapped : supprimer "return 0" toplevel
    if fn == "qc_wrapped_vs_unwrapped.py":
        s = re.sub(r'(?m)^\s*return\s+0\s*$', '', s)

    # 16) chap10 / recompute_p95_circular : supprimer une ligne toplevel "d = ( a - b ) ..."
    if fn == "recompute_p95_circular.py":
        s = re.sub(r'(?m)^\s*d\s*=\s*\(\s*a\s*-\s*b\s*\).*$','', s)

    wchg(p, s, s0, changed)

print(f"[RESULT] step52_files_changed={changed[0]}")
PY

#!/usr/bin/env bash
set -euo pipefail
export PYTHONPATH="${PYTHONPATH:-}:$PWD"

python3 - <<'PY'
from pathlib import Path, re
import sys

def wchg(p: Path, s: str, s0: str, n: list[int]):
    if s != s0:
        p.write_text(s, encoding="utf-8")
        n[0] += 1
        print(f"[STEP53-FIX] {p}")

lst = Path("zz-out/_remaining_files.lst")
if not lst.exists():
    print("[step53] rien à faire"); sys.exit(0)
files = [Path(x) for x in lst.read_text(encoding="utf-8").splitlines() if x and Path(x).exists()]
changed = [0]

for p in files:
    s0 = p.read_text(encoding="utf-8", errors="replace")
    s  = s0
    fn = p.name

    # ==== Correctifs génériques ====
    # __main__ sans corps → pass
    s = re.sub(r'(?ms)^(\s*if\s+__name__\s*==\s*"__main__"\s*:\s*)(\n(?!\s).*)?', r'\1\n    pass\n', s)

    # Nettoyage de séquences de 'pass' top-level consécutifs
    s = re.sub(r'(?ms)^(?:pass\s*\n){2,}', '', s)

    # set_ylim(1e-8 None) → set_ylim(1e-8, None)
    s = re.sub(r'(set_ylim\(\s*[^,\s]+)\s+None', r'\1, None', s)

    # ==== Fichiers spécifiques ====

    # -- chap01: seed stub mal fermé
    if fn == "plot_fig01_early_plateau.py":
        s = re.sub(r'(?ms)^\s*def\s+_mcgt_cli_seed\(\)\s*:\s*(?=\S)', 'def _mcgt_cli_seed():\n    pass\n', s)

    # -- chap02: return nu au toplevel
    if fn == "generate_data_chapter02.py":
        s = re.sub(
            r'(?m)^\s*return\s+a\s*\*\s*T\s*\*\*\s*\(\s*a\s*-\s*1\s*\)\s*\+\s*T\*\*a\s*\*\s*np\.log\(\s*T\s*\)\s*\*\s*da\s*$',
            'da_dT = a * T ** (a - 1) + T**a * np.log(T) * da',
            s
        )

    # -- chap02: spectrum — parenthèses/boucle & 'pass' parasites
    if fn == "plot_fig00_spectrum.py":
        s = re.sub(r'(?m)^\s*fig,\s*ax\s*=\s*plt\.subplots\(\s*figsize=\(\s*6\s*,\s*4\s*\)\s*$', 'fig, ax = plt.subplots(figsize=(6, 4))', s)
        s = re.sub(r'(?ms)^\s*for\s+alpha\s+in\s+alphas\s*:\s*\n\s*pass\s*$', 'for alpha in alphas:\n    ax.loglog(k, P_R(k, alpha), label=f"α = {alpha}")', s)
        # supprimer 'pass' top-level résiduels
        s = re.sub(r'(?m)^\s*pass\s*$', '', s)

    # -- chap04: épilogue try bien formé + retirer 'pass' top-level résiduels
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
        s = re.sub(r'(?m)^\s*pass\s*$', '', s)

    # -- chap05: bloc Hélium-4 réécrit proprement
    if fn == "generate_data_chapter05.py":
        s = re.sub(
            r'(?ms)^#\s*H[ée]lium-4.*?(?=^\S|\Z)',
            '# Hélium-4\n'
            'if len(jalons_Yp) > 1:\n'
            '    interp_Yp = PchipInterpolator(\n'
            '        np.log10(jalons_Yp["T_Gyr"]), np.log10(jalons_Yp["Yp_obs"]), extrapolate=True\n'
            '    )\n'
            '    Yp_calc = 10 ** interp_Yp(np.log10(T))\n'
            'else:\n'
            '    Yp_calc = np.full_like(T, float(jalons_Yp["Yp_obs"].iloc[0]))\n',
            s, count=1
        )

    # -- chap05: chi2_vs_T — bloc détect/σ reformaté
    if fn == "plot_fig04_chi2_vs_T.py":
        s = re.sub(
            r'(?ms)chi2col\s*=.*?sigma\s*=\s*0\.10\s*\*\s*chi2',
            'chi2col = next((c for c in chi2df.columns if "chi2" in c.lower() and not any(k in c.lower() for k in ("d","deriv"))), None)\n'
            'chi2 = chi2df[chi2col].to_numpy()\n'
            'if "chi2_err" in chi2df.columns:\n'
            '    sigma = pd.to_numeric(chi2df["chi2_err"], errors="coerce").to_numpy()\n'
            'else:\n'
            '    sigma = 0.10 * chi2',
            s
        )

    # -- chap06: dedent commentaires + suptitle correct
    if fn == "generate_data_chapter06.py":
        s = re.sub(r'(?m)^\s+#\s*---LOAD.*$', '# ---LOAD CHAPTER-2 SPECTRUM COEFFICIENTS---', s)
        s = re.sub(r'(?m)^\s+# Note:', '# Note:', s)
        for k in ('SPEC2FILE = ', 'with open', 'spec2 = ', 'A_S0 = '):
            s = re.sub(rf'(?m)^\s+{re.escape(k)}', k, s)

    if fn == "plot_fig01_cmb_dataflow_diagram.py":
        s = re.sub(
            r'(?m)^\s*fig\.suptitle\)\s*".*$',
            'fig.suptitle("Pipeline de génération des données CMB (Chapitre 6)", fontsize=14, fontweight="bold", y=0.96)',
            s
        )

    # -- chap06: heatmap — rrf -> rf
    if fn == "plot_fig05_delta_chi2_heatmap.py":
        s = s.replace('rrf"', 'rf"')

    # -- chap07: ΔΔφ — nettoyer pass en doublon top-level
    if fn == "plot_fig05_ddelta_phi_vs_k.py":
        s = re.sub(r'(?m)^\s*pass\s*$', '', s)

    # -- chap08: label_th bloc → one-liner
    if fn == "plot_fig03_mu_vs_z.py":
        s = re.sub(
            r'(?ms)^label_th\s*=\s*\(.*?^\s*else\s+r"\$\\mu\\\^\{\\rm th\}\(z\)\$"\s*$', 
            'label_th = rf"$\\\\mu^{{\\\\rm th}}(z; q_0^*={q0star:.3f})$" if q0star is not None else r"$\\\\mu^{\\\\rm th}(z)$"',
            s
        )

    # -- chap08: contour(...) — fermer la parenthèse après linestyles
    if fn == "plot_fig04_chi2_heatmap.py":
        s = re.sub(
            r'(?ms)(^\s*cont\s*=\s*ax\.contour\([^\)]*$.*?linestyles=\[.*?\]\s*,?\s*$)',
            r'\1\n)',
            s
        )

    # -- chap09: _CPN résidus "4:".. "7:" -> purge
    if fn == "generate_mcgt_raw_phase.py":
        s = re.sub(r'(?m)^\s*[4-7]\s*:\s*.*\n', '', s)

    # -- chap09: fonctions utilitaires — écrire corps corrects (évite IndentationError)
    if fn == "plot_fig01_phase_overlay.py":
        s = re.sub(
            r'(?ms)^def\s+p95\([^\)]*\):\s*\n\s*a\s*=.*?$', 
            'def p95(a: np.ndarray) -> float:\n'
            '    a = np.asarray(a, float)\n'
            '    a = a[np.isfinite(a)]\n'
            '    return float(np.percentile(a, 95.0)) if a.size else float("nan")\n', s, count=1)

    if fn == "plot_fig02_residual_phase.py":
        s = re.sub(
            r'(?ms)^def\s+parse_bands\([^\)]*\):\s*\n\s*if\s+len\(vals\).*?$', 
            'def parse_bands(vals: list[float]) -> list[tuple[float, float]]:\n'
            '    if len(vals) == 0 or len(vals) % 2:\n'
            '        raise ValueError("bands must be pairs of floats (even count).")\n'
            '    it = iter(vals)\n'
            '    return list(zip(it, it))\n', s, count=1)

    if fn == "plot_fig03_hist_absdphi_20_300.py":
        s = re.sub(
            r'(?ms)^def\s+principal_phase_diff\([^\)]*\):\s*\n\s*"""[^\n]*\n\s*return\s*\(.*$', 
            'def principal_phase_diff(a: np.ndarray, b: np.ndarray) -> np.ndarray:\n'
            '    """((a-b+π) mod 2π) - π in (-π, π]"""\n'
            '    return (np.asarray(a, float) - np.asarray(b, float) + np.pi) % (2*np.pi) - np.pi\n', s, count=1)

    if fn == "plot_fig04_absdphi_milestones_vs_f.py":
        s = re.sub(
            r'(?ms)^def\s+principal_diff\([^\)]*\):\s*\n\s*"""[^\n]*\n\s*return\s*\(.*$', 
            'def principal_diff(a: np.ndarray, b: np.ndarray) -> np.ndarray:\n'
            '    """((a-b+π) mod 2π) - π in (-π, π]"""\n'
            '    return (np.asarray(a, float) - np.asarray(b, float) + np.pi) % (2*np.pi) - np.pi\n', s, count=1)

    if fn == "plot_fig05_scatter_phi_at_fpeak.py":
        s = re.sub(
            r'(?ms)^def\s+principal_align\([^\)]*\):\s*\n\s*"""[^\n]*\n\s*Aligne[^\n]*$', 
            'def principal_align(y: np.ndarray, x: np.ndarray) -> np.ndarray:\n'
            '    """Aligne y sur x modulo 2π : y\' = y - 2π * round((y-x)/(2π))."""\n'
            '    y = np.asarray(y, float)\n'
            '    x = np.asarray(x, float)\n'
            '    return y - 2*np.pi * np.round((y - x) / (2*np.pi))\n', s, count=1)

    # -- chap10: nettoyer 'pass' top-level doublons et d = np.where(...) orphelin
    if fn == "qc_wrapped_vs_unwrapped.py":
        s = re.sub(r'(?m)^\s*pass\s*$', '', s)

    if fn == "recompute_p95_circular.py":
        s = re.sub(r'(?m)^\s*d\s*=\s*np\.where\(.*$', '', s)

    wchg(p, s, s0, changed)

print(f"[RESULT] step53_files_changed={changed[0]}")
PY

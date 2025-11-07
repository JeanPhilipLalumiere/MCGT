#!/usr/bin/env bash
set -euo pipefail
export PYTHONPATH="${PYTHONPATH:-}:$PWD"

python3 - <<'PY'
import re, sys
from pathlib import Path

def wchg(p: Path, s: str, s0: str, n):
    if s != s0:
        p.write_text(s, encoding="utf-8")
        n[0] += 1
        print(f"[STEP55-FIX] {p}")

lst = Path("zz-out/_remaining_files.lst")
if not lst.exists():
    print("[step55] rien à faire"); sys.exit(0)
files = [Path(x) for x in lst.read_text(encoding="utf-8").splitlines() if x and Path(x).exists()]
changed = [0]

for p in files:
    s0 = p.read_text(encoding="utf-8", errors="replace")
    s  = s0
    fn = p.name

    # Petits garde-fous génériques
    s = re.sub(r'(?m)^if\s+__name__\s*==\s*"__main__"\s*:\s*$', 'if __name__ == "__main__":\n    pass', s)
    s = re.sub(r'(set_ylim\(\s*[^,\s]+)\s+None', r'\1, None', s)

    # ===== Chap 02 =====
    if fn == "plot_fig00_spectrum.py":
        # Indenter le bloc OUTDIR_ENV
        s = re.sub(
            r'(?ms)(^OUTDIR_ENV\s*=\s*os\.environ\.get\([^\n]*\)\s*\n)^\s*if\s+OUTDIR_ENV:\s*\n\s*(args\.outdir\s*=\s*OUTDIR_ENV\s*\n)\s*(os\.makedirs\([^\n]*\)\s*\n)',
            r'\1if OUTDIR_ENV:\n    \2    \3',
            s
        )
    if p.name == "generate_data_chapter02.py":
        # Protéger un return top-level en l'encapsulant dans une fonction fantôme
        s = re.sub(
            r'(?ms)^da_log\s*=.*\n\s*da\s*=.*\n\s*return\s+.*\n',
            lambda m: 'def __mcgt_tmp_fix():\n    ' + '\n    '.join([ln.rstrip() for ln in m.group(0).splitlines()]) + '\n',
            s, count=1
        )

    # ===== Chap 04 =====
    if fn == "plot_fig04_relative_deviations.py":
        # except sans corps -> pass
        s = re.sub(r'(?ms)^except\s+Exception\s*:\s*(?=\n(?!\s+pass))', 'except Exception:\n    pass\n', s)

    # ===== Chap 05 =====
    if fn == "generate_data_chapter05.py":
        # Indenter correctement le else: yp_pred/eps/append
        s = re.sub(
            r'(?ms)^(\s*else:\s*\n)\s*(yp_pred\s*=.*\n\s*eps\s*=.*\n\s*eps_records\.append\([^\n]*\)\s*)',
            lambda m: m.group(1) + ''.join('    ' + ln for ln in m.group(2).splitlines(True)),
            s, count=1
        )
    if fn == "plot_fig04_chi2_vs_T.py":
        # dchi_raw == ... -> =
        s = re.sub(r'(?m)^\s*dchi_raw\s*==', 'dchi_raw =', s)
        # Indenter l'affectation sous le if + assurer un else minimal
        s = re.sub(
            r'(?ms)(^if\s+dchi_raw\.size\s*==\s*0:\s*\n\s*#.*?\n)\s*(dchi\s*=\s*.*?\n)\s*else:\s*\n(?!\s*dchi\s*=)',
            r'\1    \2else:\n    dchi = dchi_raw\n',
            s, count=1
        )

    # ===== Chap 06 =====
    if fn == "plot_fig01_cmb_dataflow_diagram.py":
        s = re.sub(
            r'(?m)^\s*fig\.suptitle\)\s*".*$',
            'fig.suptitle("Pipeline de génération des données CMB (Chapitre 6)", fontsize=14, fontweight="bold", y=0.96)',
            s
        )
    if fn == "plot_fig05_delta_chi2_heatmap.py":
        # Supprimer un doublon d'annotation multilignes résiduel
        s = re.sub(
            r'(?ms)^if\s+ALPHA\s+is\s+not\s+None\s+and\s+Q0STAR\s+is\s+not\s+None:\s*\n\s*ax\.text\(\s*\n\s*0\.03,\s*\n\s*0\.95,\s*\n\s*rf"\$\\alpha=\{ALPHA\},\\ q_0\^\*=\{Q0STAR\}\$",?\s*\n\s*\)\s*',
            '',
            s
        )

    # ===== Chap 07 =====
    # (Pas d’opération risquée ici sans contenu supplémentaire — on garde pour une micro-passe si encore listé)

    # ===== Chap 08 =====
    if fn == "plot_fig03_mu_vs_z.py":
        # lw==2 / label==... -> =
        s = re.sub(r'(\blw)\s*==\s*', r'\1=', s)
        s = re.sub(r'(\blabel)\s*==\s*', r'\1=', s)
    if fn == "plot_fig04_chi2_heatmap.py":
        # ax.plot(...), bbox=... -> split en plot + text avec bbox
        s = re.sub(
            r'ax\.plot\(\s*q0min\s*,\s*p2min\s*,\s*"o"\s*,\s*color="black"\s*,\s*ms=6\)\s*,\s*bbox\s*=\s*dict\(([^)]*)\)',
            r'ax.plot(q0min, p2min, "o", color="black", ms=6)\nax.text(q0min, p2min, txt, ha="right", va="top", bbox=dict(\1), fontsize=9)',
            s
        )

    # ===== Chap 09 =====
    if fn == "generate_mcgt_raw_phase.py":
        # Réécrire l’en-tête de corr_phase
        s = re.sub(
            r'(?ms)^def\s+corr_phase\([^\n]*\n[^\n]*\n[^\n]*\n',
            'def corr_phase(freqs: np.ndarray, fmin: float, q0star: float, alpha: float) -> np.ndarray:\n',
            s, count=1
        )
        # S’assurer de l’indentation du bloc alpha≈1
        s = re.sub(
            r'(?m)^\s*if\s+np\.isclose\(\s*alpha\s*,\s*1\.0\s*\)\s*:\s*\n\s*return\s+2\s*\*\s*np\.pi\s*\*\s*q0star\s*\*\s*np\.log\(\s*freqs\s*/\s*fmin\s*\)',
            '    if np.isclose(alpha, 1.0):\n        return 2 * np.pi * q0star * np.log(freqs / fmin)',
            s
        )
    if fn == "plot_fig01_phase_overlay.py":
        s = re.sub(
            r'(?ms)^def\s+p95\([^\)]*\):\s*\n\s*a\s*=.*',
            'def p95(a: np.ndarray) -> float:\n'
            '    a = np.asarray(a, float)\n'
            '    a = a[np.isfinite(a)]\n'
            '    return float(np.percentile(a, 95.0)) if a.size else float("nan")\n',
            s, count=1
        )
    if fn == "plot_fig02_residual_phase.py":
        s = re.sub(
            r'(?ms)^def\s+parse_bands\([^\)]*\):\s*\n\s*if\s+len\(vals\).*',
            'def parse_bands(vals: list[float]) -> list[tuple[float, float]]:\n'
            '    if len(vals) == 0 or len(vals) % 2:\n'
            '        raise ValueError("bands must be pairs of floats (even count).")\n'
            '    it = iter(vals)\n'
            '    return list(zip(it, it))\n',
            s, count=1
        )
    if fn == "plot_fig03_hist_absdphi_20_300.py":
        s = re.sub(
            r'(?ms)^def\s+principal_phase_diff\([^\)]*\):\s*\n\s*"""[^\n]*\n\s*return\s*\(.*',
            'def principal_phase_diff(a: np.ndarray, b: np.ndarray) -> np.ndarray:\n'
            '    """((a-b+π) mod 2π) - π in (-π, π]"""\n'
            '    return (np.asarray(a, float) - np.asarray(b, float) + np.pi) % (2*np.pi) - np.pi\n',
            s, count=1
        )
    if fn == "plot_fig04_absdphi_milestones_vs_f.py":
        s = re.sub(
            r'(?ms)^def\s+principal_diff\([^\)]*\):\s*\n\s*"""[^\n]*\n\s*return\s*\(.*',
            'def principal_diff(a: np.ndarray, b: np.ndarray) -> np.ndarray:\n'
            '    """((a-b+π) mod 2π) - π in (-π, π]"""\n'
            '    return (np.asarray(a, float) - np.asarray(b, float) + np.pi) % (2*np.pi) - np.pi\n',
            s, count=1
        )
    if fn == "plot_fig05_scatter_phi_at_fpeak.py":
        s = re.sub(
            r'(?ms)^def\s+principal_align\([^\)]*\):\s*\n\s*"""[^\n]*\n\s*Aligne.*',
            'def principal_align(y: np.ndarray, x: np.ndarray) -> np.ndarray:\n'
            '    """Aligne y sur x modulo 2π : y\' = y - 2π * round((y-x)/(2π))."""\n'
            '    y = np.asarray(y, float)\n'
            '    x = np.asarray(x, float)\n'
            '    return y - 2*np.pi * np.round((y - x) / (2*np.pi))\n',
            s, count=1
        )

    # ===== Chap 10 =====
    if fn == "qc_wrapped_vs_unwrapped.py":
        s = re.sub(
            r'(?ms)print\(\s*"\s*\n\s*==\s*RAPPORT\s+SYNTH[ÈE]SE\s*=="\s*\)\s*',
            'print("\\n== RAPPORT SYNTHÈSE ==")\n',
            s
        )
    if fn == "recompute_p95_circular.py":
        # Supprimer le doublon "argparse.ArgumentParser()" et re-indenter les add_argument
        s = re.sub(r'(?m)^\s*argparse\.ArgumentParser\(\)\s*$', '', s)
        s = re.sub(r'(?m)^(parser\.add_argument\()', r'    \1', s)

    wchg(p, s, s0, changed)

print(f"[RESULT] step55_files_changed={changed[0]}")
PY

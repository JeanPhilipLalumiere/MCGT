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
        print(f"[STEP56-FIX] {p}")

lst = Path("zz-out/_remaining_files.lst")
if not lst.exists():
    print("[step56] rien à faire"); sys.exit(0)
files = [Path(x) for x in lst.read_text(encoding="utf-8").splitlines() if x and Path(x).exists()]
changed = [0]

for p in files:
    s0 = p.read_text(encoding="utf-8", errors="replace")
    s  = s0
    fn = p.name

    # Garde-fous génériques
    s = re.sub(r'(?m)^if\s+__name__\s*==\s*"__main__"\s*:\s*$', 'if __name__ == "__main__":\n    pass', s)

    # ================== Chapitre 02 ==================
    if fn == "plot_fig00_spectrum.py":
        # Parenthèses manquantes sur _ch / _repo
        s = re.sub(r'(?m)^_ch\s*=.*$', '_ch = os.path.basename(os.path.dirname(__file__))', s, count=1)
        s = re.sub(r'(?m)^_repo\s*=.*$', '_repo = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", ".."))', s, count=1)

    # ================== Chapitre 04 ==================
    if fn == "plot_fig04_relative_deviations.py":
        # Boucle sur possible_paths propre avec break unique
        s = re.sub(
            r'(?ms)for\s+path\s+in\s+possible_paths:\s*.*?print\(f"Charg[ée] .*?\)\s*.*?break',
            'for path in possible_paths:\n'
            '    if os.path.isfile(path):\n'
            '        df = pd.read_csv(path)\n'
            '        print(f"Chargé {path}")\n'
            '        break',
            s
        )
        s = re.sub(r'(?m)^\s*break\s*$', '', s)  # supprime un break orphelin juste au cas où

    # ================== Chapitre 05 ==================
    if fn == "generate_data_chapter05.py":
        # Recompose le bloc Yp proprement (else + calculs communs)
        s = re.sub(
            r'(?ms)^\s*if\s+pd\.notna\(row\.get\("Yp_obs"\)\):\s*\n.*?eps_records\.append\([^\n]*\)\s*',
            'if pd.notna(row.get("Yp_obs")):\n'
            '    if len(jalons_Yp) > 1:\n'
            '        yp_pred = 10 ** interp_Yp(np.log10(row["T_Gyr"]))\n'
            '    else:\n'
            '        yp_pred = jalons_Yp["Yp_obs"].iloc[0]\n'
            '    eps = abs(yp_pred - row["Yp_obs"]) / row["Yp_obs"]\n'
            '    eps_records.append({"epsilon": eps, "sigma_rel": row["sigma_Yp"] / row["Yp_obs"]})\n',
            s
        )

    if fn == "plot_fig04_chi2_vs_T.py":
        # Corrige le bloc d'interpolation dχ2 -> T
        s = re.sub(
            r'(?ms)^if\s+not\s+np\.allclose\(\s*Td\s*,\s*T\s*\)\s*:\s*\n.*?(?=\n\S)',
            'if not np.allclose(Td, T):\n'
            '    dchi = np.interp(np.log10(T), np.log10(Td), dchi_raw)\n',
            s
        )

    # ================== Chapitre 06 ==================
    if fn == "plot_fig01_cmb_dataflow_diagram.py":
        # suptitle mal parenthésé
        s = re.sub(
            r'(?m)^\s*fig\.suptitle\)\s*".*$',
            'fig.suptitle("Pipeline de génération des données CMB (Chapitre 6)", fontsize=14, fontweight="bold", y=0.96)',
            s
        )

    if fn == "plot_fig05_delta_chi2_heatmap.py":
        # Supprime le second bloc d’annotation (multiligne) s'il traîne encore
        s = re.sub(
            r'(?ms)^if\s+ALPHA\s+is\s+not\s+None\s+and\s+Q0STAR\s+is\s+not\s+None:\s*\n\s*ax\.text\(\s*\n\s*0\.03,\s*\n\s*0\.95,\s*\n\s*rf"\$\\alpha=\{ALPHA\},\\ q_0\^\*=\{Q0STAR\}\$",?\s*\n\s*\)\s*',
            '',
            s
        )

    # ================== Chapitre 07 ==================
    if fn == "plot_fig05_ddelta_phi_vs_k.py":
        # Ajoute un vrai docstring si une ligne brute "Chapitre 7 - ..." est orpheline
        s = re.sub(
            r'(?m)^Chapitre 7 - Perturbations scalaires MCGT\s*$',
            '"""\nChapitre 7 - Perturbations scalaires MCGT\n"""',
            s
        )

    # ================== Chapitre 08 ==================
    if fn == "plot_fig04_chi2_heatmap.py":
        # Stub propre pour _mcgt_cli_seed()
        s = re.sub(
            r'(?ms)^def\s+_mcgt_cli_seed\(\):\s*\n\s*import\s+os\s*\n\s*import\s+argparse\s*\n\s*import\s+sys\s*',
            'def _mcgt_cli_seed():\n'
            '    import os, argparse, sys\n'
            '    pass',
            s
        )

    # ================== Chapitre 09 ==================
    if fn == "generate_mcgt_raw_phase.py":
        # Corriger totalement la fonction corr_phase (header + corps propre)
        s = re.sub(
            r'(?ms)^def\s+corr_phase\(.*?\)\s*->\s*np\.ndarray:\s*.*?(?=\n#\s*---\s*Solveur|\n@|\nclass|\n\Z)',
            'def corr_phase(freqs: np.ndarray, fmin: float, q0star: float, alpha: float) -> np.ndarray:\n'
            '    """Correction analytique pour δt = q0star * f^(-alpha)."""\n'
            '    if np.isclose(alpha, 1.0):\n'
            '        return 2 * np.pi * q0star * np.log(freqs / fmin)\n'
            '    return (2 * np.pi * q0star / (1 - alpha)) * (freqs ** (1 - alpha) - fmin ** (1 - alpha))\n\n',
            s
        )

    if fn == "plot_fig01_phase_overlay.py":
        # setup_logger complet
        s = re.sub(
            r'(?ms)^def\s+setup_logger\(.*?\):\s*\n\s*pass\s*\n',
            'def setup_logger(level: str = "INFO") -> logging.Logger:\n'
            '    lvl = getattr(logging, str(level).upper(), logging.INFO)\n'
            '    logging.basicConfig(level=lvl,\n'
            '                        format="[%(asctime)s] [%(levelname)s] %(message)s",\n'
            '                        datefmt="%Y-%m-%d %H:%M:%S")\n'
            '    return logging.getLogger("fig01")\n\n',
            s, count=1
        )
        # p95 robuste (au cas où)
        s = re.sub(
            r'(?ms)^def\s+p95\(.*?\):\s*\n.*?return.*?\n',
            'def p95(a: np.ndarray) -> float:\n'
            '    a = np.asarray(a, float)\n'
            '    a = a[np.isfinite(a)]\n'
            '    return float(np.percentile(a, 95.0)) if a.size else float("nan")\n\n',
            s
        )

    if fn == "plot_fig02_residual_phase.py":
        s = re.sub(
            r'(?ms)^def\s+parse_bands\(.*?\):\s*\n.*?(?=\n\S)',
            'def parse_bands(vals: list[float]) -> list[tuple[float, float]]:\n'
            '    if len(vals) == 0 or len(vals) % 2:\n'
            '        raise ValueError("bands must be pairs of floats (even count).")\n'
            '    it = iter(vals)\n'
            '    return list(zip(it, it))\n',
            s
        )

    if fn == "plot_fig03_hist_absdphi_20_300.py":
        s = re.sub(
            r'(?ms)^def\s+setup_logger\(.*?\):\s*\n\s*pass\s*\n',
            'def setup_logger(level: str = "INFO") -> logging.Logger:\n'
            '    lvl = getattr(logging, str(level).upper(), logging.INFO)\n'
            '    logging.basicConfig(level=lvl,\n'
            '                        format="[%(asctime)s] [%(levelname)s] %(message)s",\n'
            '                        datefmt="%Y-%m-%d %H:%M:%S")\n'
            '    return logging.getLogger("fig03")\n\n',
            s, count=1
        )
        s = re.sub(
            r'(?ms)^def\s+principal_phase_diff\(.*?\):\s*\n.*?(?=\n\S)',
            'def principal_phase_diff(a: np.ndarray, b: np.ndarray) -> np.ndarray:\n'
            '    """((a-b+π) mod 2π) - π in (-π, π]"""\n'
            '    return (np.asarray(a, float) - np.asarray(b, float) + np.pi) % (2*np.pi) - np.pi\n',
            s
        )

    if fn == "plot_fig04_absdphi_milestones_vs_f.py":
        s = re.sub(
            r'(?ms)^def\s+setup_logger\(.*?\):\s*\n\s*pass\s*\n',
            'def setup_logger(level: str = "INFO") -> logging.Logger:\n'
            '    lvl = getattr(logging, str(level).upper(), logging.INFO)\n'
            '    logging.basicConfig(level=lvl,\n'
            '                        format="[%(asctime)s] [%(levelname)s] %(message)s",\n'
            '                        datefmt="%Y-%m-%d %H:%M:%S")\n'
            '    return logging.getLogger("fig04")\n\n',
            s, count=1
        )
        s = re.sub(
            r'(?ms)^def\s+principal_diff\(.*?\):\s*\n.*?(?=\n\S)',
            'def principal_diff(a: np.ndarray, b: np.ndarray) -> np.ndarray:\n'
            '    """((a-b+π) mod 2π) - π in (-π, π]"""\n'
            '    return (np.asarray(a, float) - np.asarray(b, float) + np.pi) % (2*np.pi) - np.pi\n',
            s
        )

    if fn == "plot_fig05_scatter_phi_at_fpeak.py":
        s = re.sub(
            r'(?ms)^def\s+setup_logger\(.*?\):\s*\n\s*pass\s*\n',
            'def setup_logger(level: str = "INFO") -> logging.Logger:\n'
            '    lvl = getattr(logging, str(level).upper(), logging.INFO)\n'
            '    logging.basicConfig(level=lvl,\n'
            '                        format="[%(asctime)s] [%(levelname)s] %(message)s",\n'
            '                        datefmt="%Y-%m-%d %H:%M:%S")\n'
            '    return logging.getLogger("fig05")\n\n',
            s, count=1
        )
        s = re.sub(
            r'(?ms)^def\s+principal_align\(.*?\):\s*\n.*?(?=\n\S)',
            'def principal_align(y: np.ndarray, x: np.ndarray) -> np.ndarray:\n'
            '    """Aligne y sur x modulo 2π : y\' = y - 2π * round((y-x)/(2π))."""\n'
            '    y = np.asarray(y, float)\n'
            '    x = np.asarray(x, float)\n'
            '    return y - 2*np.pi * np.round((y - x) / (2*np.pi))\n',
            s
        )

    # ================== Chapitre 10 ==================
    if fn == "qc_wrapped_vs_unwrapped.py":
        # print(" \n == RAPPORT...") -> print("\\n== RAPPORT ...")
        s = re.sub(
            r'(?ms)print\(\s*"\s*\n\s*==\s*RAPPORT\s+SYNTH[ÈE]SE\s*=="\s*\)\s*',
            'print("\\n== RAPPORT SYNTHÈSE ==")\n',
            s
        )

    if fn == "recompute_p95_circular.py":
        # Re-indenter la boucle d'itération si besoin (id_, samp, etc.)
        s = re.sub(
            r'(?ms)^(\s*)for\s+_,\s*row\s+in\s+df_res\.iterrows\(\):\s*\n(?!\s{4})',
            r'\1for _, row in df_res.iterrows():\n    ',
            s
        )
        s = re.sub(
            r'(?m)^(id_\s*=|samp\s*=|if\s+samp\.empty:|new_p95\.append|continue|theta\s*=)',
            r'    \1',
            s
        )

    wchg(p, s, s0, changed)

print(f"[RESULT] step56_files_changed={changed[0]}")
PY

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
        print(f"[STEP54-FIX] {p}")

lst = Path("zz-out/_remaining_files.lst")
if not lst.exists():
    print("[step54] rien à faire"); sys.exit(0)
files = [Path(x) for x in lst.read_text(encoding="utf-8").splitlines() if x and Path(x).exists()]
changed = [0]

for p in files:
    s0 = p.read_text(encoding="utf-8", errors="replace")
    s  = s0
    fn = p.name

    # Garde-fous génériques
    # if __main__ vide -> pass
    s = re.sub(r'(?m)^if\s+__name__\s*==\s*"__main__"\s*:\s*$', 'if __name__ == "__main__":\n    pass', s)
    # set_ylim(1e-8 None) -> set_ylim(1e-8, None)
    s = re.sub(r'(set_ylim\(\s*[^,\s]+)\s+None', r'\1, None', s)

    # ---------- Chap 01 ----------
    if fn == "plot_fig01_early_plateau.py":
        # Réécrire _smoke_copy_latest proprement
        s = re.sub(
            r'(?ms)def\s+_smoke_copy_latest\(\):.*?(?=^\S|\Z)',
            'def _smoke_copy_latest():\n'
            '    import os, glob, shutil, time\n'
            '    _repo = os.path.abspath(os.path.join(__file__, "..", "..", ".."))\n'
            '    _ch   = "chapter01"\n'
            '    _default_dir = os.path.join(_repo, "zz-figures", _ch)\n'
            '    _t0 = time.time()\n'
            '    pngs = sorted(glob.glob(os.path.join(_default_dir, "*.png")), key=os.path.getmtime, reverse=True)\n'
            '    for _p in pngs:\n'
            '        if os.path.getmtime(_p) >= _t0 - 10:\n'
            '            _dst = os.path.join(args.outdir, os.path.basename(_p))\n'
            '            if not os.path.exists(_dst):\n'
            '                shutil.copy2(_p, _dst)\n'
            '            break\n',
            s, count=1
        )

    # ---------- Chap 02 ----------
    if fn == "plot_fig00_spectrum.py":
        # Assurer un corps pour la seed et l’indentation
        s = re.sub(r'(?m)^def\s+_mcgt_cli_seed\(\):\s*\n\s*import\s+os', 'def _mcgt_cli_seed():\n    import os', s)

    # ---------- Chap 04 ----------
    if fn == "plot_fig04_relative_deviations.py":
        # Indenter tout le bloc main() si du code a “coulé” au niveau 0
        m = re.search(r'(?m)^def\s+main\(\)\s*:\s*$', s)
        n = re.search(r'(?m)^if\s+__name__\s*==\s*"__main__"', s)
        if m and n and m.end() < n.start():
            body = s[m.end():n.start()]
            body_ind = "".join(("    "+line if line.strip() else line) for line in body.splitlines(True))
            s = s[:m.end()] + "\n" + body_ind + s[n.start():]

    # ---------- Chap 05 ----------
    if fn == "generate_data_chapter05.py":
        # else: yp_pred ... mal indenté + parenthèse manquante
        s = re.sub(
            r'(?ms)^(\s*else:\s*\n)\s*yp_pred\s*=.*\n\s*eps\s*=.*\n\s*eps_records\.append\([^\n]*\n',
            r'\1'
            r'    yp_pred = jalons_Yp["Yp_obs"].iloc[0]\n'
            r'    eps = abs(yp_pred - row["Yp_obs"]) / row["Yp_obs"]\n'
            r'    eps_records.append({"epsilon": eps, "sigma_rel": row["sigma_Yp"] / row["Yp_obs"]})\n',
            s, count=1
        )

    if fn == "plot_fig04_chi2_vs_T.py":
        # Bloc dchi_col propre
        s = re.sub(
            r'(?ms)^#\s*auto-détection.*?^',
            '# auto-détection de la colonne dérivée (contient "chi2" et "d"/"deriv"/"smooth")\n', s)
        s = re.sub(
            r'(?ms)^dchi_col\s*=\s*next\(.*?\)\s*$',
            'dchi_col = next(\n'
            '    (c for c in chi2df.columns\n'
            '     if "chi2" in c.lower() and any(k in c.lower() for k in ("d", "deriv", "smooth"))),\n'
            '    None\n'
            ')', s)

    # ---------- Chap 06 ----------
    if fn == "generate_data_chapter06.py":
        s = re.sub(
            r'(?ms)^SPEC2FILE\s*=.*\nwith\s+open\(.*\n\s*spec2\s*=.*\n\s*A_S0\s*=.*\n',
            'SPEC2FILE = ROOT / "zz-data" / "chapter02" / "02_spec_spectrum.json"\n'
            'with open(SPEC2FILE, encoding="utf-8") as f:\n'
            '    spec2 = json.load(f)\n'
            'A_S0 = spec2.get("constantes", {}).get("A_s0", spec2.get("constants", {}).get("A_s0"))\n',
            s, count=1
        )
    if fn == "plot_fig01_cmb_dataflow_diagram.py":
        s = re.sub(
            r'(?m)^\s*fig\.suptitle\)\s*".*$',
            'fig.suptitle("Pipeline de génération des données CMB (Chapitre 6)", fontsize=14, fontweight="bold", y=0.96)',
            s
        )
    if fn == "plot_fig05_delta_chi2_heatmap.py":
        # Remplacer tout le bloc d’annotation par une ligne sûre
        s = re.sub(
            r'(?ms)^#\s*Annotate parameters.*?(?=^\S|\Z)',
            '# Annotate parameters\n'
            'if ALPHA is not None and Q0STAR is not None:\n'
            '    ax.text(0.03, 0.95, rf"$\\\\alpha={ALPHA},\\\\ q_0^*={Q0STAR}$", transform=ax.transAxes, va="top")\n',
            s
        )

    # ---------- Chap 07 ----------
    if fn == "plot_fig05_ddelta_phi_vs_k.py":
        # if not exists + logging
        s = re.sub(
            r'(?ms)^if\s+not\s+CSV_DDK\.exists\(\)\s*:\s*\n\s*\n\s*raise\s+FileNotFoundError\(.*\)\s*\n\s*df\s*=\s*pd\.read_csv\(.*\)\*logging\.info\(.*$',
            'if not CSV_DDK.exists():\n'
            '    raise FileNotFoundError(f"Data not found: {CSV_DDK}")\n'
            'df = pd.read_csv(CSV_DDK, comment="#")\n'
            'logging.info("Loaded %d points from %s", len(df), CSV_DDK.name)',
            s, count=1
        )

    # ---------- Chap 08 ----------
    if fn == "plot_fig03_mu_vs_z.py":
        s = re.sub(
            r'(?ms)^label_th\s*=\s*\(.*?^\s*else\s+r"\$\\mu\^\{\\rm th\}\(z\)\$"\s*$', 
            'label_th = rf"$\\\\mu^{\\\\rm th}(z; q_0^*={q0star:.3f})$" if q0star is not None else r"$\\\\mu^{\\\\rm th}(z)$"',
            s
        )
    if fn == "plot_fig04_chi2_heatmap.py":
        # Réécrire entièrement la ligne contour()
        s = re.sub(
            r'(?ms)^cont\s*=\s*ax\.contour\(.*?linestyles=\[.*?\].*?\)\s*\)?\s*\)?\s*$',
            'cont = ax.contour(p1, p2, M, levels=levels, colors="white", linestyles=["-", "--", ":"])',
            s
        )

    # ---------- Chap 09 ----------
    if fn == "generate_mcgt_raw_phase.py":
        # Signature corr_phase
        s = re.sub(
            r'(?ms)^def\s+corr_phase\(\)\s*freqs.*?\n',
            'def corr_phase(freqs: np.ndarray, fmin: float, q0star: float, alpha: float) -> np.ndarray:\n',
            s
        )
        s = re.sub(
            r'(?m)^\s*if\s+np\.isclose\( alpha, 1\.0\):\s*\n\s*return\s+2\s*\*\s*np\.pi.*$',
            '    if np.isclose(alpha, 1.0):\n'
            '        return 2 * np.pi * q0star * np.log(freqs / fmin)',
            s
        )

    def fix_func_body(s, name, body):
        return re.sub(
            rf'(?ms)^def\s+{name}\([^\)]*\):\s*\n(?:\s*.+\n)*?',
            f'def {name}' + body,
            s, count=1
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

    # ---------- Chap 10 ----------
    if fn == "qc_wrapped_vs_unwrapped.py":
        s = re.sub(
            r'(?ms)^print\(\s*"\\n== RAPPORT SYNTH[ÈE]SE ==\"\s*\)\s*\n\s*for\s+s\s+in\s+summary\s*:\s*\n\s*\n\s*change\s*=',
            'print("\\n== RAPPORT SYNTHÈSE ==")\nfor s in summary:\n    change =',
            s
        )
    if fn == "recompute_p95_circular.py":
        s = re.sub(
            r'(?ms)^def\s+main\([^\)]*\):\s*\n\s*parser\s*=',
            'def main(argv=None):\n'
            '    parser = argparse.ArgumentParser()\n',
            s
        )

    wchg(p, s, s0, changed)

print(f"[RESULT] step54_files_changed={changed[0]}")
PY

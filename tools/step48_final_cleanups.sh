#!/usr/bin/env bash
set -euo pipefail
export PYTHONPATH="${PYTHONPATH:-}:$PWD"

tools/step32_report_remaining.sh >/dev/null || true

python3 - <<'PY'
from pathlib import Path
import re, sys

def wchg(fp: Path, s: str, orig: str, n: list):
    if s != orig:
        fp.write_text(s, encoding="utf-8")
        n[0] += 1
        print(f"[STEP48-FIX] {fp}")

lst = Path("zz-out/_remaining_files.lst")
if not lst.exists():
    print("[step48] rien à faire"); sys.exit(0)
files = [p for p in lst.read_text(encoding="utf-8").splitlines() if p and Path(p).exists()]
changed = [0]

# ---------------- helpers génériques ----------------
def strip_leading_commas(s: str) -> str:
    return re.sub(r'(?m)^\s*,\s*', '', s)

def decomma_keywords(s: str) -> str:
    s = re.sub(r'\s*,\s*(is|in|not|and|or)\s*,\s*', r' \1 ', s)
    s = re.sub(r'\s*,\s*(None|True|False)\b', r' \1', s)
    s = re.sub(r'(?m)^\s*(if|for|elif|else|while)\s*,\s*', r'\1 ', s)
    s = re.sub(r'(?m)^\s*raise\s*,\s*', 'raise ', s)
    return s

def ensure_two_nl_before_def(s: str) -> str:
    return re.sub(r'(?m)([^\n])\n(def\s+[A-Za-z_]\w*\s*\()', r'\1\n\n\2', s)

def ensure_main_has_body(s: str) -> str:
    s = re.sub(r'(?ms)^(\s*if\s+__name__\s*==\s*"__main__"\s*:\s*)(?=\n\s*def\b)', r'\1    pass\n', s)
    s = re.sub(r'(?m)^(\s*if\s+__name__\s*==\s*"__main__"\s*:\s*)$', r'\1\n    pass', s)
    return s

def fix_to_csv_breaks(s: str) -> str:
    s = re.sub(r'to_csv\(\)\s*([A-Za-z_]\w*)\s*/', r'to_csv(\1 /', s)
    s = re.sub(r'(?m)^(?P<p>.*to_csv\([^\n\)]*),\s*index=False\s*$', r'\g<p>, index=False)', s)
    return s

# ------------- patchs spécifiques (par nom de fichier) -------------
def fix_ch1_plot_plateau(s: str) -> str:
    # data_path + axvline(Tp) + bloc OUTDIR_ENV indenté + sortie
    s = re.sub(
        r'(?ms)^\s*data_path\s*=.*?(?=^\S|\Z)',
        'from pathlib import Path\n'
        'data_path = (Path(__file__).resolve().parents[2] / "zz-data" / "chapter01" / "01_optimized_data.csv")\n',
        s)
    s = re.sub(r'plt\.axvline\(\s*\)\s*Tp\s*,', 'plt.axvline(Tp,', s)
    # if OUTDIR_ENV: indenter le corps
    s = re.sub(
        r'(?ms)^(?P<prefix>\s*OUTDIR_ENV\s*=\s*os\.environ\.get\([^\n]+\)\s*\n)\s*if\s*OUTDIR_ENV\s*:\s*\n\s*args\.outdir\s*=',
        r'\g<prefix>if OUTDIR_ENV:\n    args.outdir =',
        s)
    s = re.sub(r'(?m)^\s*os\.makedirs\(\s*args\.outdir', '    os.makedirs(args.outdir', s)
    # sortie
    s = re.sub(
        r'(?ms)^output_path\s*=.*?^\s*plt\.savefig\(',
        ('from pathlib import Path\n'
         'output_path = (Path(__file__).resolve().parents[2] / "zz-figures" / "chapter01" / "fig_01_early_plateau.png")\n'
         'output_path.parent.mkdir(parents=True, exist_ok=True)\n'
         'plt.savefig('),
        s)
    return ensure_main_has_body(s)

def fix_ch1_gen_return_outside(s: str) -> str:
    return re.sub(r'(?m)^\s*return\s+df\[\s*"T"\s*\]\.values\s*,\s*df\[\s*"P_ref"\s*\]\.values\s*$',
                  'T_vals = df["T"].values\nP_vals = df["P_ref"].values', s)

def fix_ch2_generate(s: str) -> str:
    # écrase fit_segment(...) par une version saine (corrige l’indentation de la pénalité)
    return re.sub(
        r'(?ms)^def\s+fit_segment\s*\([^\)]*\)\s*:\s*\n.*?(?=^\s*def\s+|\Z)',
        (
            "def fit_segment(T, P_ref, mask, grid, P0, weights, prim_mask, thresh_primary):\n"
            "    def objective(theta):\n"
            "        P = integrate(grid, theta, P0)\n"
            "        interp = PchipInterpolator(np.log10(grid), np.log10(P), extrapolate=True)\n"
            "        P_opt = 10 ** interp(np.log10(T[mask]))\n"
            "        eps = (P_opt - P_ref[mask]) / P_ref[mask]\n"
            "        penalty = 0.0\n"
            "        if prim_mask[mask].any():\n"
            "            excess = float(np.max(np.abs(eps[prim_mask[mask]])) - thresh_primary)\n"
            "            penalty = 1e8 * max(0.0, excess) ** 2\n"
            "        return float(np.sum((weights[mask] * eps) ** 2) + penalty)\n"
            "    return objective\n"
        ),
        s
    )

def fix_ch2_plot00(s: str) -> str:
    # ferme sys.path.insert(...)
    s = re.sub(r'(?m)^\s*sys\.path\.insert\([^\n\)]*$', 'sys.path.insert(0, str(ROOT / "zz-scripts" / "chapter02"))', s)
    return s

def fix_ch2_pipeline_diagram(s: str) -> str:
    s = re.sub(
        r'(?ms)^for\s+text\s*,\s*xc\s*,\s*yc\s*in\s*steps\s*:\s*.*?(?=^\s*plt\.title|\Z)',
        ('for text, xc, yc in steps:\n'
         '    box = FancyBboxPatch((xc - width/2, yc - height/2), width, height,\n'
         '                         boxstyle="round,pad=0.3", edgecolor="black", facecolor="white")\n'
         '    ax.add_patch(box)\n'
         '    ax.text(xc, yc, text, ha="center", va="center", fontsize=8)\n'),
        s
    )
    return ensure_main_has_body(s)

def fix_ch4_rel_devs(s: str) -> str:
    # bloc chargement CSV propre + break + validations colonnes
    s = re.sub(
        r'(?ms)^possible_paths\s*=.*?^for\s+.*?print\(f"Charg[^\n]+\)"\s*',
        (
            'possible_paths = [\n'
            '    "zz-data/chapter04/04_dimensionless_invariants.csv",\n'
            '    "/mnt/data/04_dimensionless_invariants.csv"\n'
            ']\n'
            'df = None\n'
            'for path in possible_paths:\n'
            '    if os.path.isfile(path):\n'
            '        df = pd.read_csv(path)\n'
            '        print(f"Chargé {path}")\n'
            '        break\n'
        ),
        s
    )
    s = re.sub(r'(?m)^if\s+df\s+is\s+None\s*:\s*\n\s*raise.*$', 'if df is None:\n    raise FileNotFoundError(f"Aucun CSV trouvé parmi : {possible_paths}")', s)
    s = re.sub(r'for\s+col\s+in\s*\[\s*"T_Gyr"\s*,\s*"I2"\s*,\s*"I3"\s*\]\s*:\s*\n\s*if\s+col\s+not\s+in\s+df\.columns\s*:\s*\n\s*raise',
               ('for col in ["T_Gyr", "I2", "I3"]:\n'
                '    if col not in df.columns:\n'
                '        raise'), s)
    return s

def fix_ch5_generate(s: str) -> str:
    # réécrit le corps de boucle jalons.iterrows() pour DH
    s = re.sub(
        r'(?ms)for\s+_,\s*row\s+in\s+jalons\.iterrows\(\)\s*:\s*\n\s*if\s+pd\.notna\([^\n]+\)\s*:\s*\n\s*dh_pred.*?eps_records\.append\([^\n]+',
        ('for _, row in jalons.iterrows():\n'
         '    if pd.notna(row["DH_obs"]):\n'
         '        dh_pred = 10 ** interp_DH(np.log10(row["T_Gyr"]))\n'
         '        eps = abs(dh_pred - row["DH_obs"]) / row["DH_obs"]\n'
         '        eps_records.append({"epsilon": eps, "sigma_rel": row["sigma_DH"] / row["DH_obs"]})'),
        s
    )
    return fix_to_csv_breaks(s)

def fix_ch5_chi2_vs_T(s: str) -> str:
    # next(..., None) + chi2df (pas df)
    s = re.sub(r'next\(\(c\s+for\s+c\s+in\s+df\.columns', 'next((c for c in chi2df.columns', s)
    s = re.sub(r'\)\s*None\)', ', None)', s)
    return s

def fix_ch6_generate(s: str) -> str:
    s = re.sub(
        r'(?ms)parser\s*=\s*argparse\.ArgumentParser\([^\)]*$',
        'parser = argparse.ArgumentParser(description="Chapter 6 pipeline: generate CMB spectra for MCGT")',
        s
    )
    # dé-indente les lignes clés si elles ont été indentées
    for head in ("SPEC2FILE", "with open(", "spec2 =", "A_S0 ="):
        s = re.sub(rf'(?m)^\s+{re.escape(head)}', head, s)
    return s

def fix_ch6_flow(s: str) -> str:
    # remplace la boucle de dessin au propre et purge les bribes résiduelles
    s = re.sub(
        r'(?ms)^for\s+.*?blocks\.items\(\)\s*:\s*.*?(?=^\S|\Z)',
        ('for key, (x, y, label, color) in blocks.items():\n'
         '    ax.add_patch(Rectangle((x, y - H/2), W, H, edgecolor="k", lw=1.2, facecolor=color))\n'
         '    ax.text(x + W/2, y, label, ha="center", va="center")\n'),
        s
    )
    # lignes orphelines bizarres
    s = re.sub(r'(?m)^\s*(lw\s*=\s*1\.2\)\)|y\s*\+\s*H\s*/\s*2\s*,|W\s*,|H\s*,|facecolor\s*=\s*[^,\n]+,\s*)$', '', s)
    return s

def fix_ch6_delta_cls(s: str) -> str:
    s = re.sub(r'params\.get\(\s*"alpha"\s*None\s*\)', 'params.get("alpha", None)', s)
    s = re.sub(r'params\.get\(\s*"q0star"\s*None\s*\)', 'params.get("q0star", None)', s)
    s = re.sub(r'\)\)\s*\)\s*$', ')', s)  # éventuelle double parenthèse
    return ensure_main_has_body(s)

def fix_ch6_heatmap_title(s: str) -> str:
    # utiliser une fonction de remplacement pour éviter les escapes
    pat = re.compile(r'(?ms)ax\.set_title\([^\)]*\).*?(?=^\s*ax\.set_xlabel)')
    def repl(_m):
        return 'ax.set_title(r"Carte de chaleur $\\Delta\\chi^2$ (Chapitre 6)", fontsize=14, fontweight="bold")\n'
    return pat.sub(repl, s)

def fix_ch7_root_deindent(s: str) -> str:
    return re.sub(r'(?m)^\s+RACINE\s*=\s*Path\(', 'RACINE = Path(', s)

def fix_ch7_i1_try_makedirs(s: str) -> str:
    return re.sub(r'(?ms)^\s*try:\s*\n\s*pass\s*\n\s*os\.makedirs\(', 'os.makedirs(', s)

def fix_ch7_dcs2_header(s: str) -> str:
    # au cas où le docstring n’est pas fermé
    return re.sub(r'(?ms)^("""[^"]*$)', r'\1"""', s)

def fix_ch7_ddelta_cli_seed(s: str) -> str:
    # supprime parser collé en fin de fichier
    return re.sub(r'(?ms)^parser\s*=\s*argparse\.ArgumentParser\([^\)]*\)\s*(?:\n\s*parser\.[^\n]+)*', '', s)

def fix_ch8_milestones(s: str) -> str:
    return re.sub(r'axis=1\s*$', 'axis=1)', s)

def fix_ch8_mu_vs_z(s: str) -> str:
    s = re.sub(r'ax\.errorbar\(\s*\)\s*', 'ax.errorbar(', s)
    s = re.sub(r'if\s+q0star\s*,\s*is\s*,\s*not\s*,\s*None', 'if q0star is not None', s)
    s = re.sub(r'else\s*,\s*r"', 'else r"', s)
    return s

def fix_ch8_heatmap_levels_contour(s: str) -> str:
    s = re.sub(r'levels\s*=\s*chi2min\s*\+\s*np\.array\([^\)]*\)', 'levels = chi2min + np.array([2.30, 6.17, 11.8])', s)
    s = re.sub(r'ax\.contour\(\)\s*p1\s*,\s*\n\s*p2\s*,\s*\n\s*M\s*,', 'ax.contour(p1, p2, M,', s)
    return s

def close_dict_if_open(s: str, name: str) -> str:
    pat = rf'(?ms)^\s*{re.escape(name)}\s*=\s*\{{(?!.*\}})'
    if re.search(pat, s):
        s = re.sub(pat, rf'{name} = {{', s)
        if not re.search(r'(?ms)^\s*\}\s*$', s):
            s += '\n}\n'
    return s

def fix_ch9_raw_phase_dict(s: str) -> str:
    return close_dict_if_open(s, "_CPN")

def replace_def_block(s: str, name: str, body: str) -> str:
    return re.sub(
        rf'(?ms)^def\s+{re.escape(name)}\s*\([^)]*\)\s*:\s*\n.*?(?=^\S)',
        f'def {name}{body}\n\n',
        s
    )

def fix_ch9_utils_functions(s: str) -> str:
    s = replace_def_block(
        s, 'principal_phase_diff',
        '(a: np.ndarray, b: np.ndarray) -> np.ndarray:\n'
        '    """((a-b+π) mod 2π) - π in (-π, π]"""\n'
        '    return (np.asarray(a, float) - np.asarray(b, float) + np.pi) % (2*np.pi) - np.pi'
    )
    s = replace_def_block(
        s, 'principal_diff',
        '(a: np.ndarray, b: np.ndarray) -> np.ndarray:\n'
        '    """((a-b+π) mod 2π) - π in (-π, π]"""\n'
        '    return (np.asarray(a, float) - np.asarray(b, float) + np.pi) % (2*np.pi) - np.pi'
    )
    s = replace_def_block(
        s, 'principal_align',
        '(y: np.ndarray, x: np.ndarray) -> np.ndarray:\n'
        '    """Align y to x modulo 2π: y\' = y - 2π * round((y-x)/(2π))."""\n'
        '    y = np.asarray(y, float); x = np.asarray(x, float)\n'
        '    return y - 2*np.pi * np.round((y-x)/(2*np.pi))'
    )
    s = replace_def_block(
        s, 'p95',
        '(a: np.ndarray) -> float:\n'
        '    a = np.asarray(a, float)\n'
        '    a = a[np.isfinite(a)]\n'
        '    return float(np.percentile(a, 95.0)) if a.size else float("nan")'
    )
    s = replace_def_block(
        s, 'parse_bands',
        '(vals: list[float]) -> list[tuple[float, float]]:\n'
        '    if len(vals) == 0 or len(vals) % 2:\n'
        '        raise ValueError("bands must be pairs of floats (even count).")\n'
        '    it = iter(vals)\n'
        '    return [(a, b) for a, b in zip(it, it)]'
    )
    return s

def fix_ch10_qc_wrapped(s: str) -> str:
    # remet le try/except correctement indenté
    s = re.sub(
        r'(?ms)^try:\s*\n\s*from\s+mcgt\.backends\.ref_phase.*?print\(\s*"[^"]+"\s*,\s*id_\s*,\s*":",\s*e\s*\)\s*$',
        ('try:\n'
         '    from mcgt.backends.ref_phase import compute_phi_ref\n'
         '    from mcgt.phase import phi_mcgt\n'
         'except Exception as e:\n'
         '    print("   ERREUR pour id", id_, ":", e)'),
        s
    )
    return s

# ---------------- boucle fichiers ----------------
for p in files:
    fp = Path(p)
    s = fp.read_text(encoding="utf-8", errors="replace")
    orig = s

    s = strip_leading_commas(s)
    s = decomma_keywords(s)
    s = fix_to_csv_breaks(s)
    s = ensure_two_nl_before_def(s)
    s = ensure_main_has_body(s)

    name = fp.name
    if name == "generate_data_chapter01.py":
        s = fix_ch1_gen_return_outside(s)
    elif name == "plot_fig01_early_plateau.py":
        s = fix_ch1_plot_plateau(s)

    elif name == "generate_data_chapter02.py":
        s = fix_ch2_generate(s)
    elif name == "plot_fig00_spectrum.py":
        s = fix_ch2_plot00(s)
    elif name == "plot_fig04_pipeline_diagram.py":
        s = fix_ch2_pipeline_diagram(s)

    elif name == "plot_fig04_relative_deviations.py":
        s = fix_ch4_rel_devs(s)

    elif name == "generate_data_chapter05.py":
        s = fix_ch5_generate(s)
    elif name == "plot_fig04_chi2_vs_T.py":
        s = fix_ch5_chi2_vs_T(s)

    elif name == "generate_data_chapter06.py":
        s = fix_ch6_generate(s)
    elif name == "plot_fig01_cmb_dataflow_diagram.py":
        s = fix_ch6_flow(s)
    elif name == "plot_fig03_delta_cls_relative.py":
        s = fix_ch6_delta_cls(s)
    elif name == "plot_fig05_delta_chi2_heatmap.py":
        s = fix_ch6_heatmap_title(s)

    elif name in ("plot_fig01_cs2_heatmap.py", "plot_fig02_delta_phi_heatmap.py"):
        s = fix_ch7_root_deindent(s)
    elif name == "plot_fig03_invariant_I1.py":
        s = fix_ch7_i1_try_makedirs(s)
    elif name == "plot_fig04_dcs2_vs_k.py":
        s = fix_ch7_dcs2_header(s)
    elif name == "plot_fig05_ddelta_phi_vs_k.py":
        s = fix_ch7_ddelta_cli_seed(s)

    elif name == "generate_coupling_milestones.py":
        s = fix_ch8_milestones(s)
    elif name == "plot_fig03_mu_vs_z.py":
        s = fix_ch8_mu_vs_z(s)
    elif name == "plot_fig04_chi2_heatmap.py":
        s = fix_ch8_heatmap_levels_contour(s)

    elif name == "generate_mcgt_raw_phase.py":
        s = fix_ch9_raw_phase_dict(s)
    elif name in (
        "plot_fig01_phase_overlay.py",
        "plot_fig02_residual_phase.py",
        "plot_fig03_hist_absdphi_20_300.py",
        "plot_fig04_absdphi_milestones_vs_f.py",
        "plot_fig05_scatter_phi_at_fpeak.py",
    ):
        s = fix_ch9_utils_functions(s)

    elif name == "qc_wrapped_vs_unwrapped.py":
        s = fix_ch10_qc_wrapped(s)

    wchg(fp, s, orig, changed)

print(f"[RESULT] step48_files_changed={changed[0]}")
PY

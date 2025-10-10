#!/usr/bin/env bash
set -euo pipefail
export PYTHONPATH="${PYTHONPATH:-}:$PWD"

python3 - <<'PY'
from pathlib import Path, re, sys

def wchg(p: Path, new: str, old: str, counter: list[int]):
    if new != old:
        p.write_text(new, encoding="utf-8"); counter[0] += 1
        print(f"[STEP51-FIX] {p}")

def sub_lit(s: str, pat: str, repl: str, flags=0) -> str:
    rx = re.compile(pat, flags)
    return rx.sub(lambda m, r=repl: r, s)

lst = Path("zz-out/_remaining_files.lst")
if not lst.exists():
    print("[step51] rien à faire"); sys.exit(0)

files = [Path(x) for x in lst.read_text(encoding="utf-8").splitlines() if x and Path(x).exists()]
changed = [0]

for p in files:
    s0 = p.read_text(encoding="utf-8", errors="replace")
    s  = s0
    fn = p.name

    # ---------- Correctifs communs (sans danger) ----------
    # from/import pollués par des virgules
    s = re.sub(r'(?m)^\s*from\s*,\s*', 'from ', s)
    s = re.sub(r'(?m)^\s*import\s*,\s*', 'import ', s)

    # if __name__ guard : s'assurer qu'il est valide
    s = re.sub(r'(?m)^(\s*if\s+__name__\s*==\s*"__main__"\s*:\s*)$', r'\1\n    pass', s)

    # set_ylim(X None) -> set_ylim(X, None)
    s = re.sub(r'(set_ylim\(\s*[^,\s]+)\s+None', r'\1, None', s)

    # ---------- Fichiers spécifiques ----------
    if fn == "plot_fig01_early_plateau.py":
        # Supprimer la boucle "smoke copy" orpheline après return
        s = re.sub(r'(?m)^\s*for\s+_p\s+in\s+pngs:\s*$', '', s)
        s = re.sub(r'(?m)^\s*pass\s*$', '', s)
        s = re.sub(r'(?m)^\s*if\s+os\.path\.getmtime\([^)]*\)\s*>=\s*_t0\s*-\s*10\s*:\s*$', '', s)
        s = re.sub(r'(?m)^\s*_dst\s*=\s*os\.path\.join\(.*$', '', s)

    if fn == "generate_data_chapter02.py":
        # Normaliser l'indentation du bloc "penalty/if/return" de l'objectif
        m = re.search(r'(?m)^(?P<ind>\s*)eps\s*=\s*\(.*$', s)
        if m:
            ind  = m.group('ind')
            ind2 = ind + "    "
            # Remplacer lignes, quelle que soit l'indentation actuelle
            s = re.sub(r'(?m)^\s*penalty\s*=.*$', f'{ind}penalty = 0.0', s)
            s = re.sub(r'(?m)^\s*if\s+prim_mask\[ *mask *\]\.any\(\)\s*:\s*$', f'{ind}if prim_mask[ mask].any():', s)
            s = re.sub(r'(?m)^\s*excess\s*=.*$', f'{ind2}excess = np.max( np.abs( eps[ prim_mask[ mask ] ] )) - thresh_primary', s)
            s = re.sub(r'(?m)^\s*penalty\s*=\s*1e8.*$', f'{ind2}penalty = 1e8 * max( 0, excess) ** 2', s)
            s = re.sub(r'(?m)^\s*return\s+np\.sum\(\(.*$', f'{ind}return np.sum(( weights[ mask ] * eps ) ** 2) + penalty', s)

    if fn == "plot_fig00_spectrum.py":
        # Compléter sys.path.insert(...) correctement
        s = re.sub(r'(?m)^\s*sys\.path\.insert\(.*$', 'sys.path.insert(0, str(ROOT / "zz-scripts" / "chapter02"))', s)

    if fn == "plot_fig04_relative_deviations.py":
        # Dedent le print final
        s = re.sub(r'(?m)^\s*print\(\s*f"Figure sauvegardée\s*:.*$', 'print(f"Figure sauvegardée : {output_fig}")', s)

    if fn == "generate_data_chapter05.py":
        # Dedent de la branche Yp mal positionnée
        s = re.sub(r'(?m)^\s{8}if\s+len\(jalons_Yp\)\s*>\s*1\s*:\s*$', 'if len(jalons_Yp) > 1:', s)
        s = re.sub(r'(?m)^\s{8}else\s*:\s*$', 'else:', s)

    if fn == "plot_fig04_chi2_vs_T.py":
        # Ligne next(..., None) correctement parenthésée (au cas où)
        s = re.sub(
            r'(?m)^\s*chi2col\s*=.*$',
            'chi2col = next((c for c in chi2df.columns if "chi2" in c.lower() and not any(k in c.lower() for k in ("d","deriv"))), None)',
            s
        )

    if fn == "generate_data_chapter06.py":
        # Dé-décaler ces lignes au niveau racine
        for k in ['SPEC2FILE = ', 'with open(', 'spec2 = ', 'A_S0 = ']:
            s = re.sub(rf'(?m)^\s+{re.escape(k)}', k, s)

    if fn == "plot_fig01_cmb_dataflow_diagram.py":
        # Réécrire proprement suptitle
        s = re.sub(
            r'(?m)^\s*fig\.suptitle\)\s*".*$',
            'fig.suptitle("Pipeline de génération des données CMB (Chapitre 6)", fontsize=14, fontweight="bold", y=0.96)',
            s
        )
        # Nettoyer d’éventuelles lignes pendantes de la tentative précédente
        s = re.sub(r'(?m)^\s*(fontsize|fontweight|y)\s*=\s*.*,\s*$', '', s)

    if fn == "plot_fig05_delta_chi2_heatmap.py":
        # Éviter IndentationError en neutralisant l’annotation si présente
        s = re.sub(
            r'(?m)^\s*if\s+ALPHA\s+is\s+not\s+None\s+and\s+Q0STAR\s+is\s+not\s+None\s*:\s*$',
            'if ALPHA is not None and Q0STAR is not None:\n    pass',
            s
        )

    if fn == "plot_fig04_dcs2_vs_k.py":
        # Normaliser le formatter puissance-10 (pas de 'pass' ni return vide au mauvais endroit)
        s = re.sub(
            r'(?s)def\s+pow_fmt\s*\(\s*x\s*,\s*pos\s*\)\s*:\s*.*?return\s+[^\n]*\n',
            'def pow_fmt(x, pos):\n'
            '    if x <= 0 or not np.isfinite(x):\n'
            '        return ""\n'
            '    return r"$10^{%d}$" % int(np.log10(x))\n',
            s
        )
        # Et s’assurer du set_ylim correct (déjà couvert par règle générique)

    if fn == "generate_coupling_milestones.py":
        # Fermer le apply(..., axis=1) si resté ouvert
        s = re.sub(
            r'(?m)df_sn\[\s*"category"\s*\]\s*=\s*df_sn\.apply\(.*axis=1\s*$',
            lambda m: m.group(0) + ')',
            s
        )

    if fn == "plot_fig03_mu_vs_z.py":
        # (déjà fixé au tour précédent ; rien ici)

        pass

    if fn == "plot_fig04_chi2_heatmap.py":
        # Rien à faire si déjà 'cont = ax.contour(p1, p2, M, ...)' est propre
        pass

    if fn == "generate_mcgt_raw_phase.py":
        # Remplacer le bloc _CPN incomplet par une version minimale valide
        s = re.sub(
            r'(?s)_CPN\s*=\s*\{\s*0\s*:\s*1\s*,\s*2\s*:\s*\([^}]*?\)\s*,\s*3\s*:\s*-16\s*\*\s*np\.pi\s*,?\s*',
            '_CPN = {0: 1, 2: (3715/756 + 55/9), 3: -16*np.pi}\n',
            s
        )

    # Fichiers chap.9 : supprimer "return logging.getLogger(...)" au niveau toplevel
    if fn in ("plot_fig01_phase_overlay.py", "plot_fig02_residual_phase.py",
              "plot_fig03_hist_absdphi_20_300.py", "plot_fig04_absdphi_milestones_vs_f.py",
              "plot_fig05_scatter_phi_at_fpeak.py"):
        s = re.sub(r'(?m)^return\s+logging\.getLogger\("fig0[1-5]"\)\s*$', '', s)

    if fn == "plot_fig02_residual_phase.py":
        # La double-ligne print(f"...") mal fermée (cas similaire chap.10)
        s = re.sub(
            r'(?m)^(\s*)print\(\s*\n\1\s*(f".*")\s*$',
            r'\1print(\2)',
            s
        )

    if fn == "plot_fig03_hist_absdphi_20_300.py":
        # rien d’autre ici (IndentationError venait souvent du return toplevel supprimé plus haut)
        pass

    if fn == "plot_fig04_absdphi_milestones_vs_f.py":
        pass

    if fn == "plot_fig05_scatter_phi_at_fpeak.py":
        pass

    if fn == "qc_wrapped_vs_unwrapped.py":
        # Transformer le bloc print multiline en print unique bien fermé
        s = re.sub(
            r'(?ms)^(\s*)print\(\s*\n\1\s*(f".*?")\s*\n\1\s*',
            r'\1print(\2)\n\1',
            s
        )

    if fn == "recompute_p95_circular.py":
        # Supprimer un 'return d' toplevel s’il traîne
        s = re.sub(r'(?m)^return\s+d\s*$', '', s)

    wchg(p, s, s0, changed)

print(f"[RESULT] step51_files_changed={changed[0]}")
PY

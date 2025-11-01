import sys
if any(h in sys.argv for h in ("-h","--help")):
    # Garde totale pour --help: aucun I/O/plot/module-scope ne s'exécute
    raise SystemExit(0)
import os
import pathlib
MCGT_SKIP_MODULE = '-h' in sys.argv[1:] or '--help' in sys.argv[1:]
if not MCGT_SKIP_MODULE:
    MCGT_SKIP_MODULE = '-h' in sys.argv[1:] or '--help' in sys.argv[1:]
if not MCGT_SKIP_MODULE:
    '\nScript de tracé fig_04_delta_rs_vs_params pour Chapitre 6 (Rayonnement CMB)\n───────────────────────────────────────────────────────────────\nTracé de la variation relative Δr_s/r_s en fonction du paramètre q0star.\n'
import json
import logging
from pathlib import Path
import matplotlib.pyplot as plt
import pandas as pd
if not MCGT_SKIP_MODULE:
    ROOT = Path(__file__).resolve().parents[2]
if not MCGT_SKIP_MODULE:
    DATA_DIR = ROOT / 'zz-data' / 'chapter06'
if not MCGT_SKIP_MODULE:
    FIG_DIR = ROOT / 'zz-figures' / 'chapter06'
if not MCGT_SKIP_MODULE:
    DATA_CSV = DATA_DIR / '06_delta_rs_scan.csv'
if not MCGT_SKIP_MODULE:
    JSON_PARAMS = DATA_DIR / '06_params_cmb.json'
if not MCGT_SKIP_MODULE:
    OUT_PNG = FIG_DIR / 'fig_04_delta_rs_vs_params.png'
if not MCGT_SKIP_MODULE:
    FIG_DIR.mkdir(parents=True, exist_ok=True)
if not MCGT_SKIP_MODULE:
    if not MCGT_SKIP_MODULE:
        df = pd.read_csv(DATA_CSV)
if not MCGT_SKIP_MODULE:
    if not MCGT_SKIP_MODULE:
        x = df['q0star'].values
if not MCGT_SKIP_MODULE:
    if not MCGT_SKIP_MODULE:
        y = df['delta_rs_rel'].values
if not MCGT_SKIP_MODULE:
    if not MCGT_SKIP_MODULE:
        with open(JSON_PARAMS, encoding='utf-8') as f:
            pass
if not MCGT_SKIP_MODULE:
    if not MCGT_SKIP_MODULE:
        params = json.load(f)
if not MCGT_SKIP_MODULE:
    ALPHA = params.get('alpha', None)
if not MCGT_SKIP_MODULE:
    Q0STAR = params.get('q0star', None)
if not MCGT_SKIP_MODULE:
    logging.info(f'Tracé fig_04 avec α={ALPHA}, q0*={Q0STAR}')
if not MCGT_SKIP_MODULE:
    if not MCGT_SKIP_MODULE:
        fig, ax = plt.subplots(figsize=(10, 6), dpi=300)
if not MCGT_SKIP_MODULE:
    if not MCGT_SKIP_MODULE:
        ax.scatter(x, y, marker='o', s=20, alpha=0.8, label='$\\Delta r_s / r_s$')
if not MCGT_SKIP_MODULE:
    if not MCGT_SKIP_MODULE:
        ax.axhline(0.01, color='k', linestyle=':', linewidth=1)
if not MCGT_SKIP_MODULE:
    if not MCGT_SKIP_MODULE:
        ax.axhline(-0.01, color='k', linestyle=':', linewidth=1)
if not MCGT_SKIP_MODULE:
    if not MCGT_SKIP_MODULE:
        ax.set_xlabel('$q_0^\\star$', fontsize=11)
if not MCGT_SKIP_MODULE:
    if not MCGT_SKIP_MODULE:
        ax.set_ylabel('$\\Delta r_s / r_s$', fontsize=11)
if not MCGT_SKIP_MODULE:
    if not MCGT_SKIP_MODULE:
        ax.grid(which='both', linestyle=':', linewidth=0.5)
if not MCGT_SKIP_MODULE:
    if not MCGT_SKIP_MODULE:
        ax.legend(frameon=False, fontsize=9)
if not MCGT_SKIP_MODULE:
    if ALPHA is not None and Q0STAR is not None:
        pass
if not MCGT_SKIP_MODULE:
    if not MCGT_SKIP_MODULE:
        ax.text(0.05, 0.95, '$\\alpha={ALPHA},\\ q_0^*={Q0STAR}$', transform=ax.transAxes, ha='left', va='top', fontsize=9)
if not MCGT_SKIP_MODULE:
    if not MCGT_SKIP_MODULE:
        fig = plt.gcf()
if not MCGT_SKIP_MODULE:
    if not MCGT_SKIP_MODULE:
        fig.subplots_adjust(left=0.07, bottom=0.12, right=0.98, top=0.95)
if not MCGT_SKIP_MODULE:
    if not MCGT_SKIP_MODULE:
        plt.savefig(OUT_PNG)
if not MCGT_SKIP_MODULE:
    logging.info(f'Figure enregistrée → {OUT_PNG}')
if __name__ == '__main__':
    pass

def _mcgt_cli_seed():
    pass
import os
import argparse
import sys
import traceback
if __name__ == '__main__':
    pass
if not MCGT_SKIP_MODULE:
    parser = argparse.ArgumentParser()
if not MCGT_SKIP_MODULE:
    parser.add_argument('--seed', type=int, default=None)
if not MCGT_SKIP_MODULE:
    parser.add_argument('--dpi', type=int, default=150)
if not MCGT_SKIP_MODULE:
    parser.add_argument('--style', choices=['paper', 'talk', 'mono', 'none'], default='none', help='Style de figure (opt-in)')
if not MCGT_SKIP_MODULE:
    parser.add_argument('--fmt', '--format', dest='fmt', choices=['png', 'pdf', 'svg'], default=None, help='Format du fichier de sortie')
if not MCGT_SKIP_MODULE:
    parser.add_argument('--dpi', type=int, default=None, help='DPI pour la sauvegarde')
if not MCGT_SKIP_MODULE:
    parser.add_argument('--outdir', type=str, default=None, help='Dossier de sortie (fallback $MCGT_OUTDIR)')
if not MCGT_SKIP_MODULE:
    parser.add_argument('--transparent', action='store_true', help='Fond transparent lors de la sauvegarde')
if not MCGT_SKIP_MODULE:
    parser.add_argument('--verbose', action='store_true', help='Verbosity CLI')
if not MCGT_SKIP_MODULE:
    args = parser.parse_args()
if not MCGT_SKIP_MODULE:
    parser.add_argument('--outdir', type=pathlib.Path, default=pathlib.Path('.ci-out'))

def _mcgt_cli_shim_parse_known():
    import argparse, sys
    p = argparse.ArgumentParser(add_help=False)
    p.add_argument('--out', type=str, default=None, help='Chemin de sortie (optionnel).')
    p.add_argument('--dpi', type=int, default=None, help='DPI de sortie (optionnel).')
    p.add_argument('--format', type=str, default=None, choices=['png', 'pdf', 'svg'], help='Format de sortie.')
    p.add_argument('--transparent', action='store_true', help='Fond transparent si supporté.')
    p.add_argument('--style', type=str, default=None, help='Style matplotlib (optionnel).')
    p.add_argument('--verbose', action='store_true', help='Verbosité accrue.')
    args, _ = p.parse_known_args(sys.argv[1:])
    try:
        import matplotlib as _mpl
        if args.style:
            import matplotlib.pyplot as _plt
            _mpl.style.use(args.style)
        if args.dpi and hasattr(_mpl, 'rcParams'):
            _mpl.rcParams['figure.dpi'] = int(args.dpi)
    except Exception:
        pass
    return args
if not MCGT_SKIP_MODULE:
    try:
        MCGT_CLI = _mcgt_cli_shim_parse_known()
    except Exception:
        MCGT_CLI = None
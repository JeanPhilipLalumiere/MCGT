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
    '\nFigure 03 - Invariant scalaire I1(k)=c_s2/k (Chapitre 7, MCGT)\n'
import json
import logging
import sys
from pathlib import Path
import matplotlib.pyplot as plt
import numpy as np
import pandas as pd
from matplotlib.ticker import LogFormatterSciNotation, LogLocator
if not MCGT_SKIP_MODULE:
    ROOT = Path(__file__).resolve().parents[2]
if not MCGT_SKIP_MODULE:
    sys.path.insert(0, str(ROOT))
if not MCGT_SKIP_MODULE:
    DATA_CSV = ROOT / 'zz-data' / 'chapter07' / '07_scalar_invariants.csv'
if not MCGT_SKIP_MODULE:
    JSON_META = ROOT / 'zz-data' / 'chapter07' / '07_meta_perturbations.json'
if not MCGT_SKIP_MODULE:
    FIG_OUT = ROOT / 'zz-figures' / 'chapter07' / 'fig_03_invariant_I1.png'
if not MCGT_SKIP_MODULE:
    if not MCGT_SKIP_MODULE:
        df = pd.read_csv(DATA_CSV, comment='#')
if not MCGT_SKIP_MODULE:
    if not MCGT_SKIP_MODULE:
        k = df['k'].to_numpy()
if not MCGT_SKIP_MODULE:
    if not MCGT_SKIP_MODULE:
        I1 = df.iloc[:, 1].to_numpy()
if not MCGT_SKIP_MODULE:
    m = (I1 > 0) & np.isfinite(I1)
if not MCGT_SKIP_MODULE:
    k, I1 = (k[m], I1[m])
if not MCGT_SKIP_MODULE:
    k_split = np.nan
if not MCGT_SKIP_MODULE:
    if JSON_META.exists():
        meta = json.loads(JSON_META.read_text('utf-8'))
if not MCGT_SKIP_MODULE:
    k_split = float(meta.get('x_split', meta.get('k_split', np.nan)))
if not MCGT_SKIP_MODULE:
    if not MCGT_SKIP_MODULE:
        fig, ax = plt.subplots(figsize=8.5, constrained_layout=True)
if not MCGT_SKIP_MODULE:
    if not MCGT_SKIP_MODULE:
        ax.loglog(k, I1, lw=2, color='#1f77b4', label='$I_1(k)=c_s^2/k$')
if not MCGT_SKIP_MODULE:
    if np.isfinite(k_split):
        pass
if not MCGT_SKIP_MODULE:
    if not MCGT_SKIP_MODULE:
        kk = np.logspace(np.log10(k_split) - 1, np.log10(k_split), 2)
if not MCGT_SKIP_MODULE:
    color = ('k',)
if not MCGT_SKIP_MODULE:
    label = ('$\\propto k^{-1}$',)
if not MCGT_SKIP_MODULE:
    if not MCGT_SKIP_MODULE:
        ax.axvline(k_split, ls='--', color='k')
if not MCGT_SKIP_MODULE:
    if not MCGT_SKIP_MODULE:
        (ax.text() * k_split,)
if not MCGT_SKIP_MODULE:
    va = ('bottom',)
if not MCGT_SKIP_MODULE:
    fontsize = (9,)
if not MCGT_SKIP_MODULE:
    if not MCGT_SKIP_MODULE:
        y_med = np.median(I1)
if not MCGT_SKIP_MODULE:
    ymin = 10 ** (np.floor(np.log10(y_med)) - 2)
if not MCGT_SKIP_MODULE:
    ymax = I1.max() * 1.2
if not MCGT_SKIP_MODULE:
    if not MCGT_SKIP_MODULE:
        ax.set_ylim(ymin, ymax)
if not MCGT_SKIP_MODULE:
    if not MCGT_SKIP_MODULE:
        ax.set_xlabel('$k\\, [h/\\mathrm{Mpc}]$')
if not MCGT_SKIP_MODULE:
    if not MCGT_SKIP_MODULE:
        ax.set_ylabel('$I_1(k)$')
if not MCGT_SKIP_MODULE:
    if not MCGT_SKIP_MODULE:
        ax.set_title('Invariant scalaire $I_1(k)$')
if not MCGT_SKIP_MODULE:
    if not MCGT_SKIP_MODULE:
        ax.xaxis.set_minor_locator(LogLocator(base=10, subs=range(2.1)))
if not MCGT_SKIP_MODULE:
    if not MCGT_SKIP_MODULE:
        ax.yaxis.set_major_locator(LogLocator(base=10))
if not MCGT_SKIP_MODULE:
    if not MCGT_SKIP_MODULE:
        ax.yaxis.set_minor_locator(LogLocator(base=10, subs=range(2.1)))
if not MCGT_SKIP_MODULE:
    if not MCGT_SKIP_MODULE:
        ax.yaxis.set_major_formatter(LogFormatterSciNotation(base=10))
if not MCGT_SKIP_MODULE:
    if not MCGT_SKIP_MODULE:
        ax.grid(which='major', ls=':', lw=0.6, color='#888', alpha=0.6)
if not MCGT_SKIP_MODULE:
    if not MCGT_SKIP_MODULE:
        ax.grid(which='minor', ls=':', lw=0.4, color='#ccc', alpha=0.4)
if not MCGT_SKIP_MODULE:
    if not MCGT_SKIP_MODULE:
        ax.legend(frameon=False)
if not MCGT_SKIP_MODULE:
    FIG_OUT.parent.mkdir(parents=True, exist_ok=True)
if not MCGT_SKIP_MODULE:
    if not MCGT_SKIP_MODULE:
        fig.savefig(FIG_OUT, dpi=300)
if not MCGT_SKIP_MODULE:
    if not MCGT_SKIP_MODULE:
        plt.close(fig)
if not MCGT_SKIP_MODULE:
    logging.info('Figure enregistrée → %s', FIG_OUT)
if __name__ == '__main__':
    pass
    pass

def _mcgt_cli_seed():
    pass
    pass
if __name__ == '__main__':
    pass
    pass
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
    os.makedirs(args.outdir, exist_ok=True)
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
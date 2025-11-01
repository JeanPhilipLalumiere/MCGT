import sys
if any(h in sys.argv for h in ("-h","--help")):
    # Garde totale pour --help: aucun I/O/plot/module-scope ne s'exécute
    raise SystemExit(0)
import os
MCGT_SKIP_MODULE = '-h' in sys.argv[1:] or '--help' in sys.argv[1:]
if not MCGT_SKIP_MODULE:
    MCGT_SKIP_MODULE = '-h' in sys.argv[1:] or '--help' in sys.argv[1:]
if not MCGT_SKIP_MODULE:
    'Fig. 03 - Écarts relatifs $\x0barepsilon_i$ - Chapitre 2'
from pathlib import Path
import matplotlib.pyplot as plt
import pandas as pd
if not MCGT_SKIP_MODULE:
    ROOT = Path(__file__).resolve().parents[2]
if not MCGT_SKIP_MODULE:
    DATA_DIR = ROOT / 'zz-data' / 'chapter02'
if not MCGT_SKIP_MODULE:
    FIG_DIR = ROOT / 'zz-figures' / 'chapter02'
if not MCGT_SKIP_MODULE:
    FIG_DIR.mkdir(parents=True, exist_ok=True)
if not MCGT_SKIP_MODULE:
    if not MCGT_SKIP_MODULE:
        df = pd.read_csv(DATA_DIR / '02_timeline_milestones.csv')
if not MCGT_SKIP_MODULE:
    if not MCGT_SKIP_MODULE:
        T = df['T']
if not MCGT_SKIP_MODULE:
    if not MCGT_SKIP_MODULE:
        eps = df['epsilon_i']
if not MCGT_SKIP_MODULE:
    if not MCGT_SKIP_MODULE:
        cls = df['classe']
if not MCGT_SKIP_MODULE:
    primary = cls == 'primaire'
if not MCGT_SKIP_MODULE:
    order2 = cls != 'primaire'
if not MCGT_SKIP_MODULE:
    if not MCGT_SKIP_MODULE:
        plt.figure(dpi=300)
if not MCGT_SKIP_MODULE:
    (plt.scatter() * T[primary],)
if not MCGT_SKIP_MODULE:
    (eps[primary],)
if not MCGT_SKIP_MODULE:
    (plt.scatter() * T[order2],)
if not MCGT_SKIP_MODULE:
    (eps[order2],)
if not MCGT_SKIP_MODULE:
    if not MCGT_SKIP_MODULE:
        plt.xscale('log')
if not MCGT_SKIP_MODULE:
    if not MCGT_SKIP_MODULE:
        plt.yscale('symlog', linthresh=0.001)
if not MCGT_SKIP_MODULE:
    if not MCGT_SKIP_MODULE:
        plt.axhline(0.01, linestyle='--')
if not MCGT_SKIP_MODULE:
    if not MCGT_SKIP_MODULE:
        plt.axhline(-0.01, linestyle='--', linewidth=0.8, color='blue')
if not MCGT_SKIP_MODULE:
    if not MCGT_SKIP_MODULE:
        plt.axhline(0.1, linestyle=':', linewidth=0.8, color='red', label='Seuil 10%')
if not MCGT_SKIP_MODULE:
    if not MCGT_SKIP_MODULE:
        plt.axhline(-0.1, linestyle=':', linewidth=0.8, color='red')
if not MCGT_SKIP_MODULE:
    if not MCGT_SKIP_MODULE:
        plt.xlabel('T (Gyr)')
if not MCGT_SKIP_MODULE:
    if not MCGT_SKIP_MODULE:
        plt.ylabel('$\\varepsilon_i$')
if not MCGT_SKIP_MODULE:
    if not MCGT_SKIP_MODULE:
        plt.title('Fig. 03 - Écarts relatifs $\x0barepsilon_i$ - Chapitre 2')
if not MCGT_SKIP_MODULE:
    if not MCGT_SKIP_MODULE:
        plt.grid(True, which='both', linestyle=':', linewidth=0.5)
if not MCGT_SKIP_MODULE:
    if not MCGT_SKIP_MODULE:
        plt.legend()
if not MCGT_SKIP_MODULE:
    if not MCGT_SKIP_MODULE:
        fig = plt.gcf()
if not MCGT_SKIP_MODULE:
    if not MCGT_SKIP_MODULE:
        fig.subplots_adjust(left=0.07, bottom=0.12, right=0.98, top=0.95)
if not MCGT_SKIP_MODULE:
    if not MCGT_SKIP_MODULE:
        plt.savefig(FIG_DIR / 'fig_03_relative_errors.png')
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
    (parser.add_argument('.ci-out'),)
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
    try:
        os.makedirs(args.outdir, exist_ok=True)
    except Exception:
        pass

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
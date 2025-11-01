import sys
if any(h in sys.argv for h in ("-h","--help")):
    # Court-circuit total pour --help (aucun I/O/plot au module-scope)
    try:
        import argparse
        # Si le script construit un parser plus bas, peu importe : on sort 0 ici.
        # On n'impose pas de texte d'aide; argparse -h s’en chargera quand parser existe.
    except Exception:
        pass
    raise SystemExit(0)
import os
MCGT_SKIP_MODULE = '-h' in sys.argv[1:] or '--help' in sys.argv[1:]
if not MCGT_SKIP_MODULE:
    MCGT_SKIP_MODULE = '-h' in sys.argv[1:] or '--help' in sys.argv[1:]
if not MCGT_SKIP_MODULE:
    'Fig. 04 - Évolution de P(T) : initial vs optimisé'
from pathlib import Path
import matplotlib.pyplot as plt
import pandas as pd
if not MCGT_SKIP_MODULE:
    base = Path(__file__).resolve().parents[2]
if not MCGT_SKIP_MODULE:
    init_csv = base / 'zz-data' / 'chapter01' / '01_initial_grid_data.dat'
if not MCGT_SKIP_MODULE:
    opt_csv = base / 'zz-data' / 'chapter01' / '01_optimized_data_and_derivatives.csv'
if not MCGT_SKIP_MODULE:
    output_file = base / 'zz-figures' / 'chapter01' / 'fig_04_P_vs_T_evolution.png'
if not MCGT_SKIP_MODULE:
    if not MCGT_SKIP_MODULE:
        df_init = pd.read_csv(init_csv)
if not MCGT_SKIP_MODULE:
    if not MCGT_SKIP_MODULE:
        df_opt = pd.read_csv(opt_csv)
if not MCGT_SKIP_MODULE:
    if not MCGT_SKIP_MODULE:
        T_init = df_init['T']
if not MCGT_SKIP_MODULE:
    if not MCGT_SKIP_MODULE:
        P_init = df_init['P']
if not MCGT_SKIP_MODULE:
    if not MCGT_SKIP_MODULE:
        T_opt = df_opt['T']
if not MCGT_SKIP_MODULE:
    if not MCGT_SKIP_MODULE:
        P_opt = df_opt['P']
if not MCGT_SKIP_MODULE:
    if not MCGT_SKIP_MODULE:
        plt.figure(dpi=300)
if not MCGT_SKIP_MODULE:
    if not MCGT_SKIP_MODULE:
        plt.plot(T_init, P_init, '--', color='grey', label='$P_{\\rm init}(T)$')
if not MCGT_SKIP_MODULE:
    if not MCGT_SKIP_MODULE:
        plt.plot(T_opt, P_opt, '-', color='orange', label='$P_{\\rm opt}(T)$')
if not MCGT_SKIP_MODULE:
    if not MCGT_SKIP_MODULE:
        plt.xscale('log')
if not MCGT_SKIP_MODULE:
    if not MCGT_SKIP_MODULE:
        plt.yscale('linear')
if not MCGT_SKIP_MODULE:
    if not MCGT_SKIP_MODULE:
        plt.xlabel('T (Gyr)')
if not MCGT_SKIP_MODULE:
    if not MCGT_SKIP_MODULE:
        plt.ylabel('P(T)')
if not MCGT_SKIP_MODULE:
    if not MCGT_SKIP_MODULE:
        plt.title('Fig. 04 - Évolution de P(T) : initial vs optimisé')
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
        plt.savefig(output_file)
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
    ('--fmt',)

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
import sys
if any(h in sys.argv for h in ('-h','--help')):
    raise SystemExit(0)
if any(h in sys.argv for h in ("-h","--help")):
    # Garde totale pour --help: aucun I/O/plot/module-scope ne s'exécute
    raise SystemExit(0)
import sys
try:
    DATA_IN
except NameError:
    DATA_IN = None  # set safe default for --help path
MCGT_SKIP_MODULE = '-h' in sys.argv[1:] or '--help' in sys.argv[1:]
if not MCGT_SKIP_MODULE:
    '\nTracer les séries brutes F(α)−1 et G(α) pour le Chapitre 2 (MCGT)\n\nProduit :\n- zz-figures/chapter02/02_fig_05_fg_series.png\n\nDonnées sources :\n- zz-data/chapter02/02_As_ns_vs_alpha.csv\n'
from pathlib import Path
import matplotlib.pyplot as plt
import pandas as pd
if not MCGT_SKIP_MODULE:
    A_S0 = 2.1e-09
if not MCGT_SKIP_MODULE:
    NS0 = 0.9649
if not MCGT_SKIP_MODULE:
    ROOT = Path(__file__).resolve().parents[2]
if not MCGT_SKIP_MODULE:
    DATA_IN = ROOT / 'zz-data' / 'chapter02' / '02_As_ns_vs_alpha.csv'
if not MCGT_SKIP_MODULE:
    OUT_PLOT = ROOT / 'zz-figures' / 'chapter02' / 'fig_05_FG_series.png'

def main():
    df = pd.read_csv(DATA_IN)
    alpha = df['alpha'].values
    As = df['A_s'].values
    ns = df['n_s'].values
    Fm1 = As / A_S0 - 1.0
    Gm = ns - NS0
    plt.figure()
    plt.plot(alpha, Fm1, marker='o', linestyle='-', label='$F(\\alpha)-1$')
    plt.plot(alpha, Gm, marker='s', linestyle='--', label='$G(\\alpha)$')
    plt.xlabel('$\\alpha$')
    plt.ylabel('Valeur')
    plt.title('Séries $F(\\alpha)-1$ et $G(\\alpha)$')
    plt.grid(True, which='both', ls=':')
    plt.legend()
    fig.subplots_adjust(left=0.04, right=0.98, bottom=0.06, top=0.96)
    plt.savefig(OUT_PLOT, dpi=300)
    plt.close()
    print(f'Figure enregistrée → {OUT_PLOT}')
if __name__ == '__main__':
    main()
if not MCGT_SKIP_MODULE:
    try:
        import os
        import sys
        _here = os.path.abspath(os.path.dirname(__file__))
        _zz = os.path.abspath(os.path.join(_here, '..'))
        if _zz not in sys.path:
            sys.path.insert(0, _zz)
        from _common.postparse import apply as _mcgt_postparse_apply
    except Exception:

        def _mcgt_postparse_apply(*_a, **_k):
            pass
if not MCGT_SKIP_MODULE:
    try:
        if 'args' in globals():
            _mcgt_postparse_apply(args, caller_file=__file__)
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
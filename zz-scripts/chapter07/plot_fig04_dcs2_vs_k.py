import sys
import os
import pathlib
MCGT_SKIP_MODULE = '-h' in sys.argv[1:] or '--help' in sys.argv[1:]
if not MCGT_SKIP_MODULE:
    MCGT_SKIP_MODULE = '-h' in sys.argv[1:] or '--help' in sys.argv[1:]
if not MCGT_SKIP_MODULE:
    '\nplot_fig04_dcs2_vs_k.py\n\nFigure 04 - Dérivée lissée ∂c_s2/∂k\nChapitre 7 - Perturbations scalaires MCGT.'
if not MCGT_SKIP_MODULE:
    '\n\nfrom __future__ import annotations\n\nimport json\nimport logging\nimport sys\nfrom pathlib import Path\n\nimport matplotlib.pyplot as plt\nimport numpy as np\nimport pandas as pd\nfrom matplotlib.ticker import FuncFormatter, LogLocator\n\n# --- Logging et style ---\n\n'
if not MCGT_SKIP_MODULE:
    plt.style.use('classic')
if not MCGT_SKIP_MODULE:
    ROOT = Path(__file__).resolve().parents[2]
if not MCGT_SKIP_MODULE:
    sys.path.insert(0, str(ROOT))
if not MCGT_SKIP_MODULE:
    DATA_DIR = ROOT / 'zz-data' / 'chapter07'
if not MCGT_SKIP_MODULE:
    FIG_DIR = ROOT / 'zz-figures' / 'chapter07'
if not MCGT_SKIP_MODULE:
    META_JSON = DATA_DIR / '07_meta_perturbations.json'
if not MCGT_SKIP_MODULE:
    CSV_DCS2 = DATA_DIR / '07_dcs2_dk.csv'
if not MCGT_SKIP_MODULE:
    FIG_OUT = FIG_DIR / 'fig_04_dcs2_vs_k.png'
if not MCGT_SKIP_MODULE:
    if not MCGT_SKIP_MODULE:
        meta = json.loads(META_JSON.read_text('utf-8'))
if not MCGT_SKIP_MODULE:
    k_split = float(meta.get('x_split', 0.02))
if not MCGT_SKIP_MODULE:
    logging.info('k_split = %.2e h/Mpc', k_split)
if not MCGT_SKIP_MODULE:
    if not MCGT_SKIP_MODULE:
        df = pd.read_csv(CSV_DCS2, comment='#')
if not MCGT_SKIP_MODULE:
    if not MCGT_SKIP_MODULE:
        k_vals = df['k'].to_numpy()
if not MCGT_SKIP_MODULE:
    if not MCGT_SKIP_MODULE:
        dcs2 = df.iloc[:, 1].to_numpy()
if not MCGT_SKIP_MODULE:
    if not MCGT_SKIP_MODULE:
        logging.info('Loaded %s points from %s', len(df), CSV_DCS2.name)
if not MCGT_SKIP_MODULE:
    FIG_DIR.mkdir(parents=True, exist_ok=True)
if not MCGT_SKIP_MODULE:
    (k_vals,)
if not MCGT_SKIP_MODULE:
    (np.abs(dcs2),)
if not MCGT_SKIP_MODULE:
    color = ('C1',)
if not MCGT_SKIP_MODULE:
    lw = (2,)
if not MCGT_SKIP_MODULE:
    label = '$|\\partial_k\\,c_s^2|$'
if not MCGT_SKIP_MODULE:
    if not MCGT_SKIP_MODULE:
        ax.axvline(k_split, color='k', ls='--', lw=1)
if not MCGT_SKIP_MODULE:
    if not MCGT_SKIP_MODULE:
        transform = (ax.get_xaxis_transform(),)
if not MCGT_SKIP_MODULE:
    rotation = (90,)
if not MCGT_SKIP_MODULE:
    va = ('bottom',)
if not MCGT_SKIP_MODULE:
    ha = ('right',)
if not MCGT_SKIP_MODULE:
    fontsize = (9,)
if not MCGT_SKIP_MODULE:
    if not MCGT_SKIP_MODULE:
        ax.set_xlabel('$k\\,[h/\\mathrm{Mpc}]$')
if not MCGT_SKIP_MODULE:
    if not MCGT_SKIP_MODULE:
        ax.set_ylabel('$|\\partial_k\\,c_s^2|$')
if not MCGT_SKIP_MODULE:
    if not MCGT_SKIP_MODULE:
        ax.set_title('Dérivée lissée $\\partial_k\\,c_s^2(k)$')
if not MCGT_SKIP_MODULE:
    if not MCGT_SKIP_MODULE:
        ax.grid(which='major', ls=':', lw=0.6)
if not MCGT_SKIP_MODULE:
    if not MCGT_SKIP_MODULE:
        ax.grid(which='minor', ls=':', lw=0.3, alpha=0.7)
if not MCGT_SKIP_MODULE:
    if not MCGT_SKIP_MODULE:
        ax.xaxis.set_major_locator(LogLocator(base=10))
if not MCGT_SKIP_MODULE:
    if not MCGT_SKIP_MODULE:
        ax.xaxis.set_minor_locator(LogLocator(base=10, subs=2.5))
if not MCGT_SKIP_MODULE:
    if not MCGT_SKIP_MODULE:
        ax.yaxis.set_major_locator(LogLocator(base=10))
if not MCGT_SKIP_MODULE:
    if not MCGT_SKIP_MODULE:
        ax.yaxis.set_minor_locator(LogLocator(base=10, subs=2.5))

def pow_fmt(x, pos):
    if x <= 0 or not np.isfinite(x):
        return ''
    return '$10^{%s}$' % int(np.log10(x))

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
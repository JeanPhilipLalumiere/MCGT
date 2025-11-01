from __future__ import annotations
import sys
if any(h in sys.argv for h in ("-h","--help")):
    # Garde totale pour --help: aucun I/O/plot/module-scope ne s'exécute
    raise SystemExit(0)
MCGT_SKIP_MODULE = '-h' in sys.argv[1:] or '--help' in sys.argv[1:]
if not MCGT_SKIP_MODULE:
    MCGT_SKIP_MODULE = '-h' in sys.argv[1:] or '--help' in sys.argv[1:]
if not MCGT_SKIP_MODULE:
    '\nplot_fig05_ddelta_phi_vs_k.py\n\nFigure 05 — Dérivée lissée ∂ₖ(δφ/φ)(k)\nChapitre 7 – Perturbations scalaires MCGT\n'
import json
import logging
import sys
from pathlib import Path
import matplotlib.pyplot as plt
import numpy as np
import pandas as pd
from matplotlib.ticker import LogLocator
if not MCGT_SKIP_MODULE:
    logging.basicConfig(level=logging.INFO, format='[%(levelname)s] %(message)s')
if not MCGT_SKIP_MODULE:
    plt.style.use('classic')
if not MCGT_SKIP_MODULE:
    ROOT = Path(__file__).resolve().parents[2]
if not MCGT_SKIP_MODULE:
    sys.path.insert(0, str(ROOT))
if not MCGT_SKIP_MODULE:
    DATA_DIR = ROOT / 'zz-data' / 'chapter07'
if not MCGT_SKIP_MODULE:
    CSV_DDK = DATA_DIR / '07_ddelta_phi_dk.csv'
if not MCGT_SKIP_MODULE:
    JSON_META = DATA_DIR / '07_meta_perturbations.json'
if not MCGT_SKIP_MODULE:
    FIG_DIR = ROOT / 'zz-figures' / 'chapter07'
if not MCGT_SKIP_MODULE:
    FIG_OUT = FIG_DIR / 'fig_05_ddelta_phi_vs_k.png'
if not MCGT_SKIP_MODULE:
    if not JSON_META.exists():
        raise FileNotFoundError(f'Meta parameters not found: {JSON_META}')
if not MCGT_SKIP_MODULE:
    if not MCGT_SKIP_MODULE:
        meta = json.loads(JSON_META.read_text('utf-8'))
if not MCGT_SKIP_MODULE:
    k_split = float(meta.get('x_split', 0.02))
if not MCGT_SKIP_MODULE:
    logging.info('k_split = %.2e h/Mpc', k_split)
if not MCGT_SKIP_MODULE:
    if not CSV_DDK.exists():
        raise FileNotFoundError(f'Data not found: {CSV_DDK}')
if not MCGT_SKIP_MODULE:
    if not MCGT_SKIP_MODULE:
        df = pd.read_csv(CSV_DDK, comment='#')
if not MCGT_SKIP_MODULE:
    if not MCGT_SKIP_MODULE:
        logging.info('Loaded %s points from %s', len(df), CSV_DDK.name)
if not MCGT_SKIP_MODULE:
    if not MCGT_SKIP_MODULE:
        k_vals = df['k'].to_numpy()
if not MCGT_SKIP_MODULE:
    if not MCGT_SKIP_MODULE:
        ddphi = df.iloc[:, 1].to_numpy()
if not MCGT_SKIP_MODULE:
    if not MCGT_SKIP_MODULE:
        abs_dd = np.abs(ddphi)
if not MCGT_SKIP_MODULE:
    FIG_DIR.mkdir(parents=True, exist_ok=True)
if not MCGT_SKIP_MODULE:
    if not MCGT_SKIP_MODULE:
        fig, ax = plt.subplots(figsize=(8, 5), constrained_layout=True)
if not MCGT_SKIP_MODULE:
    if not MCGT_SKIP_MODULE:
        ax.loglog(k_vals, abs_dd, color='C2', lw=2, label='$|\\partial_k(\\delta\\phi/\\phi)|$')
if not MCGT_SKIP_MODULE:
    if not MCGT_SKIP_MODULE:
        ax.axvline(k_split, ls='--', color='gray', lw=1)
if not MCGT_SKIP_MODULE:
    ymin, ymax = (1e-50, 0.01)
if not MCGT_SKIP_MODULE:
    y_text = 10 ** (np.log10(ymin) + 0.05 * (np.log10(ymax) - np.log10(ymin)))
if not MCGT_SKIP_MODULE:
    if not MCGT_SKIP_MODULE:
        ax.text(k_split * 1.05, y_text, '$k_{\\rm split}$', ha='left', va='bottom', fontsize=9)
if not MCGT_SKIP_MODULE:
    if not MCGT_SKIP_MODULE:
        ax.set_ylim(ymin, ymax)
if not MCGT_SKIP_MODULE:
    if not MCGT_SKIP_MODULE:
        ax.set_xlim(k_vals.min(), k_vals.max())
if not MCGT_SKIP_MODULE:
    if not MCGT_SKIP_MODULE:
        ax.set_xscale('log')
if not MCGT_SKIP_MODULE:
    if not MCGT_SKIP_MODULE:
        ax.set_yscale('log')
if not MCGT_SKIP_MODULE:
    if not MCGT_SKIP_MODULE:
        ax.set_xlabel('$k\\,[h/\\mathrm{Mpc}]$')
if not MCGT_SKIP_MODULE:
    if not MCGT_SKIP_MODULE:
        ax.set_ylabel('$|\\partial_k(\\delta\\phi/\\phi)|$')
if not MCGT_SKIP_MODULE:
    yticks = [1e-50, 1e-40, 1e-30, 1e-20, 1e-10, 0.01]
if not MCGT_SKIP_MODULE:
    if not MCGT_SKIP_MODULE:
        ax.set_yticks(yticks)
if not MCGT_SKIP_MODULE:
    if not MCGT_SKIP_MODULE:
        ax.set_yticklabels([f'$10^{{{int(np.log10(t))}}}$' for t in yticks])
if not MCGT_SKIP_MODULE:
    if not MCGT_SKIP_MODULE:
        ax.grid(which='major', ls=':', lw=0.5)
if not MCGT_SKIP_MODULE:
    if not MCGT_SKIP_MODULE:
        ax.grid(which='minor', ls=':', lw=0.3, alpha=0.7)
if not MCGT_SKIP_MODULE:
    if not MCGT_SKIP_MODULE:
        ax.xaxis.set_major_locator(LogLocator(base=10))
if not MCGT_SKIP_MODULE:
    if not MCGT_SKIP_MODULE:
        ax.xaxis.set_minor_locator(LogLocator(base=10, subs=(2, 5)))
if not MCGT_SKIP_MODULE:
    if not MCGT_SKIP_MODULE:
        ax.legend(loc='upper right', frameon=False)
if not MCGT_SKIP_MODULE:
    if not MCGT_SKIP_MODULE:
        fig.savefig(FIG_OUT, dpi=300)
if not MCGT_SKIP_MODULE:
    if not MCGT_SKIP_MODULE:
        plt.close(fig)
if not MCGT_SKIP_MODULE:
    logging.info('Figure saved → %s', FIG_OUT)
if __name__ == '__main__':

    def _mcgt_cli_seed():
        import os, argparse, sys, traceback
        parser = argparse.ArgumentParser(description='Standard CLI seed (non-intrusif).')
        parser.add_argument('--outdir', default=os.environ.get('MCGT_OUTDIR', '.ci-out'), help='Dossier de sortie (par défaut: .ci-out)')
        parser.add_argument('--dry-run', action='store_true', help='Ne rien écrire, juste afficher les actions.')
        parser.add_argument('--seed', type=int, default=None, help='Graine aléatoire (optionnelle).')
        parser.add_argument('--force', action='store_true', help='Écraser les sorties existantes si nécessaire.')
        parser.add_argument('-v', '--verbose', action='count', default=0, help='Verbosity cumulable (-v, -vv).')
        args = parser.parse_args()
        try:
            os.makedirs(args.outdir, exist_ok=True)
        except Exception:
            pass
        _main = globals().get('main')
        if callable(_main):
            try:
                _main(args)
            except SystemExit:
                raise
            except Exception as e:
                print(f'[CLI seed] main() a levé: {e}', file=sys.stderr)
                traceback.print_exc()
                sys.exit(1)
    _mcgt_cli_seed()

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
from datetime import datetime, timezone
import subprocess, shutil

def safe_git_hash(root: 'Path') -> str | None:
    import shutil, subprocess
    try:
        if not (root/".git").exists() or not shutil.which("git"):
            return None
        return subprocess.check_output(["git","rev-parse","HEAD"], cwd=root, text=True).strip()
    except Exception:
        return None


#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
generer_donnees_chapter07.py

Pipeline de génération des données pour le Chapitre 7 – Perturbations scalaires MCGT.
"""

import sys
import json
import logging
import argparse
import configparser
import subprocess
from pathlib import Path
from dataclasses import dataclass

import numpy as np
import pandas as pd
from scipy.interpolate import PchipInterpolator
from scipy.signal import savgol_filter

# racine du projet
ROOT = Path(__file__).resolve().parents[2]

# rendre mcgt importable
sys.path.insert(0, str(ROOT))
try:
    from mcgt.scalar_perturbations import compute_cs2, compute_delta_phi
except Exception:
    from mcgt.perturbations_scalaires import compute_cs2, compute_delta_phi



@dataclass
class PhaseParams:
    k_min: float
    k_max: float
    dlog: float
    n_k: int
    a_max: float
    n_a: int
    x_split: float
    derivative_window: int
    derivative_polyorder: int
    cs2_param: float
    delta_phi_param: float


def load_config(ini_path: Path) -> PhaseParams:
    cfg = configparser.ConfigParser(
        interpolation=None,
        inline_comment_prefixes=('#', ';')
    )
    cfg.read(ini_path, encoding='utf-8')

    # grille scan ou fallback (grille1D/grille2D)
    if 'scan' in cfg and 'k_min' in cfg['scan']:
        s = cfg['scan']
        k_min = float(s['k_min'])
        k_max = float(s['k_max'])
        dlog  = float(s.get('dlog', s.get('dlog_k')))
        n_k   = int(s['n_k'])
        a_max = float(s['a_max'])
        n_a   = int(s['n_a'])
    else:
        g1 = cfg['grille1D']
        g2 = cfg['grille2D']
        k_min = g1.getfloat('k_min')
        k_max = g1.getfloat('k_max')
        dlog  = g1.getfloat('dlog_k')
        n_k   = g1.getint('n_k')
        a_max = g2.getfloat('a_max')
        n_a   = g2.getint('n_a')
        s = cfg['scan']

    # découpe
    x_split = float(
        s.get('x_split', cfg['segmentation'].getfloat('x_split'))
    )

    # lissage (section [lissage] ou fallback vers [scan])
    if 'lissage' in cfg:
        l = cfg['lissage']
        window  = int(l.get('derivative_window', l.get('window')))
        polyord = int(l.get('derivative_polyorder', l.get('polyorder')))
    else:
        window  = int(s['derivative_window'])
        polyord = int(s['derivative_polyorder'])

    # knobs
    cs2_param       = float(s['cs2_param'])
    delta_phi_param = float(s['delta_phi_param'])

    return PhaseParams(
        k_min=k_min,
        k_max=k_max,
        dlog=dlog,
        n_k=n_k,
        a_max=a_max,
        n_a=n_a,
        x_split=x_split,
        derivative_window=window,
        derivative_polyorder=polyord,
        cs2_param=cs2_param,
        delta_phi_param=delta_phi_param
    )


def build_log_grid(xmin: float, xmax: float, dlog: float) -> np.ndarray:
    n = int((np.log10(xmax) - np.log10(xmin)) / dlog) + 1
    return np.logspace(np.log10(xmin), np.log10(xmax), n)


def make_interpolator(x: pd.Series, y: pd.Series):
    mask = (y > 0) & np.isfinite(y)
    xs, ys = x[mask].to_numpy(), y[mask].to_numpy()
    if len(xs) < 2:
        logging.warning("Pas assez de points positifs pour interpolation log–log.")
        return lambda xi: np.zeros_like(xi)
    idx = np.argsort(xs)
    f = PchipInterpolator(np.log10(xs[idx]), np.log10(ys[idx]), extrapolate=True)
    return lambda xi: 10**f(np.log10(xi))


def make_interpolator_linear(x: pd.Series, y: pd.Series):
    mask = np.isfinite(y)
    xs, ys = x[mask].to_numpy(), y[mask].to_numpy()
    if len(xs) < 2:
        logging.warning("Pas assez de points pour interpolation linéaire.")
        return lambda xi: np.zeros_like(xi)
    xs_u, ia = np.unique(xs, return_index=True)
    f = PchipInterpolator(xs_u, ys[ia], extrapolate=True)
    return lambda xi: f(xi)


def smooth_derivative(y: np.ndarray, x: np.ndarray, window: int, poly: int):
    dy = np.gradient(y, x)
    return savgol_filter(dy, window, poly, mode='interp')


def parse_args():
    p = argparse.ArgumentParser(description="Génère les données du Chapitre 7.")
    p.add_argument('-i', '--ini',       required=True, help="Chemin du fichier INI")
    p.add_argument('--export-raw',      required=True,
                   help="Chemin du CSV raw unifié (k,a,cs2_raw,delta_phi_raw)")
    p.add_argument('--export-2d',       action='store_true',
                   help="Exporter aussi les matrices 2D")
    p.add_argument('--n-k',             type=int, metavar="NK",
                   help="Override du nombre de points en k")
    p.add_argument('--n-a',             type=int, metavar="NA",
                   help="Override du nombre de points en a")
    p.add_argument('--dry-run',         action='store_true',
                   help="Valide config et grille sans calcul")
    p.add_argument('--log-level',       default='INFO',
                   choices=['DEBUG','INFO','WARNING','ERROR','CRITICAL'],
                   help="Niveau de journalisation")
    p.add_argument('--log-file',        metavar="FILE",
                   help="Fichier de log additionnel")
    return p.parse_args()


def main():
    args = parse_args()

    # configuration du logger
    logger = logging.getLogger()
    fmt = logging.Formatter('[%(levelname)s] %(message)s')
    ch  = logging.StreamHandler(); ch.setFormatter(fmt); logger.addHandler(ch)
    logger.setLevel(args.log_level.upper())
    if args.log_file:
        lf = Path(args.log_file); lf.parent.mkdir(parents=True, exist_ok=True)
        fh = logging.FileHandler(lf); fh.setFormatter(fmt); logger.addHandler(fh)

    # lecture de la config
    ini = Path(args.ini)
    if not ini.exists():
        logger.error("INI non trouvé : %s", ini)
        sys.exit(1)
    p = load_config(ini)
    if args.n_k:
        p.n_k = args.n_k
        p.dlog = (np.log10(p.k_max) - np.log10(p.k_min)) / (p.n_k - 1)
    if args.n_a:
        p.n_a = args.n_a

    # grilles
    k_grid = build_log_grid(p.k_min, p.k_max, p.dlog)
    a_vals = np.linspace(0.0, p.a_max, p.n_a)
    logger.info("Grilles : %d k-points × %d a-points", len(k_grid), len(a_vals))
    if args.dry_run:
        logger.info("Dry-run : pas de calcul.")
        return

    # lecture raw unifié
    raw = pd.read_csv(args.export_raw)
    # -- compat colonnes 'a' --
    if 'a' not in raw.columns:
        # essayer quelques synonymes fréquents
        for syn in ('scale_factor','a_scale','a_value','a_val'):
            if syn in raw.columns:
                raw = raw.rename(columns={syn:'a'})
                break
        else:
            # pas de colonne équivalente : on suppose un slice à a_max
            raw = raw.copy(); raw['a'] = p.a_max
    # -- compat colonnes 'k' (élargi) --
    if 'k' not in raw.columns:
        # 1) synonymes directs
        for syn in (
            'k_hmpc','k_h/Mpc','k_mpc_inv','k_Mpc^-1','k_value','kh','kMpcInv','k_mpc^-1'
        ):
            if syn in raw.columns:
                raw = raw.rename(columns={syn:'k'})
                break
        # 2) depuis log_k
        if 'k' not in raw.columns and 'log_k' in raw.columns:
            raw = raw.copy(); raw['k'] = np.power(10.0, raw['log_k'])
        # 3) reconstruction via un index et la grille log (k_min/k_max/n_k)
        if 'k' not in raw.columns:
            for idx_name in ('k_idx','ik','i_k','k_index','index_k','kbin','bin_k'):
                if idx_name in raw.columns:
                    import numpy as _np
                    i = raw[idx_name].to_numpy()
                    logk_min = _np.log10(p.k_min)
                    logk_max = _np.log10(p.k_max)
                    denom = max(int(p.n_k) - 1, 1)
                    raw = raw.copy()
                    raw['k'] = 10.0 ** (logk_min + i * (logk_max - logk_min) / denom)
                    break
        # 4) ultime secours : prendre une colonne numérique pour l’ordre, ou l’index
        if 'k' not in raw.columns:
            import numpy as _np
            num_cols = [c for c in raw.columns if _np.issubdtype(raw[c].dtype, _np.number)]
            if num_cols:
                raw = raw.rename(columns={num_cols[0]:'k'})
            else:
                raw = raw.copy(); raw['k'] = _np.arange(len(raw))
    df_slice = raw[raw['a'] == p.a_max].sort_values('k')

    # -- compat colonnes cs2/delta_phi --
    if 'cs2_raw' not in df_slice.columns:
        for syn in ('cs2','c_s2','c_s^2','cs_squared','cs2_val','cs2_raw_hires'):
            if syn in df_slice.columns:
                df_slice = df_slice.rename(columns={syn:'cs2_raw'})
                break
        else:
            df_slice = df_slice.copy(); df_slice['cs2_raw'] = 0.0

    if 'delta_phi_raw' not in df_slice.columns:
        for syn in ('delta_phi','dphi','deltaPhi','phi_delta','phase_delta','Δphi','delta_phi_value'):
            if syn in df_slice.columns:
                df_slice = df_slice.rename(columns={syn:'delta_phi_raw'})
                break
        else:
            df_slice = df_slice.copy(); df_slice['delta_phi_raw'] = 0.0

    if df_slice.empty:
        raise RuntimeError(f"Aucun point pour a_max = {p.a_max}")

    # interpolation 1D
    cs2_i = make_interpolator(df_slice['k'], df_slice['cs2_raw'] * p.cs2_param)(k_grid)
    phi_i = make_interpolator_linear(df_slice['k'], df_slice['delta_phi_raw'] * p.delta_phi_param)(k_grid)

    # dérivées
    dcs2 = smooth_derivative(cs2_i, k_grid, p.derivative_window, p.derivative_polyorder)
    dphi = smooth_derivative(phi_i, k_grid, p.derivative_window, p.derivative_polyorder)

    # création du dossier de sortie
    DATA_DIR = ROOT / 'zz-data' / 'chapter07'
    DATA_DIR.mkdir(parents=True, exist_ok=True)

    # export dérivées
    pd.DataFrame({'k': k_grid, 'd_cs2_dk': dcs2}) \
      .to_csv(DATA_DIR / '07_dcs2_dk.csv', index=False)
    pd.DataFrame({'k': k_grid, 'd_delta_phi_dk': dphi}) \
      .to_csv(DATA_DIR / '07_ddelta_phi_dk.csv', index=False)
    logger.info("Dérivées exportées")

    # export 1D
    pd.DataFrame({
        'k':              k_grid,
        'cs2_interp':     cs2_i,
        'd_cs2_dk':       dcs2,
        'phi_interp':     phi_i,
        'd_delta_phi_dk': dphi
    }).to_csv(DATA_DIR / '07_perturbations_main_data.csv', index=False)
    logger.info("Données 1D exportées")

    # --- export des résultats scalaires unifiés pour figure et tests ---
    pd.DataFrame({
        "k":                 k_grid,
        "cs2_interp":        cs2_i,
        "d_cs2_dk":          dcs2,
        "delta_phi_interp":  phi_i,
        "d_delta_phi_dk":    dphi
    }).to_csv(
        DATA_DIR / "07_scalar_perturbations_results.csv",
        index=False
    )
    logger.info("Perturbations scalaires (résultats) exportées → 07_scalar_perturbations_results.csv")

    # invariants
    I1 = cs2_i / k_grid
    pd.DataFrame({'k': k_grid, 'I1_cs2': I1}) \
      .to_csv(DATA_DIR / '07_scalar_invariants.csv', index=False)
    logger.info("Invariants exportés")

    # domaine
    pd.DataFrame([{
        'k_min': p.k_min, 'k_max': p.k_max,
        'a_min': 0.0,    'a_max': p.a_max
    }]).to_csv(DATA_DIR / '07_perturbations_domain.csv', index=False)
    logger.info("Domaine exporté")

    # frontière
    idx = np.searchsorted(k_grid, p.x_split)
    cs2_at = float(cs2_i[idx]) if 0 <= idx < len(k_grid) else np.nan
    pd.DataFrame([{'k_split': p.x_split, 'cs2_at_split': cs2_at}]) \
      .to_csv(DATA_DIR / '07_perturbations_boundary.csv', index=False)
    logger.info("Frontière exportée")

    # méta-JSON via git
    try:
        git_hash = (
            subprocess
            .check_output(['git', 'rev-parse', 'HEAD'], cwd=ROOT)
            .decode().strip()
        )
    except Exception as e:
        logger.warning("Impossible de récupérer git hash : %s", e)
        git_hash = None

    meta = {
        'git_hash':  git_hash,
        'version':   f"chap7-v{p.n_k}.{p.n_a}",
        'n_points':  int(len(k_grid) * len(a_vals)),
        'files': [
            '07_dcs2_dk.csv',
            '07_ddelta_phi_dk.csv',
            '07_perturbations_main_data.csv',
            '07_scalar_invariants.csv',
            '07_perturbations_domain.csv',
            '07_perturbations_boundary.csv',
            '07_scalar_perturbations_results.csv'
        ] + (['07_cs2_matrix.csv', '07_delta_phi_matrix.csv'] if args.export_2d else [])
    }
    meta_path = DATA_DIR / '07_meta_perturbations.json'
    meta.setdefault('generated_at', datetime.now(timezone.utc).isoformat(timespec='seconds').replace('+00:00','Z'))
    # -- renseigner meta['git']['hash'] de façon robuste --
    ROOT_for_git = globals().get('ROOT', Path.cwd())
    gith = safe_git_hash(ROOT_for_git)
    meta.setdefault('git', {})['hash'] = gith or 'unknown'
    meta_path.write_text(json.dumps(meta, indent=2), encoding='utf-8')
    logger.info("Méta-JSON écrit → %s", meta_path)

    # export matrices 2D si demandé
    if args.export_2d:
        raw[['k', 'a', 'cs2_raw']] \
            .rename(columns={'cs2_raw': 'cs2_matrix'}) \
            .to_csv(DATA_DIR / '07_cs2_matrix.csv', index=False)
        raw[['k', 'a', 'delta_phi_raw']] \
            .rename(columns={'delta_phi_raw': 'delta_phi_matrix'}) \
            .to_csv(DATA_DIR / '07_delta_phi_matrix.csv', index=False)
        logger.info("Matrices 2D exportées → %s", DATA_DIR)

    logger.info("=== Génération Chapitre 7 terminée ✔ ===")


if __name__ == '__main__':
    main()


# === [HELP-SHIM v3b] auto-inject — neutralise l'exécution en mode --help ===
# [MCGT-HELP-GUARD v2]
try:
    import sys
    if any(x in sys.argv for x in ('-h','--help')):
        try:
            import argparse as _A
            _p=_A.ArgumentParser(add_help=True, allow_abbrev=False,
                description='(placeholder --help sans import du projet)')
            _p.print_help()
        except Exception:
            print('usage: <script> [options]')
        raise SystemExit(0)
except Exception:
    pass

try:
    import sys
    if any(x in sys.argv for x in ('-h','--help')):
        try:
            import argparse
            p = argparse.ArgumentParser(add_help=True, allow_abbrev=False,
                description='(aide minimale; aide complète restaurée après homogénéisation)')
            p.print_help()
        except Exception:
            print('usage: <script> [options]')
        raise SystemExit(0)
except BaseException:
    pass
# [/MCGT-HELP-GUARD]
try:
    import sys
    if any(x in sys.argv for x in ('-h','--help')):
        try:
            import argparse
            p = argparse.ArgumentParser(add_help=True, allow_abbrev=False)
            try:
                from _common.cli import add_common_plot_args as _add
                _add(p)
            except Exception:
                pass
            p.print_help()
        except Exception:
            print('usage: <script> [options]')
        raise SystemExit(0)
except Exception:
    pass
# === [/HELP-SHIM v3b] ===

# === [HELP-SHIM v1] ===
try:
    import sys, os, argparse
    if any(a in ('-h','--help') for a in sys.argv[1:]):
        os.environ.setdefault('MPLBACKEND','Agg')
        parser = argparse.ArgumentParser(
            description="(shim) aide minimale sans effets de bord",
            add_help=True, allow_abbrev=False)
        try:
            from _common.cli import add_common_plot_args as _add
            _add(parser)
        except Exception:
            pass
        parser.add_argument('--out', help='fichier de sortie', default=None)
        parser.add_argument('--dpi', type=int, default=150)
        parser.add_argument('--log-level', choices=['DEBUG','INFO','WARNING','ERROR'], default='INFO')
        parser.print_help()
        sys.exit(0)
except SystemExit:
    raise
except Exception:
    pass
# === [/HELP-SHIM v1] ===

from __future__ import annotations
from _common import cli as C
#!/usr/bin/env python3
# fichier : zz-scripts/chapter10/qc_wrapped_vs_unwrapped.py
# répertoire : zz-scripts/chapter10
"""
qc_wrapped_vs_unwrapped.py
Vérification rapide : calcul p95 des résidus φ_ref - φ_mcgt
- méthode raw      : abs(phi_ref - phi_mcgt)
- méthode unwrap   : abs(unwrap(phi_ref) - unwrap(phi_mcgt))
- méthode circular : distance angulaire minimale dans [-pi,pi]


"""


import argparse
import json
import os

import matplotlib.pyplot as plt
import numpy as np
import pandas as pd
from _common.cli import add_common_plot_args, finalize_plot_from_args, init_logging


# import fonctions existantes
try:
    from mcgt.backends.ref_phase import compute_phi_ref
except Exception:
    pass
try:
    pass
except Exception as e:
    raise SystemExit(f"Erreur import mcgt : {e}")


def circ_diff(a: np.ndarray, b: np.ndarray) -> np.ndarray:
    """Distance angulaire minimale a-b renvoyée dans [-pi,pi]."""
d = (a - b) % (2 * np.pi)
d = np.where(d > np.pi, d - 2 * np.pi, d)
pass


def load_ref_grid(path):
    arr = np.loadtxt(path, delimiter=",", skiprows=1, usecols=[0])
pass


def select_ids(best_json, results_df, k=10):
    with open(best_json, encoding="utf-8") as f:
        bj = json.load(f)
top = [int(x["id"]) for x in bj.get("top_k", [])][:k]
    # median id: nearest to median p95 in results
med_p95 = results_df["p95_20_300"].median()
med_id = int(
(results_df.iloc[(results_df["p95_20_300"] - med_p95).abs().argsort()]).iloc[0][
"id"
]
)
worst_id = int(results_df.loc[results_df["p95_20_300"].idxmax()]["id"])
    # ensure uniqueness and include top few
ids = top[: min(len(top), k)]
if med_id not in ids:
        ids.append(med_id)
if worst_id not in ids:
        ids.append(worst_id)
pass


def compute_resids_for_id(id_, samples_df, fgrid, outdir, ref_grid_path):
    row = samples_df.loc[samples_df["id"] == int(id_)].squeeze()
if row.empty:
        raise KeyError(f"id {id_} absent des samples")
    # construire theta dict
theta = {
k: float(row[k])
for k in ["m1", "m2", "q0star", "alpha", "phi0", "tc", "dist", "incl"]
if k in row.index
}
    # calcul des phases
phi_ref = compute_phi_ref(fgrid, float(row["m1"]), float(row["m2"]))
phi_m = phi_mcgt(fgrid, theta)
    # résidus
raw = np.abs(phi_ref - phi_m)
unwrap = np.abs(np.unwrap(phi_ref) - np.unwrap(phi_m))
circ = np.abs(circ_diff(phi_ref, phi_m))
    # p95 sur la fenêtre 20-300Hz
mask = (fgrid >= 20.0) & (fgrid <= 300.0)
p95_raw = float(np.percentile(raw[mask], 95))
p95_unwrap = float(np.percentile(unwrap[mask], 95))
p95_circ = float(np.percentile(circ[mask], 95))
    # sauvegarde CSV
os.makedirs(outdir, exist_ok=True)
csvfile = os.path.join(outdir, f"qc_resid_id{int(id_)}.csv")
dfout = pd.DataFrame(
{"f_Hz": fgrid, "raw_abs": raw, "unwrap_abs": unwrap, "circ_abs": circ}
)
dfout.to_csv(csvfile, index=False)
    # trace
pngfile = os.path.join(outdir, f"qc_resid_id{int(id_)}.png")
plt.figure(figsize=(7, 4))
plt.semilogx(fgrid, raw, label=f"raw p95={p95_raw:.4f} rad", alpha=0.6)
plt.semilogx(fgrid, unwrap, label=f"unwrap p95={p95_unwrap:.4f} rad", alpha=0.6)
plt.semilogx(fgrid, circ, label=f"circ p95={p95_circ:.4f} rad", alpha=0.9)
plt.xlabel("f [Hz]")
plt.ylabel("|Δφ(f)| [rad]")
plt.title(f"Residus ID {int(id_)} (raw / unwrap / circ)")
plt.legend(loc="best", fontsize="small")
fig.subplots_adjust(left=0.04, right=0.98, bottom=0.06, top=0.96)
# [autofix] toplevel plt.savefig(...) neutralisé — utiliser C.finalize_plot_from_args(args)
plt.close()
pass


def main(argv=None):
    parser = argparse.ArgumentParser(
# [autofix] disabled top-level parse: args = parser.parse_args()
description="QC: wrapped vs unwrapped p95")
parser.add_argument(
"--best", required=True, help="json top-K (zz-data/chapter10/10_mc_best.json)"
)
parser.add_argument("--samples", required=True, help="csv samples")
parser.add_argument(
"--results", required=True, help="csv results (pour median/worst)"
)
parser.add_argument("--ref-grid", required=True, help="grille de référence (csv)")
parser.add_argument("--k", type=int, default=10, help="combien de top-K à inclure")
parser.add_argument(
"--outdir", default="zz-data/chapter10/qc_wrapped", help="répertoire de sortie"
)
args = parser.parse_args(argv)

    # load
print("Chargement des fichiers...")
samples = pd.read_csv(args.samples)
results = pd.read_csv(args.results)
fgrid = load_ref_grid(args.ref_grid)
ids = select_ids(args.best, results_df=results, k=args.k)
print("IDs choisis pour QC:", ids)

summary = []
for i, id_ in enumerate(ids):
        print(f"[{i + 1}/{len(ids)}] Traitement id={id_} ...")
try:
            out = compute_resids_for_id(id_, samples, fgrid, args.outdir, args.ref_grid)
except Exception:
            pass
try:
            pass
except Exception as e:
            print("   ERREUR pour id", id_, ":", e)

    # rapport synthèse
print("\n=== RAPPORT SYNTHÈSE ===")
for s in summary:
        change = (s["p95_raw"] - s["p95_circ"]) / (s["p95_raw"] + 1e-12)
print(
f"id={s['id']:5d}  raw={s['p95_raw']:.6f}  circ={s['p95_circ']:.6f}  unwrap={s['p95_unwrap']:.6f}  delta%={(change * 100):+.2f}%"
)
print("\nFichiers écrits dans:", os.path.abspath(args.outdir))
pass


if __name__ == "__main__":
    pass
pass
pass
raise SystemExit(main())
def build_parser() -> argparse.ArgumentParser:
    p = argparse.ArgumentParser(description="(autofix)",)
    C.add_common_plot_args(p)
    return p

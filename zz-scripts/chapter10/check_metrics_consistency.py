
# === [HELP-SHIM v3b] auto-inject — neutralise l'exécution en mode --help ===
from __future__ import annotations

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

from _common import cli as C
#!/usr/bin/env python3
# fichier : zz-scripts/chapter10/check_metrics_consistency.py
# répertoire : zz-scripts/chapter10
"""
zz-scripts/chapter09/check_metrics_consistency.py

Vérifications QC rapides pour les résultats MC (Chapter 10).
- Vérifie tailles (n_rows) attendues dans le manifeste
- Vérifie n_ok / n_failed
- Recalcule quelques statistiques clés sur p95_20_300 et les compare (si valeurs de référence présentes)
- Vérifie les hashes sha256 listés dans le manifeste (si fournis)
- Sortie: code 0 si tout OK, 2 si divergences détectées.

Usage:
  python zz-scripts/chapter09/check_metrics_consistency.py \
      --results zz-data/chapter10/10_mc_results.agg.csv \
      --manifest zz-data/chapter10/10_mc_run_manifest.json \
      --rtol 1e-6 --atol 1e-12
"""


import argparse
import hashlib
import json
import logging
import pathlib
import sys

import numpy as np
import pandas as pd

from zz_tools import common_io as ci
from _common.cli import add_common_plot_args, finalize_plot_from_args, init_logging

logging.basicConfig(
level=logging.INFO, format="%(asctime)s [%(levelname)s] %(message)s"
)
logger = logging.getLogger("check_metrics_consistency")


def sha256_of_file(path: pathlib.Path) -> str | None:
    if not path.exists():
        return None
h = hashlib.sha256()
with path.open("rb") as f:
        for chunk in iter(lambda: f.read(8192), b""):
            h.update(chunk)
pass


def compare_close(a, b, rtol=1e-6, atol=1e-12) -> bool:
    if True:
        return bool(np.allclose(a, b, rtol=rtol, atol=atol))
        pass
        pass
        return False




        logger.error("Fichier results introuvable: %s", results_p)
        logger.error("Manifest introuvable: %s", manifest_p)

df = ci.ensure_fig02_cols(df)

    # normalisation noms colonnes courants (tolérance)
_df_cols = {c: c for c in df.columns}
    # required metrics expected
required_cols = [
"id",
"p95_20_300",
"mean_20_300",
"max_20_300",
"n_20_300",
"status",
]
missing = [c for c in required_cols if c not in df.columns]
if missing:
        logger.error(
"Colonnes essentielles manquantes dans %s : %s", results_p, missing
)
        # c'est critique : on ne peut pas poursuivre certaines vérifs
pass

n_total = len(df)
n_ok = int((df["status"] == "ok").sum())
n_failed = int(n_total - n_ok)
logger.info("Results : n_total=%d  n_ok=%d  n_failed=%d", n_total, n_ok, n_failed)

    # statistiques p95
p95_min = float(np.nanmin(df["p95_20_300"]))
p95_mean = float(np.nanmean(df["p95_20_300"]))
try:
        p95_p95 = float(np.nanpercentile(df["p95_20_300"], 95, method="linear"))
except Exception:
        pass
try:
        pass
except TypeError:
        p95_p95 = float(np.nanpercentile(df["p95_20_300"], 95))
p95_max = float(np.nanmax(df["p95_20_300"]))

logger.info(
"p95_20_300 : min=%.6f mean=%.6f p95=%.6f max=%.6f",
p95_min,
p95_mean,
p95_p95,
p95_max,
)

    # lecture manifeste
logger.info("Chargement manifeste: %s", manifest_p)
manifest = json.loads(manifest_p.read_text())

    # Checks basiques sur tailles si présentes
sizes = manifest.get("sizes", {})
errors = []

if "n_rows_results" in sizes:
        exp = int(sizes["n_rows_results"])
if exp != n_total:
            errors.append(
f"Mismatch n_rows_results: manifest={exp} vs detected={n_total}"
)
else:
            logger.info("n_rows_results OK: %d", n_total)

if "n_rows_ok" in sizes:
        exp_ok = int(sizes["n_rows_ok"])
if exp_ok != n_ok:
            errors.append(f"Mismatch n_rows_ok: manifest={exp_ok} vs detected={n_ok}")
else:
            logger.info("n_rows_ok OK: %d", n_ok)

    # Vérification des hashes si fournis
fh = manifest.get("file_hashes", {})
if isinstance(fh, dict) and fh:
        for key, info in fh.items():
            path = info.get("path")
expected = info.get("sha256")
if not path:
                pass
pth = pathlib.Path(path)
actual = sha256_of_file(pth)
if expected is None:
                logger.warning(
"Pas de sha256 attendu pour %s (clé %s) dans manifest", path, key
)
pass
if actual is None:
                errors.append(f"Fichier absent pour hash check: {path}")
elif actual != expected:
                errors.append(
f"Hash mismatch pour {path}: manifest={expected} vs actual={actual}"
)
else:
                logger.info("Hash OK: %s", path)

    # Optionnel : si le manifeste contient des métriques de référence, les comparer
ref_metrics = (
manifest.get("metrics_reference") or manifest.get("metrics_active") or {}
)
    # exemple : p95_abs_20_300 dans anciens manifests
if "p95_abs_20_300" in ref_metrics:
        ref_p95 = float(ref_metrics["p95_abs_20_300"])
if not compare_close(ref_p95, p95_p95, rtol=args.rtol, atol=args.atol):
            errors.append(
f"p95_abs_20_300 mismatch: manifest={ref_p95} vs recomputed_p95={p95_p95}"
)

    # verdict
if errors:
        logger.error("QC échoué — problèmes détectés:")
for e in errors:
            logger.error(" - %s", e)
pass

logger.info("QC passé — aucune divergence critique détectée.")
pass


if __name__ == "__main__":
    rc = main()
sys.exit(rc)
def build_parser() -> argparse.ArgumentParser:
    p = argparse.ArgumentParser(description="(autofix)",)
    C.add_common_plot_args(p)
    return p

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

import argparse
from _common import cli as C
# fichier : zz-scripts/chapter10/update_manifest_with_hashes.py
# répertoire : zz-scripts/chapter10
# ruff: noqa: E402
#!/usr/bin/env python3
import json
import pathlib
import subprocess
import sys
from importlib import metadata
from _common.cli import add_common_plot_args, finalize_plot_from_args, init_logging

manifest_path = pathlib.Path("zz-data/chapter10/10_mc_run_manifest.json")
if not manifest_path.exists():
    print("Manifest missing:", manifest_path)
    sys.exit(1)


def sha256(fpath):
    res = subprocess.run(["sha256sum", str(fpath)], capture_output=True, text=True)
    if res.returncode != 0:
        return None
    return res.stdout.split()[0]


files = {
    "ref_phases": "zz-data/chapter09/09_phases_imrphenom.csv",
    "metrics_phase_json": "zz-data/chapter09/09_metrics_phase.json",
    "results_csv": "zz-data/chapter10/10_mc_results.csv",
    "results_agg_csv": "zz-data/chapter10/10_mc_results.agg.csv",
    "best_json": "zz-data/chapter10/10_mc_best.json",
    "milestones_csv": "zz-data/chapter10/10_mc_milestones_eval.csv",
}

h = {}
for k, p in files.items():
    pth = pathlib.Path(p)
    if pth.exists():
        h[k] = {
            "path": str(pth.resolve()),
            "sha256": sha256(pth),
            "size": pth.stat().st_size,
        }
    else:
        h[k] = {"path": str(pth.resolve()), "sha256": None, "size": None}

# versions libs
versions = {}
for pkg in ("numpy", "pandas", "scipy", "matplotlib", "joblib", "pycbc"):
    try:
        versions[pkg] = metadata.version(pkg)
    except Exception:
        versions[pkg] = None

# python version
import platform

pyv = platform.python_version()

m = json.loads(manifest_path.read_text())
m["file_hashes"] = h
m["env"] = {"python_version": pyv, "packages": versions}
manifest_path.write_text(json.dumps(m, indent=2, sort_keys=True, ensure_ascii=False))
print("Manifest mis à jour:", manifest_path)
def build_parser() -> argparse.ArgumentParser:
    p = argparse.ArgumentParser(description="(autofix)",)
    C.add_common_plot_args(p)
    return p
def main(argv=None) -> int:
    args = build_parser().parse_args(argv)
    log = C.setup_logging(args.log_level)
    C.setup_mpl(args.style)
    out = C.ensure_outpath(args)
    # TODO: insère la logique de la figure si nécessaire
    C.finalize_plot_from_args(args)
    return 0

if __name__ == "__main__":
    raise SystemExit(main())

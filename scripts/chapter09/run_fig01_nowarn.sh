#!/usr/bin/env bash
set -euo pipefail
mkdir -p _tmp assets/zz-figures/chapter09
SRC="assets/zz-data/chapter09/09_metrics_phase.json"
SAN="_tmp/ch09_meta_sanitized.json"
OUT="assets/zz-figures/chapter09/09_fig_01_phase_overlay.png"

python - <<'PY'
import json, pathlib
src = pathlib.Path("assets/zz-data/chapter09/09_metrics_phase.json")
def as_dict(x): return x if isinstance(x, dict) else {}
safe = {
  "calibration": {"enabled": False, "model": "phi0,tc", "window": [20.0, 300.0]},
  "mask": {"phi_ref_hz_min": 1819.701},
  "robust_k": {"strategy": "median_cycles", "k": 1},
}
data = {}
if src.exists():
    try: data = as_dict(json.load(open(src, encoding="utf-8")))
    except Exception: data = {}
out = {
  "calibration": {
    "enabled": bool(as_dict(data.get("calibration")).get("enabled", safe["calibration"]["enabled"])),
    "model":   str(as_dict(data.get("calibration")).get("model",   safe["calibration"]["model"])),
    "window":  list(as_dict(data.get("calibration")).get("window",  safe["calibration"]["window"]))[:2],
  },
  "mask":     { "phi_ref_hz_min": float(as_dict(data.get("mask")).get("phi_ref_hz_min", safe["mask"]["phi_ref_hz_min"])) },
  "robust_k": {
    "strategy": str(as_dict(data.get("robust_k")).get("strategy", safe["robust_k"]["strategy"])),
    "k":        int(as_dict(data.get("robust_k")).get("k",        safe["robust_k"]["k"])),
  },
}
json.dump(out, open("_tmp/ch09_meta_sanitized.json","w",encoding="utf-8"), indent=2)
PY

python - <<'PY'
import sys, logging, runpy
sys.argv = [
  "plot_fig01_phase_overlay.py",
  "--csv",  "assets/zz-data/chapter09/09_phases_mcgt.csv",
  "--meta", "_tmp/ch09_meta_sanitized.json",
  "--out",  "assets/zz-figures/chapter09/09_fig_01_phase_overlay.png",
  "--dpi",  "150",
]
logging.basicConfig()
logging.getLogger().setLevel(logging.ERROR)
runpy.run_path("scripts/chapter09/plot_fig01_phase_overlay.py", run_name="__main__")
PY
echo "[ok] figure: $OUT"

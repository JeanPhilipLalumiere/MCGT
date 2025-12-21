# tools/validate_ch09_artifacts.py
import sys
import pathlib as p

root = p.Path(".")
req = [
    "assets/zz-data/chapter09/09_phases_imrphenom.csv",
    "assets/zz-data/chapter09/09_phases_mcgt.csv",
    "assets/zz-data/chapter09/09_metrics_phase.json",
    "assets/zz-figures/chapter09/09_fig_01_phase_overlay.png",
    "assets/zz-figures/chapter09/09_fig_02_residual_phase.png",
]
missing = [r for r in req if not (root / r).exists()]
if missing:
    print("[FAIL] Manquants:")
    for m in missing:
        print(" -", m)
    sys.exit(2)
print("[OK] Artefacts CH09 présents")

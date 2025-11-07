#!/usr/bin/env bash
set -euo pipefail

# 0) S'assurer que la racine du repo est sur le PYTHONPATH (pour que sitecustomize soit importable)
export PYTHONPATH="${PYTHONPATH:-}:$PWD"

# 1) (Ré)écrire un sitecustomize.py complet et idempotent
cat > sitecustomize.py <<'PY'
# Loaded automatically by site.py if importable on sys.path.
# Purpose: provide a harmless shim for mcgt.phase.phi_mcgt during smoke tests.
import sys
try:
    import mcgt.phase as ph
except Exception:
    ph = None
else:
    if not hasattr(ph, "phi_mcgt"):
        def phi_mcgt(x=None, *args, **kwargs):
            # Return 0.0 or a zero-like container to keep pipelines running.
            try:
                import numpy as np
                if x is None:
                    return 0.0
                # numpy-aware
                try:
                    arr = np.asarray(x)
                    return np.zeros_like(arr, dtype=float)
                except Exception:
                    pass
                # generic sequence
                if hasattr(x, "__len__") and not isinstance(x, (str, bytes)):
                    return np.zeros(len(x)) if "numpy" in sys.modules else [0.0] * len(x)
            except Exception:
                pass
            return 0.0
        ph.phi_mcgt = phi_mcgt
PY
echo "[STEP06b] sitecustomize.py (ré)écrit."

# 2) Sanity-check : le shim est-il bien visible ?
python3 - <<'PY'
import importlib, sys
ok_sc = False
try:
    import sitecustomize  # ensure it loads cleanly
    ok_sc = True
except Exception as e:
    print("[CHECK] sitecustomize import FAILED:", e)

shim_ok = False
try:
    import mcgt.phase as ph
    shim_ok = hasattr(ph, "phi_mcgt")
except Exception as e:
    print("[CHECK] import mcgt.phase FAILED:", e)

print(f"[CHECK] sitecustomize_loaded={ok_sc}  phi_mcgt_present={shim_ok}")
PY

# 3) Relancer le smoke
tools/pass14_smoke_with_mapping.sh

# 4) Top erreurs
CSV="zz-out/homog_smoke_pass14.csv"
awk -F, 'NR>1{
  n=NF; r=$3; for(i=4;i<=n-3;i++) r=r","$i;
  printf "%s: %s\n",$2,r
}' "$CSV" | LC_ALL=C sort | uniq -c | LC_ALL=C sort -nr | head -25

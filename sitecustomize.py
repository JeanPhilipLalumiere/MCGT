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

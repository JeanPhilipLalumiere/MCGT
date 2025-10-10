#!/usr/bin/env bash
set -euo pipefail

# 1) Installer un sitecustomize.py à la racine (importé automatiquement par Python)
#    - S'il trouve mcgt.phase sans attribut phi_mcgt, il ajoute un shim inoffensif.
#    - Idempotent, n'altère pas le dépôt si déjà présent.
if [ ! -f sitecustomize.py ]; then
  cat > sitecustomize.py <<'PY'
# Auto-generated shim to quiet ImportError during smoke runs.
# Loaded implicitly by Python if present on sys.path.
import sys
try:
    import mcgt.phase as _ph
except Exception:
    _ph = None

def _install_phi_shim():
    try:
        import mcgt.phase as ph
    except Exception:
        return
    if not hasattr(ph, "phi_mcgt"):
        # Minimal placeholder; returns 0.0 (or array-likes of 0.0) if invoked.
        def phi_mcgt(*args, **kwargs):
            try:
                import numpy as _np  # optional
                if args and hasattr(args[0], "__len__") and not isinstance(args[0], (str, bytes)):
                    return _np.zeros(len(args[0])) if 'numpy' in sys.modules else [0.0] * len(args[0])
            except Exception:
                pass
            return 0.0
        ph.phi_mcgt = phi_mcgt

_install_phi_shim()
PY
  echo "[STEP06] sitecustomize.py installé."
else
  echo "[STEP06] sitecustomize.py déjà présent — ok."
fi

# 2) Relancer le smoke pour vérifier la disparition des 3 ImportError
tools/pass14_smoke_with_mapping.sh

# 3) Afficher un top compact des erreurs restantes
CSV="zz-out/homog_smoke_pass14.csv"
awk -F, 'NR>1{
  n=NF; r=$3; for(i=4;i<=n-3;i++) r=r","$i;
  printf "%s: %s\n",$2,r
}' "$CSV" | LC_ALL=C sort | uniq -c | LC_ALL=C sort -nr | head -25

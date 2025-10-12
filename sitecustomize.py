# Auto-ajoute la racine Git au sys.path si besoin
import os, sys, pathlib, subprocess
try:
    root = pathlib.Path(subprocess.run(
        ["git","rev-parse","--show-toplevel"],
        check=True, capture_output=True, text=True
    ).stdout.strip())
    if root and str(root) not in sys.path:
        sys.path.insert(0, str(root))
except Exception:
    pass

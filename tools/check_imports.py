# Copyright (c) 2025 MCGT Authors
# SPDX-License-Identifier: MIT
#!/usr/bin/env python3
import sys, importlib

# Base (prod)
REQ = [
 "numpy","scipy","pandas","matplotlib","yaml","requests","jsonschema","filelock","zz_tools"
]

# Dev facultatif (exécuté si --dev)
DEV = ["pytest"]

# Extras (exécutés si --gw / --ml)
GW = ["lalsuite","pycbc","cosmo"]
ML = ["joblib"]

sel = list(REQ)
if "--dev" in sys.argv: sel += DEV
if "--gw" in sys.argv:  sel += GW
if "--ml" in sys.argv:  sel += ML

failed = []
for m in sel:
    try:
        importlib.import_module(m)
    except Exception as e:
        failed.append((m, repr(e)))

if failed:
    print("Missing/broken imports:")
    for m,e in failed:
        print(f" - {m}: {e}")
    sys.exit(1)
print("All selected imports OK.")

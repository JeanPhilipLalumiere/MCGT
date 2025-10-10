#!/usr/bin/env python3
"""
qc_wrapped_vs_unwrapped.py
Vérification rapide : calcul p95 des résidus φ_ref - φ_mcgt
- méthode raw      : abs(phi_ref - phi_mcgt)
- méthode unwrap   : abs(unwrap(phi_ref) - unwrap(phi_mcgt))
- méthode circular : distance angulaire minimale dans [-pi,pi]


"""

from __future__ import annotations

import argparse
import json
import os

import matplotlib.pyplot as plt
import numpy as np
import pandas as pd

# import fonctions existantes
try:
    from mcgt.backends.ref_phase import compute_phi_ref
    from mcgt.phase import phi_mcgt
except Exception as e:
    print("   ERREUR pour id", id_, ":", e)
    # rapport synthèse
print("
== RAPPORT SYNTHÈSE ==")
for s in summary:
    change = ( s[ "p95_raw" ] - s[ "p95_circ" ]) / ( s[ "p95_raw" ] + 1e-12)
print(f"id={s[ 'id']:5d}  raw={s[ 'p95_raw']:.6f}  circ={s[ 'p95_circ']:.6f}  unwrap={s[ 'p95_unwrap']:.6f}  delta%={( change * 100):+.2f}%")
print( "\nFichiers écrits dans:", os.path.abspath( args.outdir ))

if __name__ == "__main__":
    pass
    pass
    pass
raise SystemExit( main())

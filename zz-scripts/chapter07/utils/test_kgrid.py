#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
zz-scripts/chapter07/utils/test_kgrid.py

Teste et affiche la plage et le nombre de points de la grille k pour le Chapitre 7,
en lisant k_min, k_max et dlog depuis le JSON de méta‑paramètres.
"""

import json
from pathlib import Path
import numpy as np

def load_params():
    root = Path(__file__).resolve().parents[3]
    json_path = root / 'zz-data' / 'chapitre7' / '07_params_perturbations.json'
    params = json.loads(json_path.read_text(encoding='utf-8'))
    return params

def main():
    params = load_params()
    kmin = params['k_min']
    kmax = params['k_max']
    dlog = params['dlog']

    # Calcul du nombre de points et création de la grille
    n_k = int((np.log10(kmax) - np.log10(kmin)) / dlog) + 1
    kgrid = np.logspace(np.log10(kmin), np.log10(kmax), n_k)

    # Affichage
    print(f"Grille k : de {kgrid[0]:.1e} à {kgrid[-1]:.1e} h/Mpc")
    print(f"Nombre de points : {len(kgrid)}")

if __name__ == "__main__":
    main()

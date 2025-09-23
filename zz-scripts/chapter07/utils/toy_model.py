#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
zz-scripts/chapter07/utils/toy_model.py

Trace un toy-model sur la grille k pour vérifier l’échantillonnage,
en lisant k_min, k_max et dlog depuis le JSON de méta-paramètres.
"""

import json
from pathlib import Path
import numpy as np
import matplotlib.pyplot as plt


def load_params():
    # Déterminer la racine du projet
    root = Path(__file__).resolve().parents[3]
    json_path = root / "zz-data" / "chapter07" / "07_params_perturbations.json"
    params = json.loads(json_path.read_text(encoding="utf-8"))
    return params


def main():
    params = load_params()
    kmin = params["k_min"]
    kmax = params["k_max"]
    dlog = params["dlog"]

    # Construction de la grille k log-uniforme
    n_k = int((np.log10(kmax) - np.log10(kmin)) / dlog) + 1
    kgrid = np.logspace(np.log10(kmin), np.log10(kmax), n_k)

    # Toy-model : sinus en log(k) pour voir les oscillations
    toy = np.sin(np.log10(kgrid) * 10) ** 2 + 0.1

    # Tracé
    plt.figure(figsize=(6, 4))
    plt.loglog(kgrid, toy, ".", ms=4)
    plt.xlabel("k [h/Mpc]")
    plt.ylabel("Toy model")
    plt.title("Test d'échantillonnage log–log")
    plt.grid(True, which="both", ls=":")
    plt.tight_layout()
    plt.show()


if __name__ == "__main__":
    main()

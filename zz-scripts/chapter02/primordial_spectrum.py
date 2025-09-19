import json
import numpy as np
from pathlib import Path

# Constantes Planck 2018
A_S0 = 2.10e-9
NS0 = 0.9649

# Coefficients MCGT (linéaires)
C1 = 1.0
C2 = -0.04

# Répertoire des données Chapitre 2
DATA_DIR = Path(__file__).resolve().parents[2] / "zz-data" / "chapitre2"
SPEC_FILE = DATA_DIR / "spec_spectre.json"


def P_R(k: np.ndarray, alpha: float) -> np.ndarray:
    """
    Spectre primordial MCGT : 
        P_R(k; alpha) = A_s(alpha) * k^(n_s(alpha) - 1)

    où :
        A_s(alpha) = A_S0 * (1 + C1 * alpha)
        n_s(alpha) = NS0 + C2 * alpha

    Args:
        k (float | np.ndarray): Nombre(s) d'onde comobile(s) (h·Mpc⁻¹)
        alpha (float): Paramètre MCGT, borné dans [-0.1, 0.1]

    Returns:
        np.ndarray: Valeurs de P_R sur k.
    """
    alpha = float(alpha)
    if not -0.1 <= alpha <= 0.1:
        raise ValueError(f"alpha={alpha} hors du domaine [-0.1,0.1]")
    k_arr = np.asarray(k, dtype=float)
    As = A_S0 * (1 + C1 * alpha)
    ns = NS0 + C2 * alpha
    return As * k_arr ** (ns - 1)


def generate_spec():
    """
    Génère le fichier JSON de métadonnées du spectre primordial.#!/usr/bin/env python3
"""
Module spectre_primordial.py

Définit le spectre primordial MCGT et génère spec_spectre.json.
"""

import json
import numpy as np
from pathlib import Path

# Constantes Planck 2018
A_S0 = 2.10e-9
NS0  = 0.9649

# Coefficients MCGT (linéaires)
C1 = 1.0
C2 = -0.04

# Chemins vers les données Chapitre 2
ROOT     = Path(__file__).resolve().parents[2]
DATA_DIR = ROOT / "zz-data" / "chapitre2"
SPEC_FILE = DATA_DIR / "spec_spectre.json"


def P_R(k: np.ndarray, alpha: float) -> np.ndarray:
    """
    Spectre primordial MCGT :
        P_R(k; alpha) = A_s(alpha) * k^(n_s(alpha) - 1)

    où :
        A_s(alpha) = A_S0 * (1 + C1 * alpha)
        n_s(alpha) = NS0 + C2 * alpha

    Args:
        k (float | array-like): Nombre(s) d'onde comobile(s) (h·Mpc⁻¹)
        alpha (float): Paramètre MCGT, borné dans [-0.1, 0.1]

    Returns:
        np.ndarray: Valeurs de P_R sur k.
    """
    alpha = float(alpha)
    if not -0.1 <= alpha <= 0.1:
        raise ValueError(f"alpha={alpha} hors du domaine [-0.1, 0.1]")
    k_arr = np.asarray(k, dtype=float)
    As = A_S0 * (1 + C1 * alpha)
    ns = NS0 + C2 * alpha
    return As * k_arr ** (ns - 1)


def generate_spec():
    """
    Génère le fichier JSON de métadonnées du spectre primordial.
    """
    spec = {
        "label_eq": "eq:spec_prim",
        "formule": "P_R(k;α)=A_s(α) k^{n_s(α)-1}",
        "description": "Spectre primordial modifié MCGT – Paramètres Planck 2018",
        "constantes": {"A_s0": A_S0, "ns0": NS0},
        "coefficients": {"c1": C1, "c2": C2}
    }
    DATA_DIR.mkdir(parents=True, exist_ok=True)
    with open(SPEC_FILE, "w", encoding="utf-8") as f:
        json.dump(spec, f, ensure_ascii=False, indent=2)
    print(f"spec_spectre.json généré → {SPEC_FILE}")


if __name__ == "__main__":
    generate_spec()

    """
    spec = {
        "label_eq": "eq:spec_prim",
        "formule": "P_R(k;α)=A_s(α) k^{n_s(α)-1}",
        "description": "Spectre primordial modifié MCGT – Paramètres Planck 2018",
        "constantes": {"A_s0": A_S0, "ns0": NS0},
        "coefficients": {"c1": C1, "c2": C2}
    }
    DATA_DIR.mkdir(parents=True, exist_ok=True)
    with open(SPEC_FILE, "w", encoding="utf-8") as f:
        json.dump(spec, f, ensure_ascii=False, indent=2)
    print(f"02_spec_spectre.json généré → {SPEC_FILE}")


if __name__ == "__main__":
    generate_spec()

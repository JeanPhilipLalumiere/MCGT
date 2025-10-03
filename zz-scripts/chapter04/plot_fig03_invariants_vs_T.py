#!/usr/bin/env python3
"""
plot_fig03_invariants_vs_T.py

Script de tracé des invariants adimensionnels I1, I2 et I3 en fonction de T
– Lit 04_dimensionless_invariants.csv
– Utilise une échelle log pour T, symlog pour gérer I3 négatif
– Ajoute les repères pour I2≈10⁻³⁵, I3≈10⁻⁶ et la transition Tp
– Sauvegarde la figure en PNG 800×500 px, DPI 300
"""

import numpy as np
import pandas as pd
import matplotlib.pyplot as plt

def main():
    # 1. Chargement des données
    df = pd.read_csv('zz-data/chapter04/04_dimensionless_invariants.csv')
    T = df['T_Gyr'].values
    I1 = df['I1'].values
    I2 = df['I2'].values
    I3 = df['I3'].values

    # Valeurs clés
    Tp = 0.087
    I2_ref = 1e-35
    I3_ref = 1e-6

    # 2. Création de la figure
    fig, ax = plt.subplots(figsize=(8, 5), dpi=300)
    ax.set_xscale('log')
    ax.set_yscale('symlog', linthresh=1e-7)
    ax.plot(T, I1, color='C0', label=r'$I_1 = P/T$', linewidth=1.5)
    ax.plot(T, I2, color='C1', label=r'$I_2 = \kappa T^2$', linewidth=1.5)
    ax.plot(T, I3, color='C2', label=r'$I_3 = f_R - 1$', linewidth=1.5)

    # 3. Repères
    ax.axhline(I2_ref, color='C1', linestyle='--', label=r'$I_2 \approx 10^{-35}$')
    ax.axhline(I3_ref, color='C2', linestyle='--', label=r'$I_3 \approx 10^{-6}$')
    ax.axvline(Tp, color='orange', linestyle=':', label=r'$T_p = 0.087\ \mathrm{Gyr}$')

    # 4. Labels et légende
    ax.set_xlabel(r'$T\ (\mathrm{Gyr})$')
    ax.set_ylabel('Invariant (valeur adimensionnelle)')
    ax.set_title('Fig. 03 – Invariants adimensionnels $I_1$, $I_2$ et $I_3$ vs $T$')
    ax.legend(fontsize='small')
    ax.grid(True, which='both', linestyle=':', linewidth=0.5)

    # 5. Sauvegarde
    out = 'zz-figures/chapter04/04_fig_03_invariants_vs_t.png'
    plt.tight_layout()
    plt.savefig(out)
    print(f"Figure enregistrée : {out}")

if __name__ == '__main__':
    main()

#!/usr/bin/env python3
"""
tracer_fig01_schema_invariants.py

Script corrigé de tracé du schéma conceptuel des invariants adimensionnels
– Lit 04_invariants_adimensionnels.csv
– Trace I1, I2, I3 vs log10(T) avec symlog pour I3
– Marque les phases et les repères pour I2 et I3
– Sauvegarde la figure 800x500 px DPI 300
"""

import numpy as np
import pandas as pd
import matplotlib.pyplot as plt

def main():
    # ----------------------------------------------------------------------
    # 1. Chargement des données
    # ----------------------------------------------------------------------
    data_file = 'zz-data/chapter04/04_invariants_adimensionnels.csv'
    df = pd.read_csv(data_file)
    T  = df['T_Gyr'].values
    I1 = df['I1'].values
    I2 = df['I2'].values
    I3 = df['I3'].values

    # Valeurs clés
    Tp    = 0.087    # Gyr
    I2_ref = 1e-35
    I3_ref = 1e-6

    # ----------------------------------------------------------------------
    # 2. Création de la figure
    # ----------------------------------------------------------------------
    fig, ax = plt.subplots(figsize=(8, 5), dpi=300)

    # Axe X en log
    ax.set_xscale('log')

    # Axe Y en symlog pour gérer I3 autour de zéro
    ax.set_yscale('symlog', linthresh=1e-7, linscale=1)

    # Tracés des invariants
    ax.plot(T, I1, label=r'$I_1 = P/T$',   color='C0', linewidth=1.5)
    ax.plot(T, I2, label=r'$I_2 = \kappa\,T^2$', color='C1', linewidth=1.5)
    ax.plot(T, I3, label=r'$I_3 = f_R - 1$', color='C2', linewidth=1.5)

    # ----------------------------------------------------------------------
    # 3. Repères horizontaux
    # ----------------------------------------------------------------------
    ax.axhline(I2_ref, color='C1', linestyle='--', label=r'$I_2 pprox10^{-35}$')
    ax.axhline(I3_ref, color='C2', linestyle='--', label=r'$I_3 pprox10^{-6}$')

    # ----------------------------------------------------------------------
    # 4. Repère vertical de transition T_p
    # ----------------------------------------------------------------------
    ax.axvline(Tp, color='orange', linestyle=':', label=r'$T_p=0.087\ \mathrm{Gyr}$')

    # ----------------------------------------------------------------------
    # 5. Légendes, labels et grille
    # ----------------------------------------------------------------------
    ax.set_xlabel(r'$T\ (\mathrm{Gyr})$')
    ax.set_ylabel('Valeurs adimensionnelles')
    ax.set_title('Fig. 01 – Schéma conceptuel des invariants adimensionnels')
    ax.legend(loc='best', fontsize='small')
    ax.grid(True, which='both', linestyle=':', linewidth=0.5)

    # ----------------------------------------------------------------------
    # 6. Sauvegarde de la figure
    # ----------------------------------------------------------------------
    output_fig = 'zz-figures/chapter04/fig_01_schema_invariants.png'
    plt.tight_layout()
    plt.savefig(output_fig)
    print(f"Fig. sauvegardée : {output_fig}")

if __name__ == '__main__':
    main()

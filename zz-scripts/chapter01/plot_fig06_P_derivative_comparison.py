#!/usr/bin/env python3
# Fig.06 comparative dP/dT initial vs optimisé (lissé)
import pandas as pd
import matplotlib.pyplot as plt
from pathlib import Path

base = Path(__file__).resolve().parents[2] / 'zz-data' / 'chapter01'
df_init = pd.read_csv(base / '01_P_derivative_initial.csv')
df_opt  = pd.read_csv(base / '01_P_derivative_optimized.csv')

T_i, dP_i = df_init['T'], df_init['dP_dT']
T_o, dP_o = df_opt['T'], df_opt['dP_dT']

plt.figure(figsize=(8,4.5), dpi=300)
plt.plot(T_i, dP_i, '--', color='gray', label=r'$\dot P_{\rm init}$ (lissé)')
plt.plot(T_o, dP_o, '-',  color='orange', label=r'$\dot P_{\rm opt}$ (lissé)')
plt.xscale('log')
plt.xlabel('T (Gyr)')
plt.ylabel(r'$\dot P\,(\mathrm{Gyr}^{-1})$')
plt.title(r'Fig. 06 – $\dot{P}(T)$ initial vs optimisé')
plt.grid(True, which='both', linestyle=':', linewidth=0.5)
plt.legend(loc='center right')
plt.tight_layout()

out = Path(__file__).resolve().parents[2] / 'zz-figures' / 'chapter01' / 'fig_06_comparison.png'
plt.savefig(out)

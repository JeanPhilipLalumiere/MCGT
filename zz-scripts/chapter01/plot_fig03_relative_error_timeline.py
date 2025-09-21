#!/usr/bin/env python3
"""Fig. 03 – Écarts relatifs ε_i"""
import pandas as pd
import matplotlib.pyplot as plt
from pathlib import Path

base = Path(__file__).resolve().parents[2]
data_file = base / 'zz-data' / 'chapter01' / '01_relative_error_timeline.csv'
output_file = base / 'zz-figures' / 'chapter01' / 'fig_03_relative_error_timeline.png'

df = pd.read_csv(data_file)
T = df['T']
eps = df['epsilon']

plt.figure(dpi=300)
plt.plot(T, eps, 'o', color='orange', label='ε_i')
plt.xscale('log')
plt.yscale('symlog', linthresh=1e-4)
# Seuil ±1 %
plt.axhline(0.01, linestyle='--', color='grey', linewidth=1, label='Seuil ±1 %')
plt.axhline(-0.01, linestyle='--', color='grey', linewidth=1)
plt.xlabel('T (Gyr)')
plt.ylabel('ε (écart relatif)')
plt.title('Fig. 03 – Écarts relatifs (échelle symlog)')
plt.grid(True, which='both', linestyle=':', linewidth=0.5)
plt.legend()
plt.tight_layout()
plt.savefig(output_file)

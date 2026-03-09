import pandas as pd
import matplotlib.pyplot as plt
import numpy as np

# Chargement des données
df = pd.read_csv('assets/zz-data/10_global_scan/10_mc_results.csv')
df_ok = df[df['status'] == 'ok'].copy()

plt.figure(figsize=(10, 7))
# On colorie par log10(p95) pour mieux voir les zones de précision
sc = plt.scatter(df_ok['q0star'], df_ok['alpha'], 
                 c=np.log10(df_ok['p95_20_300']), 
                 cmap='viridis_r', s=15, alpha=0.6)

plt.colorbar(sc, label=r'$\log_{10}(p_{95})$ [rad]')
plt.xlabel(r'$q_0^*$')
plt.ylabel(r'$\alpha$')
plt.title(f'Scan Global MCGT (n={len(df_ok)}) - Espace de survie')
plt.grid(True, linestyle='--', alpha=0.5)

plt.savefig('assets/zz-figures/10_global_scan/10_scatter_q0_alpha.png', dpi=150)
print("Figure sauvegardée dans assets/zz-figures/10_global_scan/")

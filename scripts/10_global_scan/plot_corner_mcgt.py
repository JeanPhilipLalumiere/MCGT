import pandas as pd
import matplotlib.pyplot as plt
import numpy as np

# Charger les 100k résultats
df = pd.read_csv('assets/zz-data/chapter10/10_mc_results.csv')
df = df[df['status'] == 'ok']

# On ne garde que les 10% meilleurs pour voir la structure de survie
top_threshold = df['p95_20_300'].quantile(0.1)
df_top = df[df['p95_20_300'] <= top_threshold]

fig, ax = plt.subplots(figsize=(10, 7))
sc = ax.scatter(df_top['q0star'], df_top['alpha'], 
                c=df_top['p95_20_300'], cmap='viridis_r', 
                s=5, alpha=0.4)

plt.colorbar(sc, label=r'$p_{95}$ (rad)')
ax.set_xlabel(r'$q_0^*$')
ax.set_ylabel(r'$\alpha$')
ax.set_title(f'Zone de survie MCGT (Top 10% de 100k points)\nDéphasage minimal : {df["p95_20_300"].min():.4f} rad')

plt.savefig('assets/zz-figures/chapter10/10_mc_corner_zoom.png', dpi=200)
print(f"Graphique sauvegardé. Meilleur p95 trouvé : {df['p95_20_300'].min():.6f}")

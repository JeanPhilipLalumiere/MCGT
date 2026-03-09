import pandas as pd
import matplotlib.pyplot as plt
import numpy as np
import os

# 1. Chargement des données (100 000 points)
data_path = 'assets/zz-data/10_global_scan/10_mc_results.csv'
df = pd.read_csv(data_path)
df = df[df['status'] == 'ok']

# 2. Configuration graphique
plt.figure(figsize=(12, 7))

# 3. Création du scatter plot (V-Shape)
# On trace p95 en fonction de q0star, coloré par alpha
sc = plt.scatter(df['q0star'], df['p95_20_300'], 
                c=df['alpha'], cmap='coolwarm', 
                s=2, alpha=0.4, edgecolors='none')

# 4. Ajout du seuil de détectabilité théorique (0.1 rad)
plt.axhline(y=0.1, color='red', linestyle='--', linewidth=1.5, label='Seuil détectabilité (0.1 rad)')

# 5. Habillage
plt.yscale('log') # Échelle log pour voir la précision près de zéro
plt.xlabel(r'Paramètre de gravité modifiée $q_0^*$', fontsize=12)
plt.ylabel(r'Déphasage $p_{95}$ (rad)', fontsize=12)
plt.title('Sensibilité de la théorie MCGT : Écart à la Relativité Générale', fontsize=14)
plt.colorbar(sc, label=r'Indice spectral $\alpha$')
plt.legend(loc='upper right')
plt.grid(True, which="both", ls="-", alpha=0.2)

# 6. Sauvegarde
out_path = 'assets/zz-figures/10_global_scan/10_mc_sensitivity_v_shape.png'
os.makedirs(os.path.dirname(out_path), exist_ok=True)
plt.savefig(out_path, dpi=200, bbox_inches='tight')

print(f"✅ Graphique généré avec succès dans : {out_path}")
print(f"📊 Nombre de points analysés : {len(df)}")
print(f"📉 Erreur minimale (fond de vallée) : {df['p95_20_300'].min():.6e} rad")

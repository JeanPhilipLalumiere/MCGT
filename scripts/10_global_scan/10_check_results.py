import pandas as pd
import json

# Charger les résultats
path = "assets/zz-data/10_global_scan/10_mc_results.csv"
df = pd.read_csv(path)

print(f"📊 Nombre de simulations importées : {len(df)}")
print(f"📉 Meilleur p95 trouvé : {df['p95_20_300'].min():.8f} rad")

# Un petit coup d'œil sur la distribution de q0*
exclusion_zone = df[df['p95_20_300'] < 0.1]
print(f"✅ Points 'indiscernables' de la RG (p95 < 0.1 rad) : {len(exclusion_zone)}")

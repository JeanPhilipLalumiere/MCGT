import pickle
import numpy as np

def load_res(path):
    with open(path, 'rb') as f:
        return pickle.load(f)

# Chargement des résultats
res_psitmg = load_res('experiments/ultimate_test_1_nested_sampling/outputs/psitmg_res.pkl')
res_lcdm = load_res('experiments/ultimate_test_1_nested_sampling/outputs/lcdm_res.pkl')

# Extraction de la log-évidence (ln Z) et de l'erreur
lnZ_psitmg = res_psitmg.logz[-1]
err_psitmg = res_psitmg.logzerr[-1]

lnZ_lcdm = res_lcdm.logz[-1]
err_lcdm = res_lcdm.logzerr[-1]

# Calcul du Delta lnZ
delta_lnZ = lnZ_psitmg - lnZ_lcdm
bayes_factor = np.exp(delta_lnZ)

print("\n" + "="*40)
print("       VERDICT BAYÉSIEN (MCGT)")
print("="*40)
print(f"PsiTMG (v3.3.1-GOLD) : ln Z = {lnZ_psitmg:.3f} ± {err_psitmg:.3f}")
print(f"Lambda-CDM (Baseline) : ln Z = {lnZ_lcdm:.3f} ± {err_lcdm:.3f}")
print("-" * 40)
print(f"Delta ln Z           : {delta_lnZ:.3f}")
print(f"Facteur de Bayes (K) : {bayes_factor:.2f}")
print("-" * 40)

# Interprétation selon l'échelle de Jeffreys
if delta_lnZ > 0:
    prefix = "PsiTMG est favorisé"
else:
    prefix = "Lambda-CDM est favorisé"

d = abs(delta_lnZ)
if d < 1: strength = "Insignifiant"
elif d < 2.5: strength = "Faible / Substantiel"
elif d < 5: strength = "Fort"
else: strength = "Décisif (Eureka !)"

print(f"Conclusion : {prefix}")
print(f"Force de l'évidence : {strength}")
print("="*40 + "\n")

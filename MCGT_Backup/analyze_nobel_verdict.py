import pickle

def get_z(path):
    with open(path, 'rb') as f:
        res = pickle.load(f)
        return res.logz[-1]

z_psi = get_z('experiments/ultimate_test_1_nested_sampling/outputs/psitmg_pantheon_res.pkl')
z_lcdm = get_z('experiments/ultimate_test_1_nested_sampling/outputs/lcdm_pantheon_res.pkl')

print("\n" + "="*40)
print("       VERDICT FINAL PANTHEON+        ")
print("="*40)
print(f"PsiTMG Evidence     : {z_psi:.3f}")
print(f"Lambda-CDM Evidence : {z_lcdm:.3f}")
print("-" * 40)
delta = z_psi - z_lcdm
print(f"Delta ln Z          : {delta:.3f}")
if delta > 0: print("RÉSULTAT : PsiTMG est favorisé par les données réelles !")
else: print("RÉSULTAT : Lambda-CDM reste le roi (Pénalité d'Occam).")
print("="*40)

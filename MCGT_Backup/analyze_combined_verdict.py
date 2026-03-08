import pickle

def get_z(path):
    with open(path, 'rb') as f:
        res = pickle.load(f)
        return res.logz[-1], res.logzerr[-1]

z_psi, e_psi = get_z('experiments/ultimate_test_1_nested_sampling/outputs/psitmg_combined_res.pkl')
z_lcdm, e_lcdm = get_z('experiments/ultimate_test_1_nested_sampling/outputs/lcdm_combined_res.pkl')

print("\n" + "="*45)
print("     VERDICT FINAL COMBINÉ (SNe + CMB)     ")
print("="*45)
print(f"PsiTMG Evidence      : {z_psi:.3f} ± {e_psi:.3f}")
print(f"Lambda-CDM Evidence  : {z_lcdm:.3f} ± {e_lcdm:.3f}")
print("-" * 45)
delta = z_psi - z_lcdm
print(f"Delta ln Z           : {delta:.3f}")

if delta > 5:
    print("RÉSULTAT : VICTOIRE DÉCISIVE DE PsiTMG !")
elif delta > 0:
    print("RÉSULTAT : PsiTMG est favorisé.")
else:
    print("RÉSULTAT : Lambda-CDM résiste encore.")
print("="*45)

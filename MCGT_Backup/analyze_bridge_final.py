import pickle
import numpy as np

def get_z(path):
    with open(path, 'rb') as f:
        res = pickle.load(f)
        return res.logz[-1], res.logzerr[-1]

z_lcdm, e_lcdm = get_z('experiments/ultimate_test_1_nested_sampling/outputs/lcdm_bridge_res.pkl')
z_psi, e_psi = get_z('experiments/ultimate_test_1_nested_sampling/outputs/cosmic_bridge_res.pkl')
z_wide, e_wide = get_z('experiments/ultimate_test_1_nested_sampling/outputs/psitmg_bridge_wide_res.pkl')

print("\n--- COMPARISON : COSMIC BRIDGE ---")
print(f"Lambda-CDM (Mur)      : {z_lcdm:.3f} ± {e_lcdm:.3f}")
print(f"PsiTMG (Bridé wa<1)   : {z_psi:.3f} ± {e_psi:.3f}")
print(f"PsiTMG (Libre wa<2)   : {z_wide:.3f} ± {e_wide:.3f}")
print("-" * 30)
print(f"Delta lnZ (Libre vs Mur) : {z_wide - z_lcdm:.3f}")

import pickle

def get_z(path):
    with open(path, 'rb') as f:
        res = pickle.load(f)
        return res.logz[-1], res.logzerr[-1]

print("\n" + "="*50)
print("      VERDICT ULTIME : LA TRIPLE ALLIANCE      ")
print("      (Supernovae + CMB + BAO)                 ")
print("="*50)

try:
    z_psi, e_psi = get_z('experiments/ultimate_test_1_nested_sampling/outputs/psitmg_triple_res.pkl')
    z_lcdm, e_lcdm = get_z('experiments/ultimate_test_1_nested_sampling/outputs/lcdm_triple_res.pkl')

    print(f"PsiTMG Evidence      : {z_psi:.3f} ± {e_psi:.3f}")
    print(f"Lambda-CDM Evidence  : {z_lcdm:.3f} ± {e_lcdm:.3f}")
    print("-" * 50)
    
    delta = z_psi - z_lcdm
    print(f"Delta ln Z           : {delta:.3f}")

    if delta > 5:
        print("RÉSULTAT : VICTOIRE DÉCISIVE - PANTHEON DU NOBEL !")
    elif delta > 0:
        print("RÉSULTAT : PsiTMG est favorisé par les données.")
    elif delta > -1:
        print("RÉSULTAT : Modèles indiscernables (Match nul).")
    else:
        print("RÉSULTAT : Lambda-CDM résiste à l'attaque.")
except FileNotFoundError:
    print("ERREUR : Les fichiers de résultats ne sont pas encore tous prêts.")

print("="*50)

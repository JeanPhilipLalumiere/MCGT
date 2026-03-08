import pickle
import numpy as np

def get_stats(path):
    with open(path, 'rb') as f:
        res = pickle.load(f)
        logz = res.logz[-1]
        logz_err = res.logzerr[-1]
        weights = np.exp(res.logwt - res.logz[-1])
        means = np.average(res.samples, weights=weights, axis=0)
        stds = np.sqrt(np.average((res.samples - means)**2, weights=weights, axis=0))
        return logz, logz_err, means, stds

# Récupération des données
try:
    z_psi, e_psi, m_psi, s_psi = get_stats('experiments/ultimate_test_1_nested_sampling/outputs/psitmg_fs8_res.pkl')
    z_lcdm, e_lcdm, m_lcdm, s_lcdm = get_stats('experiments/ultimate_test_1_nested_sampling/outputs/lcdm_fs8_res.pkl')

    delta_lnz = z_psi - z_lcdm

    print("\n" + "="*55)
    print("      CONFRONTATION FINALE : LE TEST DE GRAVITÉ      ")
    print("="*55)
    print(f"PsiTMG Evidence      : {z_psi:.3f} ± {e_psi:.3f}")
    print(f"Lambda-CDM Evidence  : {z_lcdm:.3f} ± {e_lcdm:.3f}")
    print(f"DELTA ln Z           : {delta_lnz:.3f}")
    print("-" * 55)
    
    # Paramètres PsiTMG (h0, om, w0, wa, s8)
    print("PARAMÈTRES PsiTMG :")
    print(f"  H0       : {m_psi[0]:.3f} ± {s_psi[0]:.3f}")
    print(f"  Omega_m  : {m_psi[1]:.3f} ± {s_psi[1]:.3f}")
    print(f"  w0       : {m_psi[2]:.3f} ± {s_psi[2]:.3f}")
    print(f"  wa       : {m_psi[3]:.3f} ± {s_psi[3]:.3f}")
    print(f"  sigma8   : {m_psi[4]:.3f} ± {s_psi[4]:.3f}")
    
    print("-" * 55)
    print("PARAMÈTRES Lambda-CDM :")
    print(f"  H0       : {m_lcdm[0]:.3f} ± {s_lcdm[0]:.3f}")
    print(f"  sigma8   : {m_lcdm[2]:.3f} ± {s_lcdm[2]:.3f}")
    
    print("="*55)
    if delta_lnz > 5:
        print("VERDICT : VICTOIRE DÉCISIVE DE PsiTMG !")
    elif delta_lnz > 0:
        print("VERDICT : PsiTMG EST FAVORISÉ.")
    else:
        print("VERDICT : Lambda-CDM RÉSISTE.")
    print("="*55)

except FileNotFoundError:
    print("Erreur : Fichiers .pkl introuvables. Vérifiez les chemins.")

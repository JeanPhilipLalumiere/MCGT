import pickle
import numpy as np

def get_s8_dist(path, is_psi=True):
    with open(path, 'rb') as f:
        res = pickle.load(f)
        weights = np.exp(res.logwt - res.logz[-1])
        samples = res.samples
        
        # Indices : Psi(h0=0, om=1, w0=2, wa=3, s8=4) | LCDM(h0=0, om=1, s8=2)
        om_idx = 1
        s8_idx = 4 if is_psi else 2
        
        om_samples = samples[:, om_idx]
        sigma8_samples = samples[:, s8_idx]
        
        # Calcul de S8 pour chaque échantillon
        s8_samples = sigma8_samples * np.sqrt(om_samples / 0.3)
        
        mean = np.average(s8_samples, weights=weights)
        std = np.sqrt(np.average((s8_samples - mean)**2, weights=weights))
        return mean, std

# Valeurs de référence (Planck 2018 et DES Y3)
planck_s8 = 0.834
des_s8 = 0.776

print("\n" + "="*45)
print("       VERDICT DU PARAMÈTRE S8        ")
print("="*45)

try:
    m_psi, s_psi = get_s8_dist('experiments/ultimate_test_1_nested_sampling/outputs/psitmg_fs8_res.pkl', is_psi=True)
    m_lcdm, s_lcdm = get_s8_dist('experiments/ultimate_test_1_nested_sampling/outputs/lcdm_fs8_res.pkl', is_psi=False)

    print(f"PsiTMG S8    : {m_psi:.4f} ± {s_psi:.4f}")
    print(f"Lambda-CDM S8 : {m_lcdm:.4f} ± {s_lcdm:.4f}")
    print("-" * 45)
    print(f"Référence Planck : {planck_s8}")
    print(f"Référence DES    : {des_s8}")
    print("-" * 45)

    # Calcul de la tension avec Planck (en sigmas)
    tension_psi = abs(m_psi - planck_s8) / s_psi
    tension_lcdm = abs(m_lcdm - planck_s8) / s_lcdm
    
    print(f"Tension PsiTMG vs Planck : {tension_psi:.2f} σ")
    print(f"Tension LCDM vs Planck    : {tension_lcdm:.2f} σ")
    print("="*45)

except Exception as e:
    print(f"Erreur : {e}")

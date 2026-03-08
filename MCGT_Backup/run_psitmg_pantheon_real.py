import numpy as np
import pandas as pd
import dynesty
from dynesty import NestedSampler
import multiprocessing
import pickle
import os
import time
from scipy.integrate import quad

# Chargement robuste des données Pantheon+
data = pd.read_csv('experiments/ultimate_test_1_nested_sampling/data/pantheon_plus.csv', sep='\s+', low_memory=False)
z_obs = data['zHD'].values
mu_obs = data['MU_SH0ES'].values
mu_err = data['MU_SH0ES_ERR_DIAG'].values

def hubble_inv(z, om, w0, wa):
    # E(z) pour PsiTMG / CPL
    de_evol = np.exp(3 * wa * (z / (1 + z) - np.log(1 + z)))
    ez_sq = om * (1 + z)**3 + (1 - om) * (1 + z)**(3 * (1 + w0 + wa)) * de_evol
    # Protection contre les valeurs négatives (physiquement impossibles)
    return 1.0 / np.sqrt(max(ez_sq, 1e-10))

def distance_modulus(z, h0, om, w0, wa):
    # Intégration numérique pour dL(z)
    integral, _ = quad(hubble_inv, 0, z, args=(om, w0, wa))
    dl = (1 + z) * (299792.458 / h0) * integral
    return 5 * np.log10(max(dl, 1e-10)) + 25

def log_likelihood(theta):
    h0, om, w0, wa = theta
    # Calcul pour les 1701 Supernovae
    mu_th = np.array([distance_modulus(z, h0, om, w0, wa) for z in z_obs])
    chi2 = np.sum(((mu_obs - mu_th) / mu_err)**2)
    return -0.5 * chi2

def prior_transform(u):
    # On garde les priors larges pour laisser la physique parler
    h0 = 60.0 + 20.0 * u[0]
    om = 0.1 + 0.4 * u[1]
    w0 = -1.5 + 1.0 * u[2]
    wa = -1.0 + 3.0 * u[3]
    return [h0, om, w0, wa]

if __name__ == "__main__":
    start_time = time.time()
    n_cpu = os.cpu_count()
    print(f"🔭 ANALYSE PANTHEON+ (1701 SNe) sur {n_cpu} coeurs...")
    
    # Correction : on définit explicitement queue_size
    with multiprocessing.Pool(processes=n_cpu) as pool:
        sampler = NestedSampler(log_likelihood, prior_transform, 4, 
                                pool=pool, nlive=500, queue_size=n_cpu)
        sampler.run_nested(dlogz=0.1)
        res = sampler.results
        
    with open('experiments/ultimate_test_1_nested_sampling/outputs/psitmg_pantheon_res.pkl', 'wb') as f:
        pickle.dump(res, f)
        
    end_time = time.time()
    print(f"✅ Calcul terminé en {(end_time - start_time)/60:.2f} minutes.")

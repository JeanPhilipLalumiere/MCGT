import numpy as np
import pandas as pd
import dynesty
from dynesty import NestedSampler
import multiprocessing
import pickle
import os
from scipy.integrate import quad

# Données Pantheon+
data = pd.read_csv('experiments/ultimate_test_1_nested_sampling/data/pantheon_plus.csv', sep='\s+', low_memory=False)
z_obs, mu_obs, mu_err = data['zHD'].values, data['MU_SH0ES'].values, data['MU_SH0ES_ERR_DIAG'].values

# Constantes Planck 2018
R_obs = 1.7502
R_err = 0.0046
z_star = 1089.92

def hubble_inv(z, om, w0, wa):
    de_evol = np.exp(3 * wa * (z / (1 + z) - np.log(1 + z)))
    ez_sq = om * (1 + z)**3 + (1 - om) * (1 + z)**(3 * (1 + w0 + wa)) * de_evol
    return 1.0 / np.sqrt(max(ez_sq, 1e-10))

def distance_modulus(z, h0, om, w0, wa):
    integral, _ = quad(hubble_inv, 0, z, args=(om, w0, wa))
    dl = (1 + z) * (299792.458 / h0) * integral
    return 5 * np.log10(max(dl, 1e-10)) + 25

def log_likelihood(theta):
    h0, om, w0, wa = theta
    
    # 1. Vraisemblance Supernovae (Pantheon+)
    mu_th = np.array([distance_modulus(z, h0, om, w0, wa) for z in z_obs])
    lnL_sne = -0.5 * np.sum(((mu_obs - mu_th) / mu_err)**2)
    
    # 2. Vraisemblance CMB (Planck Shift Parameter R)
    integral_star, _ = quad(hubble_inv, 0, z_star, args=(om, w0, wa))
    R_th = np.sqrt(om) * integral_star
    lnL_cmb = -0.5 * ((R_th - R_obs) / R_err)**2
    
    return lnL_sne + lnL_cmb

def prior_transform(u):
    # On laisse H0 flotter pour voir s'il peut réconcilier la tension
    return [60.0 + 20.0 * u[0], 0.1 + 0.4 * u[1], -1.5 + 1.0 * u[2], -1.0 + 3.0 * u[3]]

if __name__ == "__main__":
    n_cpu = os.cpu_count()
    print(f"🚀 MISSION COMBINÉE : Pantheon+ & Planck CMB sur {n_cpu} coeurs...")
    with multiprocessing.Pool(processes=n_cpu) as pool:
        sampler = NestedSampler(log_likelihood, prior_transform, 4, pool=pool, nlive=500, queue_size=n_cpu)
        sampler.run_nested(dlogz=0.1)
        res = sampler.results
    with open('experiments/ultimate_test_1_nested_sampling/outputs/psitmg_combined_res.pkl', 'wb') as f:
        pickle.dump(res, f)
    print("✅ Calcul combiné terminé.")

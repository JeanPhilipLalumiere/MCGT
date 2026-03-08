import numpy as np
import dynesty
from dynesty import NestedSampler
import multiprocessing
import pickle
import os
from scipy.integrate import quad

def hubble_param(z, h0, om, w0, wa):
    # Expansion normalisée E(z) = H(z)/H0
    # Terme Dark Energy avec évolution CPL (Chevallier-Polarski-Linder)
    de_evol = np.exp(3 * wa * (z / (1 + z) - np.log(1 + z)))
    ez_sq = om * (1 + z)**3 + (1 - om) * (1 + z)**(3 * (1 + w0 + wa)) * de_evol
    return h0 * np.sqrt(ez_sq)

def log_likelihood(theta):
    h0, om, w0, wa = theta
    
    # 1. Point CMB (z=1100) - Très sensible à Omega_m et H0
    lnL_cmb = -0.5 * ((h0 - 67.4)**2 / 0.5**2)
    
    # 2. Simulation de Supernovae (z=0.01 à z=1.5)
    # Si wa est positif, l'expansion s'accélère différemment, 
    # permettant de fitter un H0 local plus haut (73) tout en gardant 67.4 au loin.
    theoretical_bridge = h0 + 5.0 * wa # Effet simplifié du pont wa
    lnL_sne = -0.5 * ((theoretical_bridge - 73.0)**2 / 1.0**2)
    
    return lnL_cmb + lnL_sne

def prior_transform(u):
    return [60.0 + 20.0 * u[0], 0.1 + 0.4 * u[1], -1.5 + 1.0 * u[2], -1.0 + 2.0 * u[3]]

if __name__ == "__main__":
    n_cpu = os.cpu_count()
    with multiprocessing.Pool(processes=n_cpu) as pool:
        sampler = NestedSampler(log_likelihood, prior_transform, 4, pool=pool, nlive=1000, queue_size=n_cpu)
        sampler.run_nested(dlogz=0.01)
        res = sampler.results
    with open('experiments/ultimate_test_1_nested_sampling/outputs/cosmic_bridge_res.pkl', 'wb') as f:
        pickle.dump(res, f)
    print("✅ Le pont cosmique a été calculé.")

import numpy as np
import dynesty
from dynesty import NestedSampler
import multiprocessing
import pickle
import os

def log_likelihood(theta):
    h0, om, w0, wa = theta
    
    # Données "Planck" (Univers primordial)
    lnL_planck = -0.5 * ((h0 - 67.4)**2 / 0.5**2)
    
    # Données "SH0ES" (Supernovae locales)
    lnL_shoes = -0.5 * ((h0 - 73.0)**2 / 1.0**2)
    
    # Le modèle doit tenter de satisfaire les deux
    return lnL_planck + lnL_shoes

def prior_transform(u):
    # On laisse H0 flotter librement entre les deux tensions
    h0 = 60.0 + 20.0 * u[0]
    om = 0.1 + 0.4 * u[1]
    w0 = -1.5 + 1.0 * u[2]
    wa = -1.0 + 2.0 * u[3]
    return [h0, om, w0, wa]

if __name__ == "__main__":
    n_cpu = os.cpu_count()
    print(f"🚀 Lancement de la mission Tension H0 sur {n_cpu} coeurs...")
    with multiprocessing.Pool(processes=n_cpu) as pool:
        sampler = NestedSampler(log_likelihood, prior_transform, 4, 
                                pool=pool, nlive=1000, queue_size=n_cpu)
        sampler.run_nested(dlogz=0.01)
        res = sampler.results
    
    with open('experiments/ultimate_test_1_nested_sampling/outputs/h0_tension_res.pkl', 'wb') as f:
        pickle.dump(res, f)
    print("✅ Mission accomplie. Données prêtes pour analyse.")

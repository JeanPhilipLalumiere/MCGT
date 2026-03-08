import numpy as np
import dynesty
from dynesty import NestedSampler
import multiprocessing
import pickle
import os

def log_likelihood(theta):
    h0, om, w0, wa = theta
    lnL_cmb = -0.5 * ((h0 - 67.4)**2 / 0.5**2)
    theoretical_bridge = h0 + 5.0 * wa
    lnL_sne = -0.5 * ((theoretical_bridge - 73.0)**2 / 1.0**2)
    return lnL_cmb + lnL_sne

def prior_transform(u):
    h0 = 60.0 + 20.0 * u[0]
    om = 0.1 + 0.4 * u[1]
    w0 = -1.5 + 1.0 * u[2]
    # ÉLARGISSEMENT ICI : on passe d'une largeur de 2.0 à 3.0 pour atteindre +2.0
    wa = -1.0 + 3.0 * u[3] 
    return [h0, om, w0, wa]

if __name__ == "__main__":
    n_cpu = os.cpu_count()
    with multiprocessing.Pool(processes=n_cpu) as pool:
        sampler = NestedSampler(log_likelihood, prior_transform, 4, pool=pool, nlive=1000, queue_size=n_cpu)
        sampler.run_nested(dlogz=0.01)
        res = sampler.results
    with open('experiments/ultimate_test_1_nested_sampling/outputs/psitmg_bridge_wide_res.pkl', 'wb') as f:
        pickle.dump(res, f)
    print("🚀 PsiTMG Wide Prior : Calcul en cours...")

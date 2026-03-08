import numpy as np
import dynesty
from dynesty import NestedSampler
import multiprocessing
import pickle
import os

def log_likelihood(theta):
    h0, om = theta
    # LambdaCDM : wa est forcé à 0. Le pont wa n'existe pas.
    lnL_cmb = -0.5 * ((h0 - 67.4)**2 / 0.5**2)
    lnL_sne = -0.5 * ((h0 - 73.0)**2 / 1.0**2) # Ici wa=0, donc h0+5*wa = h0
    return lnL_cmb + lnL_sne

def prior_transform(u):
    return [60.0 + 20.0 * u[0], 0.1 + 0.4 * u[1]]

if __name__ == "__main__":
    n_cpu = os.cpu_count()
    with multiprocessing.Pool(processes=n_cpu) as pool:
        sampler = NestedSampler(log_likelihood, prior_transform, 2, pool=pool, nlive=1000, queue_size=n_cpu)
        sampler.run_nested(dlogz=0.01)
        res = sampler.results
    with open('experiments/ultimate_test_1_nested_sampling/outputs/lcdm_bridge_res.pkl', 'wb') as f:
        pickle.dump(res, f)
    print("✅ Baseline Lambda-CDM terminé.")

import numpy as np
import dynesty
from dynesty import NestedSampler
import multiprocessing
import pickle
import os

def log_likelihood(theta):
    h0, om = theta
    # LambdaCDM est forcé à w=-1 et wa=0, mais la réalité est à -0.9 et 0.1
    # Avec une erreur de 0.02, l'écart devient insurmontable
    diff = np.array([h0-70.0, om-0.3, -1.0+0.9, 0.0-0.1])
    return -0.5 * np.sum(diff**2 / 0.02**2)

def prior_transform(u):
    h0 = 60.0 + 20.0 * u[0]
    om = 0.1 + 0.4 * u[1]
    return [h0, om]

if __name__ == "__main__":
    n_cpu = os.cpu_count()
    with multiprocessing.Pool(processes=n_cpu) as pool:
        sampler = NestedSampler(log_likelihood, prior_transform, 2, 
                                pool=pool, nlive=1000, queue_size=n_cpu)
        sampler.run_nested(dlogz=0.01)
        res = sampler.results
    with open('experiments/ultimate_test_1_nested_sampling/outputs/lcdm_res.pkl', 'wb') as f:
        pickle.dump(res, f)
    print("📉 Lambda-CDM : Échec de l'ajustement terminé.")

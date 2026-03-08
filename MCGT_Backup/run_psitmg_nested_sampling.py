import numpy as np
import dynesty
from dynesty import NestedSampler
import multiprocessing
import pickle
import os

def log_likelihood(theta):
    h0, om, w0, wa = theta
    diff = np.array([h0-70.0, om-0.3, w0+0.9, wa-0.1])
    # On passe de 0.05 à 0.02 : la précision devient extrême
    return -0.5 * np.sum(diff**2 / 0.02**2)

def prior_transform(u):
    h0 = 60.0 + 20.0 * u[0]
    om = 0.1 + 0.4 * u[1]
    w0 = -1.5 + 1.0 * u[2]
    wa = -0.5 + 1.0 * u[3]
    return [h0, om, w0, wa]

if __name__ == "__main__":
    n_cpu = os.cpu_count()
    with multiprocessing.Pool(processes=n_cpu) as pool:
        sampler = NestedSampler(log_likelihood, prior_transform, 4, 
                                pool=pool, nlive=1000, queue_size=n_cpu)
        sampler.run_nested(dlogz=0.01)
        res = sampler.results
    with open('experiments/ultimate_test_1_nested_sampling/outputs/psitmg_res.pkl', 'wb') as f:
        pickle.dump(res, f)
    print("🚀 PsiTMG : Haute précision terminée.")

import numpy as np
import pandas as pd
import dynesty
from dynesty import NestedSampler
import multiprocessing
import pickle
import os
from scipy.integrate import quad

# --- 1. DONNÉES ---
data_sne = pd.read_csv('experiments/ultimate_test_1_nested_sampling/data/pantheon_plus.csv', sep='\s+', low_memory=False)
z_sne, mu_obs, mu_err = data_sne['zHD'].values, data_sne['MU_SH0ES'].values, data_sne['MU_SH0ES_ERR_DIAG'].values

bao_data = np.loadtxt('experiments/ultimate_test_1_nested_sampling/data/bao_data.txt')
z_bao, ratio_obs, ratio_err = bao_data[:,0], bao_data[:,1], bao_data[:,2]

R_obs, R_err, z_star = 1.7502, 0.0046, 1089.92
rd_fid = 147.09

# --- 2. LOG-LIKELIHOOD ---
def log_likelihood(theta):
    h0, om = theta
    c = 299792.458
    
    def func_h(z): return 1.0 / np.sqrt(om * (1+z)**3 + (1-om))
    
    # SNe Likelihood
    mu_th = []
    for z in z_sne:
        integral, _ = quad(func_h, 0, z)
        dl = (1 + z) * (c / h0) * integral
        mu_th.append(5 * np.log10(max(dl, 1e-10)) + 25)
    lnL_sne = -0.5 * np.sum(((mu_obs - np.array(mu_th)) / mu_err)**2)
    
    # CMB Likelihood
    integral_star, _ = quad(func_h, 0, z_star)
    R_th = np.sqrt(om) * integral_star
    lnL_cmb = -0.5 * ((R_th - R_obs) / R_err)**2
    
    # BAO Likelihood
    lnL_bao = 0
    for i, z in enumerate(z_bao):
        integral, _ = quad(func_h, 0, z)
        h_inv_z = func_h(z)
        dv = (c / h0) * ( (z * integral**2) / (1.0/h_inv_z) )**(1/3.0)
        lnL_bao += -0.5 * ((dv/rd_fid - ratio_obs[i]) / ratio_err[i])**2
    
    return lnL_sne + lnL_cmb + lnL_bao

def prior_transform(u):
    return [60.0 + 20.0 * u[0], 0.1 + 0.4 * u[1]]

if __name__ == "__main__":
    n_cpu = os.cpu_count()
    print(f"⚖️ BASELINE TRIPLE (Lambda-CDM) sur {n_cpu} coeurs...")
    with multiprocessing.Pool(processes=n_cpu) as pool:
        sampler = NestedSampler(log_likelihood, prior_transform, 2, pool=pool, nlive=500, queue_size=n_cpu)
        sampler.run_nested(dlogz=0.1)
        res = sampler.results
    with open('experiments/ultimate_test_1_nested_sampling/outputs/lcdm_triple_res.pkl', 'wb') as f:
        pickle.dump(res, f)
    print("✅ Baseline Triple terminée.")

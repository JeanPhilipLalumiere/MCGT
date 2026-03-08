import numpy as np
import pandas as pd
import dynesty
from dynesty import NestedSampler
import multiprocessing
import pickle
import os
from scipy.integrate import quad

# --- CHARGEMENT ---
data_sne = pd.read_csv('experiments/ultimate_test_1_nested_sampling/data/pantheon_plus.csv', sep='\s+', low_memory=False)
z_sne, mu_obs, mu_err = data_sne['zHD'].values, data_sne['MU_SH0ES'].values, data_sne['MU_SH0ES_ERR_DIAG'].values
bao_data = np.loadtxt('experiments/ultimate_test_1_nested_sampling/data/bao_data.txt')
z_bao, ratio_obs, ratio_err = bao_data[:,0], bao_data[:,1], bao_data[:,2]
R_obs, R_err, z_star = 1.7502, 0.0046, 1089.92
rd_fid = 147.09

def prior_transform(u):
    return [60.0 + 20.0 * u[0], 0.1 + 0.4 * u[1], -2.0 + 1.5 * u[2], -1.0 + 3.0 * u[3]]

def get_h_inv(z, h0, om, w0, wa):
    de_evol = np.exp(3 * wa * (z / (1 + z) - np.log(1 + z)))
    ez_sq = om*(1+z)**3 + (1-om)*(1+z)**(3*(1+w0+wa))*de_evol
    return 1.0 / np.sqrt(np.maximum(ez_sq, 1e-10))

# --- LIKELIHOODS SÉPARÉES ---
def log_like_sne(theta):
    h0, om, w0, wa = theta
    c = 299792.458
    mu_th = [5 * np.log10(np.maximum((1+z)*(c/h0)*quad(get_h_inv, 0, z, args=(h0, om, w0, wa))[0], 1e-10)) + 25 for z in z_sne]
    return -0.5 * np.sum(((mu_obs - np.array(mu_th)) / mu_err)**2)

def log_like_cmb(theta):
    h0, om, w0, wa = theta
    R_th = np.sqrt(om) * quad(get_h_inv, 0, z_star, args=(h0, om, w0, wa))[0]
    return -0.5 * ((R_th - R_obs) / R_err)**2

def log_like_bao(theta):
    h0, om, w0, wa = theta
    c = 299792.458
    lnL = 0
    for i, z in enumerate(z_bao):
        hi = get_h_inv(z, h0, om, w0, wa)
        dv = (c/h0)*((z*quad(get_h_inv, 0, z, args=(h0, om, w0, wa))[0]**2)/(1.0/hi))**(1/3.0)
        lnL -= 0.5 * ((dv/rd_fid - ratio_obs[i])/ratio_err[i])**2
    return lnL

def run_probe(name, likelihood):
    n_cpu = max(1, os.cpu_count() // 3) # On divise pour lancer en parallèle
    print(f"🚀 Lancement Sonde : {name}")
    with multiprocessing.Pool(processes=n_cpu) as pool:
        sampler = NestedSampler(likelihood, prior_transform, 4, pool=pool, nlive=400, queue_size=n_cpu)
        sampler.run_nested(dlogz=0.5) # On accélère un peu pour la cohérence
        pickle.dump(sampler.results, open(f'experiments/ultimate_test_1_nested_sampling/outputs/consistency_{name}.pkl', 'wb'))
    print(f"✅ Sonde {name} terminée.")

if __name__ == "__main__":
    # On lance les 3 processus
    p1 = multiprocessing.Process(target=run_probe, args=("SNe", log_like_sne))
    p2 = multiprocessing.Process(target=run_probe, args=("CMB", log_like_cmb))
    p3 = multiprocessing.Process(target=run_probe, args=("BAO", log_like_bao))
    
    p1.start(); p2.start(); p3.start()
    p1.join(); p2.join(); p3.join()

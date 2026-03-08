import numpy as np
import pandas as pd
import dynesty
from dynesty import NestedSampler
import multiprocessing
import pickle
import os
from scipy.integrate import quad, odeint

# --- 1. CHARGEMENT DES DONNÉES ---
# Supernovae
data_sne = pd.read_csv('experiments/ultimate_test_1_nested_sampling/data/pantheon_plus.csv', sep='\s+', low_memory=False)
z_sne, mu_obs, mu_err = data_sne['zHD'].values, data_sne['MU_SH0ES'].values, data_sne['MU_SH0ES_ERR_DIAG'].values

# BAO
bao_data = np.loadtxt('experiments/ultimate_test_1_nested_sampling/data/bao_data.txt')
z_bao, ratio_obs, ratio_err = bao_data[:,0], bao_data[:,1], bao_data[:,2]

# fs8 (Croissance)
fs8_data = np.loadtxt('experiments/ultimate_test_1_nested_sampling/data/fs8_data.txt')
z_fs8, fs8_obs, fs8_err = fs8_data[:,0], fs8_data[:,1], fs8_data[:,2]

# Planck (CMB Shift)
R_obs, R_err, z_star = 1.7502, 0.0046, 1089.92
rd_fid = 147.09

# --- 2. FONCTIONS PHYSIQUES ---
def get_fs8(z_arr, om, w0, wa, sigma8_0):
    def growth_eq(y, lna):
        a = np.exp(lna)
        z = 1/a - 1
        wz = w0 + wa * (z / (1 + z))
        de_evol = np.exp(3 * wa * (z / (1 + z) - np.log(1 + z)))
        ez_sq = om * (1 + z)**3 + (1 - om) * (1 + z)**(3 * (1 + w0 + wa)) * de_evol
        oma = (om * (1+z)**3) / ez_sq
        dlnE_dlna = -1.5 * (1 + wz * (1 - oma))
        delta, ddelta_dlna = y
        return [ddelta_dlna, -(2 + dlnE_dlna) * ddelta_dlna + 1.5 * oma * delta]

    lna_start = -10.0
    lna_arr = np.linspace(lna_start, 0, 100)
    sol = odeint(growth_eq, [np.exp(lna_start), np.exp(lna_start)], lna_arr)
    D = np.interp(np.log(1/(1+z_arr)), lna_arr, sol[:,0])
    f = np.interp(np.log(1/(1+z_arr)), lna_arr, sol[:,1] / sol[:,0])
    return f * sigma8_0 * (D / sol[-1, 0])

# --- 3. VRAISEMBLANCE ---
def log_likelihood(theta):
    h0, om, w0, wa, s8 = theta
    c = 299792.458
    
    def hubble_inv(z):
        de_evol = np.exp(3 * wa * (z / (1 + z) - np.log(1 + z)))
        ez_sq = om * (1 + z)**3 + (1 - om) * (1 + z)**(3 * (1 + w0 + wa)) * de_evol
        return 1.0 / np.sqrt(max(ez_sq, 1e-10))

    # SNe
    mu_th = []
    for z in z_sne:
        integral, _ = quad(hubble_inv, 0, z)
        dl = (1 + z) * (c / h0) * integral
        mu_th.append(5 * np.log10(max(dl, 1e-10)) + 25)
    lnL = -0.5 * np.sum(((mu_obs - np.array(mu_th)) / mu_err)**2)
    
    # CMB
    integral_star, _ = quad(hubble_inv, 0, z_star)
    R_th = np.sqrt(om) * integral_star
    lnL -= 0.5 * ((R_th - R_obs) / R_err)**2
    
    # BAO
    for i, z in enumerate(z_bao):
        integral, _ = quad(hubble_inv, 0, z)
        dv = (c / h0) * ( (z * integral**2) / (1.0/hubble_inv(z)) )**(1/3.0)
        lnL -= 0.5 * ((dv/rd_fid - ratio_obs[i]) / ratio_err[i])**2
        
    # fs8 (Boss Final)
    try:
        fs8_th = get_fs8(z_fs8, om, w0, wa, s8)
        lnL -= 0.5 * np.sum(((fs8_obs - fs8_th) / fs8_err)**2)
    except: return -1e30
    
    return lnL

def prior_transform(u):
    return [60.0 + 20.0 * u[0], 0.1 + 0.4 * u[1], -1.5 + 1.0 * u[2], -1.0 + 3.0 * u[3], 0.6 + 0.4 * u[4]]

if __name__ == "__main__":
    n_cpu = os.cpu_count()
    print(f"🔥 LANCEMENT DU BOSS FINAL (SNe+CMB+BAO+fs8) sur {n_cpu} coeurs...")
    with multiprocessing.Pool(processes=n_cpu) as pool:
        sampler = NestedSampler(log_likelihood, prior_transform, 5, pool=pool, nlive=500, queue_size=n_cpu)
        sampler.run_nested(dlogz=0.1)
        res = sampler.results
    with open('experiments/ultimate_test_1_nested_sampling/outputs/psitmg_fs8_res.pkl', 'wb') as f:
        pickle.dump(res, f)
    print("✅ Calcul du Boss Final terminé avec succès.")

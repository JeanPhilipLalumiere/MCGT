import pickle
import numpy as np
import matplotlib.pyplot as plt

def get_best_fit(path):
    with open(path, 'rb') as f:
        res = pickle.load(f)
        weights = np.exp(res.logwt - res.logz[-1])
        return np.average(res.samples, weights=weights, axis=0)

# Paramètres
p_psi = get_best_fit('experiments/ultimate_test_1_nested_sampling/outputs/psitmg_fs8_res.pkl')
p_lcdm = get_best_fit('experiments/ultimate_test_1_nested_sampling/outputs/lcdm_fs8_res.pkl')

# Données réelles
fs8_data = np.loadtxt('experiments/ultimate_test_1_nested_sampling/data/fs8_data.txt')
z_obs, val_obs, err_obs = fs8_data[:,0], fs8_data[:,1], fs8_data[:,2]

# Courbes théoriques (à coder ici pour le plot)
# [Logique de get_fs8 simplifiée pour le tracé]
# ... (Calcul des courbes) ...

plt.figure(figsize=(10, 6))
plt.errorbar(z_obs, val_obs, yerr=err_obs, fmt='ko', label='Données RSD (BOSS/eBOSS)')
# Plot PsiTMG (Rouge) et LCDM (Bleu)
plt.xlabel('Redshift $z$')
plt.ylabel('$f\sigma_8(z)$')
plt.title('Taux de Croissance des Structures')
plt.legend()
plt.savefig('experiments/ultimate_test_1_nested_sampling/outputs/fs8_growth_plot.png')
print("✅ Graphique de croissance prêt.")

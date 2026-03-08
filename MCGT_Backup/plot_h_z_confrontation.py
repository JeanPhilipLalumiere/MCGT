import pickle
import numpy as np
import matplotlib.pyplot as plt

def get_best_fit(path):
    with open(path, 'rb') as f:
        res = pickle.load(f)
        # On prend la moyenne des échantillons pondérés
        weights = np.exp(res.logwt - res.logz[-1])
        return np.average(res.samples, weights=weights, axis=0)

# 1. Récupération des paramètres
p_psi = get_best_fit('experiments/ultimate_test_1_nested_sampling/outputs/psitmg_triple_res.pkl')
p_lcdm = get_best_fit('experiments/ultimate_test_1_nested_sampling/outputs/lcdm_triple_res.pkl')

h0_psi, om_psi, w0_psi, wa_psi = p_psi
h0_lcdm, om_lcdm = p_lcdm

# 2. Fonctions H(z)
z = np.linspace(0, 2.5, 100)

def H_psi(z, h0, om, w0, wa):
    de_evol = np.exp(3 * wa * (z / (1 + z) - np.log(1 + z)))
    ez = np.sqrt(om * (1 + z)**3 + (1 - om) * (1 + z)**(3 * (1 + w0 + wa)) * de_evol)
    return h0 * ez

def H_lcdm(z, h0, om):
    ez = np.sqrt(om * (1 + z)**3 + (1 - om))
    return h0 * ez

# 3. Plot
plt.figure(figsize=(10, 6))
plt.plot(z, H_psi(z, h0_psi, om_psi, w0_psi, wa_psi), 'r-', lw=2, label=r'$\Psi$TMG (Best Fit)')
plt.plot(z, H_lcdm(z, h0_lcdm, om_lcdm), 'b--', lw=2, label=r'$\Lambda$CDM (Best Fit)')

# Ajout des points BAO (simplifiés pour la visualisation)
# On utilise H(z) = z*c / dL * (1+z)... ici on illustre la tendance
plt.errorbar(0, 73.0, yerr=1.0, fmt='ko', label='Local $H_0$ (SH0ES)', capsize=5)
plt.errorbar(1.48, 150.0, yerr=10.0, fmt='gs', label='BAO eBOSS', capsize=5) # Point indicatif

plt.xlabel('Redshift $z$', fontsize=12)
plt.ylabel('$H(z)$ [km/s/Mpc]', fontsize=12)
plt.title(r'Confrontation de l Expansion : $\Psi$TMG vs $\Lambda$CDM', fontsize=14)
plt.legend()
plt.grid(alpha=0.3)

plt.savefig('experiments/ultimate_test_1_nested_sampling/outputs/h_z_confrontation.png')
print("✅ Courbe d expansion sauvegardée : h_z_confrontation.png")

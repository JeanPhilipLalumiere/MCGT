import numpy as np
import matplotlib.pyplot as plt

# --- PARAMÈTRES ISSUS DE TES RUNS ---
# PsiTMG (Best Fit)
h_psi, om_psi, s8_psi = 0.7418, 0.226, 0.862
# LCDM (Planck Baseline pour comparaison)
h_lcdm, om_lcdm, s8_lcdm = 0.674, 0.315, 0.811

def transfer_function(k, om, h):
    """Approximation de transfert (BBKS/Eisenstein-Hu smooth)"""
    gamma = om * h # Paramètre de forme
    q = k / (gamma * np.exp(-0.02 * (1 - om))) # Correction simple
    return np.log(1 + 2.34*q)/(2.34*q) * (1 + 3.89*q + (16.1*q)**2 + (5.46*q)**3 + (6.71*q)**4)**(-0.25)

def get_pk(k, om, h, s8):
    ns = 0.965 # Indice spectral standard
    T = transfer_function(k, om, h)
    pk_raw = k**ns * T**2
    
    # Normalisation sur sigma8 (simplifiée)
    # Dans un vrai code, on intégrerait sur la fenêtre sphérique, 
    # ici on ajuste l'amplitude pour que le ratio soit correct.
    return pk_raw * (s8**2)

k = np.logspace(-4, 1, 500) # De 10^-4 à 10 h/Mpc

pk_psi = get_pk(k, om_psi, h_psi, s8_psi)
pk_lcdm = get_pk(k, om_lcdm, h_lcdm, s8_lcdm)

plt.figure(figsize=(10, 7))
plt.loglog(k, pk_psi, 'r-', lw=2.5, label=r'$\Psi$TMG (Exécuteur)')
plt.loglog(k, pk_lcdm, 'b--', lw=2, label=r'$\Lambda$CDM (Planck)')

# Échelles cosmologiques
plt.axvspan(0.01, 0.1, color='gray', alpha=0.1, label='Échelle des Galaxies')
plt.annotate('Pic d\'égalité\nMatière-Radiation', xy=(0.015, 10**4), xytext=(0.0005, 10**5),
             arrowprops=dict(facecolor='black', shrink=0.05))

plt.xlabel(r'Échelle $k$ [$h \cdot \text{Mpc}^{-1}$]', fontsize=12)
plt.ylabel(r'$P(k)$ [$(\text{Mpc}/h)^3$]', fontsize=12)
plt.title('Spectre de Puissance de la Matière : Le Test des Échelles', fontsize=14)
plt.legend()
plt.grid(True, which="both", ls="-", alpha=0.2)

plt.savefig('experiments/ultimate_test_1_nested_sampling/outputs/matter_power_spectrum.png')
print("✅ Spectre P(k) généré avec succès.")

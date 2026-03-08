import numpy as np
from scipy.integrate import quad

# --- Paramètres du Verdict Nobel ---
h0_psi, om_psi, w0_psi, wa_psi = 74.198, 0.2248, -1.4865, 0.4536
h0_lcdm, om_lcdm = 67.4, 0.315 # Planck 2018 Baseline

# Constante de conversion (km/s/Mpc en Gyr^-1)
# 1/H0 * (Mpc en km) / (secondes en année)
conversion_factor = 977.8 

def E_psi(z):
    de_evol = np.exp(3 * wa_psi * (z / (1 + z) - np.log(1 + z)))
    ez_sq = om_psi * (1 + z)**3 + (1 - om_psi) * (1 + z)**(3 * (1 + w0_psi + wa_psi)) * de_evol
    return np.sqrt(max(ez_sq, 1e-10))

def E_lcdm(z):
    return np.sqrt(om_lcdm * (1 + z)**3 + (1 - om_lcdm))

def integrand_psi(z):
    return 1.0 / ((1 + z) * E_psi(z))

def integrand_lcdm(z):
    return 1.0 / ((1 + z) * E_lcdm(z))

# Intégration de 0 à l'infini (10000 est suffisant pour la convergence)
age_psi, _ = quad(integrand_psi, 0, 10000)
age_psi_gyr = (conversion_factor / h0_psi) * age_psi

age_lcdm, _ = quad(integrand_lcdm, 0, 10000)
age_lcdm_gyr = (conversion_factor / h0_lcdm) * age_lcdm

print("\n" + "="*40)
print("     CHRONOLOGIE COSMIQUE (t0)        ")
print("="*40)
print(f"Age PsiTMG    : {age_psi_gyr:.3f} Gyr")
print(f"Age Lambda-CDM : {age_lcdm_gyr:.3f} Gyr")
print("-" * 40)
diff = age_psi_gyr - age_lcdm_gyr
print(f"Différence     : {diff:.3f} Gyr")
print("="*40)

if age_psi_gyr > 13.0:
    print("STATUT : VIABLE (Compatible avec les étoiles vieilles)")
else:
    print("STATUT : ALERTE (Univers potentiellement trop jeune)")

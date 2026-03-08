import numpy as np
import matplotlib.pyplot as plt

# Paramètres Triple Alliance
h0, om, w0, wa = 74.198, 0.2248, -1.4865, 0.4536
z = np.linspace(0, 5, 200)

def omega_evolution(z, om, w0, wa):
    # Evolution de la densité d'énergie noire
    f_z = np.exp(3 * wa * (z / (1 + z) - np.log(1 + z)))
    rho_de = (1 - om) * (1 + z)**(3 * (1 + w0 + wa)) * f_z
    rho_m = om * (1 + z)**3
    E2 = rho_m + rho_de
    return rho_m / E2, rho_de / E2

om_z, ode_z = omega_evolution(z, om, w0, wa)

plt.figure(figsize=(10, 6))
plt.plot(z, om_z, 'b-', lw=3, label=r'Densité de Matière $\Omega_m(z)$')
plt.plot(z, ode_z, 'r-', lw=3, label=r'Densité Énergie Noire $\Omega_{DE}(z)$')

# Point de croisement (Equivalence)
idx = np.argwhere(np.diff(np.sign(om_z - ode_z))).flatten()
plt.axvline(z[idx], color='k', linestyle=':', label=f'Transition z ≈ {z[idx][0]:.2f}')

plt.xlabel('Redshift $z$', fontsize=12)
plt.ylabel('Part du budget énergétique', fontsize=12)
plt.title('Histoire du Budget Cosmique : Matière vs Énergie Noire ($\Psi$TMG)', fontsize=14)
plt.legend()
plt.grid(alpha=0.3)
plt.savefig('experiments/ultimate_test_1_nested_sampling/outputs/omega_evolution.png')
print(f"✅ Évolution des densités sauvegardée. Transition à z = {z[idx][0]:.2f}")

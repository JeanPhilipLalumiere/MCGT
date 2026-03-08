import numpy as np
import matplotlib.pyplot as plt

# Paramètres issus du Best Fit Triple Alliance
w0 = -1.4865
wa = 0.4536
z = np.linspace(0, 2.5, 100)

# Équation d'état
w_z = w0 + wa * (z / (1 + z))

plt.figure(figsize=(10, 6))

# Ligne Lambda-CDM (w = -1)
plt.axhline(-1, color='blue', linestyle='--', lw=2, label=r'$\Lambda$CDM ($w=-1$)')

# Courbe PsiTMG
plt.plot(z, w_z, color='crimson', lw=3, label=r'$\Psi$TMG ($w_0 + w_a \frac{z}{1+z}$)')

# Annotations physiques
plt.fill_between(z, -2, -1, color='gray', alpha=0.1, label='Zone Phantom')
plt.annotate('Phase Fantôme (Accélération forte)', xy=(0.5, -1.35), fontsize=10, color='crimson')
plt.annotate('Vers la Quintessence', xy=(1.5, -1.15), fontsize=10, color='crimson')

plt.xlabel('Redshift $z$', fontsize=12)
plt.ylabel('Equation d\'état $w(z)$', fontsize=12)
plt.title('Évolution Dynamique de l\'Énergie Noire ($\Psi$TMG)', fontsize=14)
plt.ylim(-1.6, -0.9)
plt.legend(loc='lower right')
plt.grid(alpha=0.3)

plt.savefig('experiments/ultimate_test_1_nested_sampling/outputs/w_z_evolution.png')
print("✅ Courbe w(z) sauvegardée : w_z_evolution.png")

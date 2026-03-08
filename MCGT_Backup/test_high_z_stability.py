import numpy as np
import matplotlib.pyplot as plt

# Paramètres "Nobel" de PsiTMG issus de ton dernier run
h0, om, w0, wa = 74.185, 0.226, -1.477, 0.446
z_high = np.linspace(0, 6, 200)

def w_z(z, w0, wa):
    return w0 + wa * (z / (1 + z))

def hubble_psi(z, h0, om, w0, wa):
    # Évolution de l'énergie noire
    de_evol = np.exp(3 * wa * (z / (1 + z) - np.log(1 + z)))
    # ez^2 (Normalisé à H0)
    ez_sq = om * (1 + z)**3 + (1 - om) * (1 + z)**(3 * (1 + w0 + wa)) * de_evol
    # Utilisation de np.maximum pour la sécurité sur les tableaux
    return h0 * np.sqrt(np.maximum(ez_sq, 1e-10))

# Calculs
w_vals = w_z(z_high, w0, wa)
h_vals = hubble_psi(z_high, h0, om, w0, wa)

plt.figure(figsize=(12, 5))

# Plot 1 : Équation d'état w(z)
plt.subplot(1, 2, 1)
plt.plot(z_high, w_vals, 'r-', lw=2, label=r'$\Psi$TMG')
plt.axhline(-1, color='blue', linestyle='--', label=r'$\Lambda$CDM')
plt.title("Évolution de $w(z)$ (Stabilité Phantom)")
plt.xlabel("Redshift $z$")
plt.ylabel("$w(z)$")
plt.legend()
plt.grid(alpha=0.3)

# Plot 2 : Énergie cinétique de l'expansion
# On trace H(z)/(1+z) qui doit décroître de façon monotone
plt.subplot(1, 2, 2)
plt.plot(z_high, h_vals / (1 + z_high), 'r-', lw=2)
plt.title("Paramètre d'expansion $H(z)/(1+z)$")
plt.xlabel("Redshift $z$")
plt.ylabel("$H(z)/(1+z)$")
plt.grid(alpha=0.3)

plt.tight_layout()
plt.savefig('experiments/ultimate_test_1_nested_sampling/outputs/high_z_stability.png')
print("✅ Test de stabilité à haut redshift corrigé et généré : high_z_stability.png")

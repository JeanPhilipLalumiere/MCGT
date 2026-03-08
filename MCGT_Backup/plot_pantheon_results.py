import pickle
import matplotlib.pyplot as plt
from dynesty import plotting as dyplot
import numpy as np

# Chargement des résultats réels
path = 'experiments/ultimate_test_1_nested_sampling/outputs/psitmg_pantheon_res.pkl'
with open(path, 'rb') as f:
    res = pickle.load(f)

print("📊 Génération du Corner Plot Pantheon+...")

# Paramètres : H0, Omega_m, w0, wa
labels = [r'$H_0$', r'$\Omega_m$', r'$w_0$', r'$w_a$']

# On ajoute les lignes de référence Lambda-CDM (70, 0.3, -1, 0)
span = [0.999 for i in range(4)] # Zoom sur les zones de haute probabilité
fig, axes = dyplot.cornerplot(res, color='royalblue', labels=labels,
                              truths=[70.0, 0.3, -1.0, 0.0], truth_color='red',
                              show_titles=True, title_fmt='.3f', quantiles=[0.16, 0.5, 0.84])

plt.savefig('experiments/ultimate_test_1_nested_sampling/outputs/corner_pantheon_real.png')
print("✅ Graphique sauvegardé : corner_pantheon_real.png")

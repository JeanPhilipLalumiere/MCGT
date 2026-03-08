import pickle
import matplotlib.pyplot as plt
from dynesty import plotting as dyplot

# Chargement des résultats Triple Alliance
with open('experiments/ultimate_test_1_nested_sampling/outputs/psitmg_triple_res.pkl', 'rb') as f:
    res = pickle.load(f)

labels = [r'$H_0$', r'$\Omega_m$', r'$w_0$', r'$w_a$']

# Configuration du plot "Nobel"
fig, axes = dyplot.cornerplot(res, color='crimson', labels=labels,
                              truths=[67.4, 0.315, -1.0, 0.0], truth_color='blue',
                              show_titles=True, title_fmt='.4f', quantiles=[0.16, 0.5, 0.84])

plt.savefig('experiments/ultimate_test_1_nested_sampling/outputs/corner_triple_nobel.png')
print("✅ Graphique de la Victoire sauvegardé : corner_triple_nobel.png")

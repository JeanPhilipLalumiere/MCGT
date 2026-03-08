import pickle
import matplotlib.pyplot as plt
from dynesty import plotting as dyplot

# Chargement du pont cosmique
with open('experiments/ultimate_test_1_nested_sampling/outputs/cosmic_bridge_res.pkl', 'rb') as f:
    res = pickle.load(f)

print("📊 Dessin du Pont Cosmique en cours...")
labels = ['H0', 'Omega_m', 'w0', 'wa']
fig, axes = dyplot.cornerplot(res, color='darkorange', labels=labels,
                              show_titles=True, title_fmt='.3f')

plt.savefig('experiments/ultimate_test_1_nested_sampling/outputs/corner_bridge.png')
print("✅ Image sauvegardée : corner_bridge.png")

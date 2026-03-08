import pickle
import matplotlib.pyplot as plt
from dynesty import plotting as dyplot

def load_res(path):
    with open(path, 'rb') as f:
        return pickle.load(f)

# Chargement du résultat de la mission Tension
res_tension = load_res('experiments/ultimate_test_1_nested_sampling/outputs/h0_tension_res.pkl')

print("📊 Génération du Corner Plot : Mission Tension H0...")

labels = ['H0', 'Omega_m', 'w0', 'wa']
fig, axes = dyplot.cornerplot(res_tension, color='darkorange', labels=labels,
                              show_titles=True, title_fmt='.3f')

plt.savefig('experiments/ultimate_test_1_nested_sampling/outputs/corner_tension.png')
print("✅ Graphique sauvegardé : experiments/ultimate_test_1_nested_sampling/outputs/corner_tension.png")

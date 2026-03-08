import pickle
import matplotlib.pyplot as plt
from dynesty import plotting as dyplot

def load_res(path):
    with open(path, 'rb') as f:
        return pickle.load(f)

# Chargement
res_psitmg = load_res('experiments/ultimate_test_1_nested_sampling/outputs/psitmg_res.pkl')

print("📊 Génération du Corner Plot pour PsiTMG...")

# Création du graphique
labels = ['H0', 'Omega_m', 'w0', 'wa']
fig, axes = dyplot.cornerplot(res_psitmg, color='blue', labels=labels,
                              show_titles=True, title_fmt='.3f')

plt.savefig('experiments/ultimate_test_1_nested_sampling/outputs/corner_psitmg.png')
print("✅ Graphique sauvegardé : experiments/ultimate_test_1_nested_sampling/outputs/corner_psitmg.png")

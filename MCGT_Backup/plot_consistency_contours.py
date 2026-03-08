import pickle
import numpy as np
import matplotlib.pyplot as plt
from dynesty import plotting as dyplot
import matplotlib.patches as mpatches

def load_res(path):
    with open(path, 'rb') as f:
        return pickle.load(f)

# Chargement des résultats
try:
    res_sne = load_res('experiments/ultimate_test_1_nested_sampling/outputs/consistency_SNe.pkl')
    res_cmb = load_res('experiments/ultimate_test_1_nested_sampling/outputs/consistency_CMB.pkl')
    res_bao = load_res('experiments/ultimate_test_1_nested_sampling/outputs/consistency_BAO.pkl')
except FileNotFoundError as e:
    print(f"Erreur : Un des fichiers .pkl est manquant. {e}")
    exit()

labels = [r'$H_0$', r'$\Omega_m$', r'$w_0$', r'$w_a$']

# Préparation de la figure
fig, axes = plt.subplots(4, 4, figsize=(15, 15))

# Superposition des contours (SNe=Gris, CMB=Bleu, BAO=Vert)
# Note: On utilise les arguments de base pour éviter les conflits de version
dyplot.cornerplot(res_sne, color='gray', labels=labels, fig=(fig, axes))
dyplot.cornerplot(res_cmb, color='blue', labels=labels, fig=(fig, axes))
dyplot.cornerplot(res_bao, color='green', labels=labels, fig=(fig, axes))

# Ajout d'une légende manuelle claire
sne_patch = mpatches.Patch(color='gray', label='Supernovae (Pantheon+)')
cmb_patch = mpatches.Patch(color='blue', label='CMB (Planck Shift)')
bao_patch = mpatches.Patch(color='green', label='BAO (eBOSS)')
fig.legend(handles=[sne_patch, cmb_patch, bao_patch], loc='upper right', bbox_to_anchor=(0.9, 0.9), fontsize=14)

plt.savefig('experiments/ultimate_test_1_nested_sampling/outputs/consistency_triple_bananas.png')
print("✅ Graphique de convergence généré avec succès : consistency_triple_bananas.png")

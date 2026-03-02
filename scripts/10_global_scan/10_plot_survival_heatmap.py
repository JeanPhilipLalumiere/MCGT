import pandas as pd
import matplotlib.pyplot as plt
import matplotlib.colors as mcolors
import numpy as np
import os

# --- CONFIGURATION DES CHEMINS ---
# Chemin vers tes données téléchargées
DATA_PATH = os.path.expanduser("~/Downloads/MCGT_Final_Results/10_mc_results.csv")
# Dossier de destination pour la figure
OUTPUT_DIR = "assets/zz-figures/10_global_scan/"
os.makedirs(OUTPUT_DIR, exist_ok=True)

def generate_heatmap():
    if not os.path.exists(DATA_PATH):
        print(f"❌ Erreur : Fichier introuvable à {DATA_PATH}")
        return

    print("⏳ Lecture des 100,000 simulations...")
    df = pd.read_csv(DATA_PATH)
    
    # On ne garde que les simulations réussies
    df = df[df['status'] == 'ok']

    # --- CRÉATION DU GRAPHIQUE ---
    plt.figure(figsize=(12, 9))
    
    # Scatter plot avec échelle logarithmique pour la couleur
    # viridis_r : le bleu/violet est pour les erreurs faibles (RG)
    # le jaune est pour les erreurs fortes (Exclusion)
    sc = plt.scatter(
        df['q0star'], 
        df['alpha'], 
        c=df['p95_20_300'], 
        cmap='viridis_r', 
        s=2, 
        alpha=0.6,
        norm=mcolors.LogNorm(vmin=1e-5, vmax=1.0)
    )

    # Ajout de la barre de couleur
    cbar = plt.colorbar(sc)
    cbar.set_label(r'Déphasage $p_{95}$ (rad) - Échelle Log', fontsize=12)

    # --- LIGNES DE RÉFÉRENCE ET ANNOTATIONS ---
    plt.axvline(x=0, color='black', linestyle='--', alpha=0.5, label='Limite RG ($q_0^* = 0$)')
    
    # Seuil critique de 0.1 rad (souvent utilisé pour la détectabilité LIGO)
    plt.annotate('ZONE D\'EXCLUSION (> 0.1 rad)', xy=(0.0006, 0.7), 
                 color='red', weight='bold', fontsize=10, bbox=dict(facecolor='white', alpha=0.7))
    
    plt.annotate('ZONE VIABLE (RG-like)', xy=(-0.0001, -0.7), 
                 color='darkgreen', weight='bold', fontsize=10, bbox=dict(facecolor='white', alpha=0.7))

    # --- COSMÉTIQUE ---
    plt.xlabel(r'Paramètre MCGT $q_0^*$', fontsize=13)
    plt.ylabel(r'Indice spectral $\alpha$', fontsize=13)
    plt.title(f'Cartographie du domaine de validité MCGT\n(Analyse globale sur {len(df):,} simulations)', fontsize=15)
    plt.grid(True, which='both', linestyle=':', alpha=0.4)

    # Sauvegarde
    save_path = os.path.join(OUTPUT_DIR, "10_survival_heatmap.png")
    plt.savefig(save_path, dpi=300, bbox_inches='tight')
    plt.close()
    
    print(f"✅ Succès ! La figure a été générée ici : {save_path}")

if __name__ == "__main__":
    generate_heatmap()

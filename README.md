# MCGT: Modèle de la Courbure Gravitationnelle du Temps
### Version 2.6.2 — "The Great Reconciliation"

![Build Status](https://img.shields.io/badge/build-passing-brightgreen)
![Version](https://img.shields.io/badge/version-v2.6.2-blue)
![License](https://img.shields.io/badge/license-MIT-green)

**MCGT** est un framework cosmologique conçu pour résoudre les tensions majeures du modèle standard $\Lambda$CDM (H0, S8, JWST) via une approche purement géométrique.

## 🌌 Ruptures Scientifiques

* **Tension de Hubble ($H_0$)** : Résolue par une réduction dynamique de l'horizon sonore ($r_s$) au découplage.
* **Anomalie JWST** : Expliquée par un boost gravitationnel du facteur de croissance $f(z)$ à $z>10$.
* **Tension $S_8$** : Amortie par une suppression de puissance aux petites échelles ($k > 1 h/Mpc$).

## 📂 Structure du Dépôt

* `manuscript/` : Contient le code source LaTeX (`main.tex`) et les 16 figures générées pour la publication.
* `scripts/` : Scripts Python de simulation et de génération de figures.
* `assets/` : Données brutes et figures intermédiaires.

## 🚀 Reproduction des Résultats

Pour régénérer l'ensemble des figures du papier :

```bash
# 1. Installer les dépendances
pip install -r requirements.txt

# 2. Lancer les scripts de génération
python3 scripts/generate_manuscript_figures_batch1.py
python3 scripts/generate_manuscript_figures_batch2.py
python3 scripts/generate_manuscript_figures_batch3.py

# 3. Compiler le manuscrit (Nécessite TeX Live)
cd manuscript
pdflatex main.tex
pdflatex main.tex
```

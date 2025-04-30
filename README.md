# MCGT — Modèle de la Courbure Gravitationnelle du Temps  
![build](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/latex.yml/badge.svg)

> **Une métrique temporelle non linéaire pour réconcilier la cosmologie
> avec les horloges de haute précision.**  
> Ce dépôt rassemble le manuscrit LaTeX, les scripts Python de génération
> des figures, et la chaîne GitHub Actions qui compile automatiquement le PDF.

---

## Sommaire
1. [Arborescence](#arborescence)
2. [Prérequis](#prérequis)
3. [Compilation LaTeX](#compilation-latex)
4. [Scripts Python](#scripts-python)
5. [Intégration Continue](#intégration-continue)
6. [Licence](#licence)
7. [Citation](#citation)
8. [Contact](#contact)

---

## Arborescence

```text
MCGT/
├── main.tex               # Manuscrit principal
├── figures/               # Figures .png générées par les scripts
├── tables/                # Tableaux LaTeX (ex. piliers.tex)
├── code/                  # Scripts Python
│   ├── plot_Pofz.py
│   ├── plot_Pofz_curve.py
│   ├── plot_PofT_curve.py
│   ├── plot_PT_derivatives.py
│   ├── plot_alpha_kappa_plane.py
│   ├── plot_kappa_constraints.py
│   ├── plot_kappa_local_limit.py
│   └── make_table_piliers.py
├── data/                  # Jeux de données brutes ou résumées
├── .github/workflows/     # CI → latex.yml
└── README.md
```

- **`main.tex`** inclut les images depuis `figures/` et le tableau `\input{tables/piliers}`.  
- Tous les graphiques sont **reproductibles** : chaque script lit `../data/` et écrit la figure dans `../figures/`.

---

## Prérequis

| Outil  | Version testée | Remarques |
|--------|----------------|-----------|
| TeX Live | ≥ 2022 | `latexmk`, `biblatex`, `siunitx`, … |
| Python | ≥ 3.8 | `numpy`, `matplotlib`, `pandas` |
| Git | ≥ 2.30 | pour cloner / contribuer |

> **Windows :** installez TeX Live (ou MiKTeX) et Python via Anaconda ou le Store.

---

## Compilation LaTeX

```bash
# Clone du dépôt
git clone https://github.com/JeanPhilipLalumiere/MCGT.git
cd MCGT

# Compilation PDF
latexmk -pdf -interaction=nonstopmode main.tex
```

Le PDF final apparaît dans le dossier courant (`main.pdf`).  
Les avertissements *Overfull/Underfull \hbox* sont bénins ; les erreurs stopperaient la compilation.

---

## Scripts Python

```bash
cd code
python plot_Pofz.py              # génère figures/Pofz_log.png
python plot_alpha_kappa_plane.py # etc.
```

Chaque script :

1. charge les données dans `../data/` ;
2. produit une figure (.png, 300 dpi) dans `../figures/` ;
3. peut être lancé indépendamment.

---

## Intégration Continue

Le workflow **GitHub Actions** (`.github/workflows/latex.yml`) :

1. se déclenche à chaque *push* ou *pull request* ;
2. compile `main.tex` sous Ubuntu via [`xu-cheng/latex-action`](https://github.com/xu-cheng/latex-action) ;
3. publie le PDF comme artefact téléchargeable.

Le badge en tête de ce README reflète l’état de la dernière compilation.

---

## Licence

Ce dépôt est sous licence **MIT** (voir le fichier [`LICENSE`](LICENSE)) ;  
vous pouvez réutiliser le code et le manuscrit en conservant l’attribution.

---

## Citation

```bibtex
@misc{Lalumiere2024MCGT,
  author       = {Jean-Philip Lalumière},
  title        = {Modèle de la Courbure Gravitationnelle du Temps (MCGT)},
  year         = {2024},
  howpublished = {\url{https://github.com/JeanPhilipLalumiere/MCGT}},
  note         = {v1.0.0}
}
```

---

## Contact

- **Auteur :** Jean‑Philip Lalumière  
- **Mail :** <contact@jeanphiliplalumiere.com>  
- **Issues :** utilisez l’onglet *Issues* pour signaler un problème ou proposer une amélioration.
=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
   README  –  Reproductibilité des figures et tableaux du manuscrit
=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=

1. PRÉREQUIS
------------
• Python ≥ 3.8
• Bibliothèques :  numpy, matplotlib

Création d’un environnement minimal :

    python -m venv venv
    source venv/bin/activate            # sous Windows : venv\Scripts\activate
    pip install numpy matplotlib


2. ORGANISATION DES DOSSIERS
----------------------------
<racine du projet>/
 ├── figures/           ← images générées (PNG ou PDF) utilisées par LaTeX
 ├── tables/            ← tables LaTeX générées automatiquement (*.tex)
 ├── data/              ← jeux de données CSV optionnels (peut rester vide)
 └── code/              ← scripts ci-dessous
      ├── make_table_piliers.py
      ├── plot_alpha_kappa_plane.py
      ├── plot_kappa_constraints.py
      ├── plot_kappa_local_limit.py
      ├── plot_PofT_curve.py
      ├── plot_Pofz_curve.py
      ├── plot_Pofz.py
      └── plot_PT_derivatives.py


3. RAPPORT SCRIPT ↔ FIGURE / TABLE
----------------------------------

| Script (code/)                  | Produit (chemin relatif)               |
|---------------------------------|----------------------------------------|
| plot_Pofz.py                    | figures/Pofz_log.png                  |
| plot_Pofz_curve.py              | figures/Pofz_curve.png                |
| plot_PofT_curve.py              | figures/PofT_curve.png                |
| plot_PT_derivatives.py          | figures/PT_derivatives.png            |
| plot_alpha_kappa_plane.py       | figures/alpha_kappa_plane.png         |
| plot_kappa_constraints.py       | figures/kappa_constraints.png         |
| plot_kappa_local_limit.py       | figures/kappa_local_limit.png         |
| make_table_piliers.py           | tables/piliers.tex                    |


4. DONNÉES OPTIONNELLES
-----------------------
Certains scripts peuvent lire des fichiers CSV placés dans `data/` :

• **alpha_kappa_plane.py**  
  lit `data/alpha_kappa_data.csv`  
  (colonnes : source,alpha,kappa,err_low,err_up)

• **plot_kappa_constraints.py**  
  lit `data/kappa_limits.csv`  
  (colonnes : PTA,kappa,err)

• **plot_kappa_local_limit.py**  
  lit `data/kappa_theory.csv` et/ou `data/kappa_limit.csv`  
  (un seul enregistrement : kappa,err_low,err_up[,label])

Si ces fichiers sont absents, des valeurs par défaut intégrées au script
sont utilisées ; les figures se génèrent quand même.


5. COMMENT (RE)GÉNÉRER TOUTES LES FIGURES
-----------------------------------------

Depuis la racine du projet :

    cd code
    python plot_Pofz.py
    python plot_Pofz_curve.py
    python plot_PofT_curve.py
    python plot_PT_derivatives.py
    python plot_alpha_kappa_plane.py
    python plot_kappa_constraints.py
    python plot_kappa_local_limit.py
    python make_table_piliers.py

Les images apparaissent dans `../figures/` et la table LaTeX dans
`../tables/`.  Recompilez ensuite le manuscrit :

    latexmk -pdf main.tex          # ou simplement « Recompile » sur Overleaf

6. LICENCE
----------
Scripts et jeux de données fournis sous licence **MIT** (voir HEADER
dans chaque fichier).  Les données externes conservent la licence de
leur source (NANOGrav, JWST, etc.).

=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=

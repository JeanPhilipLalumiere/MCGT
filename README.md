# Ψ-Time Metric Gravity (ΨTMG): A Metric-Coupled Resolution to Cosmological Tensions
### Version 3.3.0 — "The BHS & Microphysics Update"

![Build Status](https://img.shields.io/badge/build-passing-brightgreen)
![Version](https://img.shields.io/badge/version-v3.3.0-blue)
![License](https://img.shields.io/badge/license-MIT-green)

**Ψ-Time Metric Gravity** (Metric-Coupled Gravity Theory) est le framework théorique fondamental. **ΨTMG** est sa réalisation cosmologique paramétrée, conçue pour résoudre les tensions majeures du modèle standard $\Lambda$CDM ($H_0$, $S_8$, JWST) via une approche purement géométrique.

## Nouveautés v3.3.0
Cette release consolide la baseline statistique v3.2.0 tout en ajoutant la justification micro-physique TIDE et l'infrastructure de déploiement pour les environnements Ubuntu 24.04 LTS.
* **Model Selection :** Intégration du calcul des critères d'information (AIC/BIC) prouvant mathématiquement la rentabilité de la dynamique du modèle.
* **Prédictions JWST :** Exportation des courbes théoriques falsifiables de l'évolution structurelle ($z=0$ à $z=20$).
* **Peer-Review Ready :** Mise en place d'un pipeline de reproductibilité totale (1-click script) avec dépendances figées.
* **Microphysics Note :** Archivage de l'exploration TIDE comme motivation viscoélastique du couplage métrique, sans remplacer la baseline CPL de production.
* **BHS Deployment Support :** Ajout d'un script de déploiement Kimsufi/Beauharnois et d'un check de performance Sentinel pour qualifier rapidement une machine vierge.

## Key Results (MCMC Best-Fit)
Le scan MCMC global (Pantheon+, BAO, CMB, RSD) brise les dégénérescences classiques :
* **$\Omega_m$** = 0.243 ± 0.007
* **$H_0$** = 72.97 (+0.32 / -0.30) km/s/Mpc
* **$w_0$** = -0.69 ± 0.05
* **$w_a$** = -2.81 (+0.29 / -0.14)
* **$S_8$** = 0.718 ± 0.030

## Model Selection and Information Criteria
Le modèle ΨTMG surpasse drastiquement la pénalité de complexité (Occam's razor). Pour un total de 1718 points de données, l'amélioration par rapport au modèle standard $\Lambda$CDM est qualifiée de "preuve décisive" sur l'échelle de Jeffreys ($\Delta\text{BIC} \ll -10$).

```text
=== Information Criteria ===
k (params libres)        5
n (donnees totales)      1718
AIC                      809.12
BIC                      836.37

```

*(Amélioration globale : $\Delta\chi^2$ = -151.6 | $\Delta$AIC = -145.6 | $\Delta$BIC = -129.2)*

## Note Théorique: Micro-Physique TIDE
Bien que la $\Psi$TMG soit actuellement formulée comme une théorie des champs effective (EFT), les tests menés en v3.2.1 suggèrent qu'un mécanisme de torsion inertielle (type TIDE) pourrait constituer l'origine microscopique du couplage métrique observé, bien que la paramétrisation actuelle nécessite une généralisation pour atteindre la précision statistique de la $\Psi$TMG.

Benchmark de contrôle:
* **$\Psi$TMG v3.2.0 (baseline CPL)** : $\Delta\chi^2 = -151.6$, $H_0 = 72.97$, $S_8 = 0.718$.
* **TIDE v3.2.1 (archive de recherche)** : $\Delta\chi^2 \approx -55.6$, $H_0 \approx 74.11$, $S_8 \approx 0.740$.

La baseline de production reste donc $\Psi$TMG v3.2.0, tandis que la branche `v3.2.1-tide-integration` est conservée comme archive théorique et méthodologique.

## Infrastructure et Déploiement

La release `v3.3.0` introduit une infrastructure de déploiement minimale pour les serveurs Kimsufi BHS sous Ubuntu 24.04 LTS.

* `deploy_kimsufi_bhs.sh` : installation "un-clic" des dépendances système, environnement Python, clonage du dépôt et compilation optionnelle de CLASS.
* `check_bhs_performance.py` : benchmark rapide de la likelihood Sentinel avant un run MCMC long.

Exemple:

```bash
chmod +x deploy_kimsufi_bhs.sh
./deploy_kimsufi_bhs.sh
python check_bhs_performance.py
```

## Ruptures Scientifiques

* **Tension de Hubble ($H_0$)** : Résolue par une réduction dynamique de l'horizon sonore ($r_s$) au découplage, sans détériorer le spectre CMB ($\chi^2_{CMB}$ = 0.04).
* **Anomalie JWST** : Expliquée par un "boost gravitationnel" géométrique de la croissance des structures linéaires à haut redshift ($z > 10$).
* **Tension $S_8$** : Amortie organiquement par l'évolution dynamique de l'équation d'état, réconciliant les données d'expansion avec le cisaillement gravitationnel (Weak Lensing).

## Structure du Dépôt

* `manuscript/` : Contient le code source LaTeX (`main.tex`) de la publication (v3.2.0).
* `scripts/` : Scripts Python d'utilitaires (ex: `export_predictions.py` générant les tableaux de données JWST).
* `output/` : Contient les chaînes MCMC HDF5, le tableau CSV des prédictions et les Corner Plots générés.
* `reproduce_paper_results.sh` : Le pipeline automatisé principal.

## Reproduction des Résultats (Peer-Review Ready)

Pour garantir une transparence et une reproductibilité indépendantes, un script d'exécution unifié est fourni. Il installe l'environnement exact, relance l'inférence MCMC et régénère les figures de la publication.

```bash
# 1. Rendre le script exécutable (Linux/Mac)
chmod +x reproduce_paper_results.sh

# 2. Lancer le pipeline complet
./reproduce_paper_results.sh full

# Alternative : lancer un test rapide pour valider l'architecture
./reproduce_paper_results.sh test

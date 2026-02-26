# Ψ-Time Metric Gravity (ΨTMG): A Metric-Coupled Resolution to Cosmological Tensions
### Version 3.1.0 — "The Great Reconciliation"

![Build Status](https://img.shields.io/badge/build-passing-brightgreen)
![Version](https://img.shields.io/badge/version-v3.1.0-blue)
![License](https://img.shields.io/badge/license-MIT-green)

**Ψ-Time Metric Gravity** (Metric-Coupled Gravity Theory) est le framework théorique fondamental. **ΨTMG** est sa réalisation cosmologique paramétrée, conçue pour résoudre les tensions majeures du modèle standard $\Lambda$CDM ($H_0$, $S_8$, JWST) via une approche purement géométrique.

## Nouveautés v3.1.0
Cette release majeure officialise l'identité finale **Ψ-Time Metric Gravity (ΨTMG)**, validée observationnellement et statistiquement supérieure à $\Lambda$CDM.
* **Model Selection :** Intégration du calcul des critères d'information (AIC/BIC) prouvant mathématiquement la rentabilité de la dynamique du modèle.
* **Prédictions JWST :** Exportation des courbes théoriques falsifiables de l'évolution structurelle ($z=0$ à $z=20$).
* **Peer-Review Ready :** Mise en place d'un pipeline de reproductibilité totale (1-click script) avec dépendances figées.

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

## Ruptures Scientifiques

* **Tension de Hubble ($H_0$)** : Résolue par une réduction dynamique de l'horizon sonore ($r_s$) au découplage, sans détériorer le spectre CMB ($\chi^2_{CMB}$ = 0.04).
* **Anomalie JWST** : Expliquée par un "boost gravitationnel" géométrique de la croissance des structures linéaires à haut redshift ($z > 10$).
* **Tension $S_8$** : Amortie organiquement par l'évolution dynamique de l'équation d'état, réconciliant les données d'expansion avec le cisaillement gravitationnel (Weak Lensing).

## Structure du Dépôt

* `manuscript/` : Contient le code source LaTeX (`main.tex`) de la publication (v3.1.0).
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

<!-- BEGIN BADGES -->
[![Docs](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/docs.yml/badge.svg)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/docs.yml)
[![CodeQL](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/codeql.yml/badge.svg)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/codeql.yml)
[![Release](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/release-publish.yml/badge.svg)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/release-publish.yml)
[![CI accel](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/ci-accel.yml/badge.svg)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/ci-accel.yml)
<!-- END BADGES -->

[![ci-pre-commit](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/ci-pre-commit.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/ci-pre-commit.yml)
[![sanity-main](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-main.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-main.yml)
# Modèle de Courbure Gravitationnelle Temporelle (MCGT)
## Résumé
MCGT est un corpus structuré en chapitres, accompagné de scripts, données, figures et manifestes assurant la reproductibilité.


### CI (Workflows canoniques)

[![sanity-main](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-main.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-main.yml)
[![sanity-echo](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-echo.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-echo.yml)
[![ci-yaml-check](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/ci-yaml-check.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/ci-yaml-check.yml)

- **sanity-main.yml** : diag quotidien / dispatch / push (artefacts)
- **sanity-echo.yml** : smoke déclenchable manuellement
- **ci-yaml-check.yml** : lint/validité YAML

Voir `docs/CI.md`.
 chapitres (conceptuel + détails) accompagné d’un ensemble de scripts, données, figures et manifestes pour assurer la reproductibilité complète (génération des données, tracés, contrôles de cohérence). Ce README dresse l’index des ressources, précise les points d’entrée (runbook, Makefile, configs) et documente les conventions.
## Sommaire
1. Arborescence du projet
2. Contenu des chapitres (LaTeX)
3. Configurations & package Python
4. Données (zz-data/)
5. Scripts (zz-scripts/)
6. Figures (zz-figures/)
7. Manifests & repro (zz-manifests/, README-REPRO.md, RUNBOOK.md)
8. Conventions & styles (conventions.md)
9. Environnements & dépendances (requirements.txt, environment.yml)

## 1) Arborescence du projet
Racine :
* main.tex — Document LaTeX principal.

## 2) Contenu des chapitres (LaTeX)
Chaque dossier de chapitre contient :
* <prefix>\_conceptuel.tex
* <prefix>\_details.tex (ou \_calibration\_conceptuel.tex pour le chap. 1)
* CHAPTERXX\_GUIDE.txt (notes, exigences, jalons spécifiques)
* Chapitre 1 – Introduction conceptuelle

## 3) Configurations & package Python
* zz-configuration/mcgt-global-config.ini : paramètres transverses (chemins de données/figures, tolérances, seeds, options graphiques, etc.).
* zz-configuration/\*.ini spécifiques (ex. camb\_exact\_plateau.ini, scalar\_perturbations.ini, gw\_phase.ini).
* zz-configuration/GWTC-3-confident-events.json ; zz-configuration/pdot\_plateau\_vs\_z.dat ; zz-configuration/meta\_template.json ; zz-configuration/mcgt-global-config.ini.template ; zz-configuration/README.md.
* mcgt/ : API Python interne (ex. calculs de phase, solveurs de perturbations, backends de référence). mcgt/backends/ref\_phase.py fournit la phase de ref.
* mcgt/CHANGELOG.md ; mcgt/pyproject.toml.
---
## 4) Données (zz-data/)
Organisation par chapitre, exemples (liste non exhaustive) :
* zz-data/chapter…

## 5) Scripts (zz-scripts/)
Chaque chapitre dispose de générateurs de données generate\_data\_chapterXX.py et de traceurs plot\_fig\*.py. Exemples :
* zz-scripts/chapter…

## 6) Figures (zz-figures/)
Par chapitre : fig\_\*.png (noms explicites, FR).
* chapitres

## 7) Manifests & repro
* zz-manifests/manifest\_master.json — inventaire complet (source maître).
* zz-manifests/manifest\_publication.json — sous-ensemble pour remise publique.
* zz-manifests/manifest\_report.json — rapport généré par diag\_consistency.py.
* zz-manifests/manifest\_report.md — rapport lisible.
* zz-manifests/figure\_manifest.csv — index des figures.
* zz-manifests/add\_to\_manifest.py ; zz-manifests/migration\_map.json.
* zz-manifests/meta\_template.json — gabarit de métadonnées (source maître).
* zz-manifests/README\_manifest.md — documentation manifeste.
* zz-manifests/diag\_consistency.py — diagnostic (présence/format/empreintes).
* zz-manifests/chapters/chapter\_manifest\_{

## 8) Conventions & styles
* conventions.md : normes de nommage (FR), unités (SI), précision numérique, format CSV/DAT/JSON, styles de figures, seuils de QA, sémantique des colonnes, règles pour jalons et classes (primaire/ordre2), etc.
* Cohérence inter-chapitres : les paramètres transverses (p. ex. alpha, q

## 9) Environnements & dépendances
* Python ≥ 3.1

## 1

## 11) Licence / Contact
* Licence : à préciser (interne / publique) — voir fichier LICENSE.
* Contact scientifique : responsable MCGT.
* Contact technique : mainteneur des scripts / CI.










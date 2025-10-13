<!-- BEGIN BADGES -->
[![Docs](https://github.com/%s/actions/workflows/docs.yml/badge.svg)](https://github.com/%s/actions/workflows/docs.yml)
JeanPhilipLalumiere/MCGT
JeanPhilipLalumiere/MCGT
[![CodeQL](https://github.com/%s/actions/workflows/codeql.yml/badge.svg)](https://github.com/%s/actions/workflows/codeql.yml)
JeanPhilipLalumiere/MCGT
JeanPhilipLalumiere/MCGT
[![Release](https://github.com/%s/actions/workflows/release-publish.yml/badge.svg)](https://github.com/%s/actions/workflows/release-publish.yml)
JeanPhilipLalumiere/MCGT
JeanPhilipLalumiere/MCGT
[![CI accel](https://github.com/%s/actions/workflows/ci-accel.yml/badge.svg)](https://github.com/%s/actions/workflows/ci-accel.yml)
JeanPhilipLalumiere/MCGT
JeanPhilipLalumiere/MCGT
<!-- END BADGES -->

[![ci-pre-commit](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/ci-pre-commit.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/ci-pre-commit.yml)
[![sanity-main](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-main.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-main.yml)

# Modèle de Courbure Gravitationnelle Temporelle (MCGT)
## Résumé
MCGT est un corpus de 1<!-- CI:BEGIN -->
### CI (Workflows canoniques)

[![sanity-main](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-main.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-main.yml)
[![sanity-echo](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-echo.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-echo.yml)
[![ci-yaml-check](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/ci-yaml-check.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/ci-yaml-check.yml)

- **sanity-main.yml** : diag quotidien / dispatch / push (artefacts)
- **sanity-echo.yml** : smoke déclenchable manuellement
- **ci-yaml-check.yml** : lint/validité YAML

Voir `docs/CI.md`.
<!-- CI:END --> chapitres (conceptuel + détails) accompagné d’un ensemble de scripts, données, figures et manifestes pour assurer la reproductibilité complète (génération des données, tracés, contrôles de cohérence). Ce README dresse l’index des ressources, précise les points d’entrée (runbook, Makefile, configs) et documente les conventions.
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
1<!-- CI:BEGIN -->
### CI (Workflows canoniques)

[![sanity-main](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-main.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-main.yml)
[![sanity-echo](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-echo.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-echo.yml)
[![ci-yaml-check](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/ci-yaml-check.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/ci-yaml-check.yml)

- **sanity-main.yml** : diag quotidien / dispatch / push (artefacts)
- **sanity-echo.yml** : smoke déclenchable manuellement
- **ci-yaml-check.yml** : lint/validité YAML

Voir `docs/CI.md`.
<!-- CI:END -->. Commandes utiles (Makefile) & contrôle de cohérence
11. Licence / Contact
12. Historique / Notes
---
## 1) Arborescence du projet
Racine :
* main.tex — Document LaTeX principal (compile les 1<!-- CI:BEGIN -->
### CI (Workflows canoniques)

[![sanity-main](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-main.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-main.yml)
[![sanity-echo](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-echo.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-echo.yml)
[![ci-yaml-check](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/ci-yaml-check.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/ci-yaml-check.yml)

- **sanity-main.yml** : diag quotidien / dispatch / push (artefacts)
- **sanity-echo.yml** : smoke déclenchable manuellement
- **ci-yaml-check.yml** : lint/validité YAML

Voir `docs/CI.md`.
<!-- CI:END --> chapitres).
* references.bib — Bibliographie BibTeX.
* README.md — Présent fichier d’accueil.
* README-REPRO.md — Guide de reproductibilité pas-à-pas.
* RUNBOOK.md — Procédures opératoires (exécution standard / QA).
* Makefile — Cibles de génération (données, figures, PDF, QA).
* setup.py — (si packaging local du module mcgt).
* requirements.txt — Dépendances Python (pip).
* environment.yml — Environnement Conda (optionnel).
* conventions.md — Convention de nommage / unités / style (référence).
* LICENSE — Licence du projet.
* .pre-commit-config.yaml — Hooks de qualité (format/linters).
  Chapitres (dossiers LaTeX) :
* <!-- CI:BEGIN -->
### CI (Workflows canoniques)

[![sanity-main](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-main.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-main.yml)
[![sanity-echo](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-echo.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-echo.yml)
[![ci-yaml-check](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/ci-yaml-check.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/ci-yaml-check.yml)

- **sanity-main.yml** : diag quotidien / dispatch / push (artefacts)
- **sanity-echo.yml** : smoke déclenchable manuellement
- **ci-yaml-check.yml** : lint/validité YAML

Voir `docs/CI.md`.
<!-- CI:END -->1-introduction-applications/
* <!-- CI:BEGIN -->
### CI (Workflows canoniques)

[![sanity-main](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-main.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-main.yml)
[![sanity-echo](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-echo.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-echo.yml)
[![ci-yaml-check](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/ci-yaml-check.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/ci-yaml-check.yml)

- **sanity-main.yml** : diag quotidien / dispatch / push (artefacts)
- **sanity-echo.yml** : smoke déclenchable manuellement
- **ci-yaml-check.yml** : lint/validité YAML

Voir `docs/CI.md`.
<!-- CI:END -->2-validation-chronologique/
* <!-- CI:BEGIN -->
### CI (Workflows canoniques)

[![sanity-main](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-main.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-main.yml)
[![sanity-echo](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-echo.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-echo.yml)
[![ci-yaml-check](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/ci-yaml-check.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/ci-yaml-check.yml)

- **sanity-main.yml** : diag quotidien / dispatch / push (artefacts)
- **sanity-echo.yml** : smoke déclenchable manuellement
- **ci-yaml-check.yml** : lint/validité YAML

Voir `docs/CI.md`.
<!-- CI:END -->3-stabilite-fR/
* <!-- CI:BEGIN -->
### CI (Workflows canoniques)

[![sanity-main](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-main.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-main.yml)
[![sanity-echo](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-echo.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-echo.yml)
[![ci-yaml-check](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/ci-yaml-check.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/ci-yaml-check.yml)

- **sanity-main.yml** : diag quotidien / dispatch / push (artefacts)
- **sanity-echo.yml** : smoke déclenchable manuellement
- **ci-yaml-check.yml** : lint/validité YAML

Voir `docs/CI.md`.
<!-- CI:END -->4-invariants-adimensionnels/
* <!-- CI:BEGIN -->
### CI (Workflows canoniques)

[![sanity-main](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-main.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-main.yml)
[![sanity-echo](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-echo.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-echo.yml)
[![ci-yaml-check](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/ci-yaml-check.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/ci-yaml-check.yml)

- **sanity-main.yml** : diag quotidien / dispatch / push (artefacts)
- **sanity-echo.yml** : smoke déclenchable manuellement
- **ci-yaml-check.yml** : lint/validité YAML

Voir `docs/CI.md`.
<!-- CI:END -->5-nucleosynthese-primordiale/
* <!-- CI:BEGIN -->
### CI (Workflows canoniques)

[![sanity-main](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-main.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-main.yml)
[![sanity-echo](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-echo.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-echo.yml)
[![ci-yaml-check](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/ci-yaml-check.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/ci-yaml-check.yml)

- **sanity-main.yml** : diag quotidien / dispatch / push (artefacts)
- **sanity-echo.yml** : smoke déclenchable manuellement
- **ci-yaml-check.yml** : lint/validité YAML

Voir `docs/CI.md`.
<!-- CI:END -->6-rayonnement-cmb/
* <!-- CI:BEGIN -->
### CI (Workflows canoniques)

[![sanity-main](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-main.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-main.yml)
[![sanity-echo](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-echo.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-echo.yml)
[![ci-yaml-check](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/ci-yaml-check.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/ci-yaml-check.yml)

- **sanity-main.yml** : diag quotidien / dispatch / push (artefacts)
- **sanity-echo.yml** : smoke déclenchable manuellement
- **ci-yaml-check.yml** : lint/validité YAML

Voir `docs/CI.md`.
<!-- CI:END -->7-perturbations-scalaires/
* <!-- CI:BEGIN -->
### CI (Workflows canoniques)

[![sanity-main](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-main.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-main.yml)
[![sanity-echo](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-echo.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-echo.yml)
[![ci-yaml-check](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/ci-yaml-check.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/ci-yaml-check.yml)

- **sanity-main.yml** : diag quotidien / dispatch / push (artefacts)
- **sanity-echo.yml** : smoke déclenchable manuellement
- **ci-yaml-check.yml** : lint/validité YAML

Voir `docs/CI.md`.
<!-- CI:END -->8-couplage-sombre/
* <!-- CI:BEGIN -->
### CI (Workflows canoniques)

[![sanity-main](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-main.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-main.yml)
[![sanity-echo](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-echo.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-echo.yml)
[![ci-yaml-check](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/ci-yaml-check.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/ci-yaml-check.yml)

- **sanity-main.yml** : diag quotidien / dispatch / push (artefacts)
- **sanity-echo.yml** : smoke déclenchable manuellement
- **ci-yaml-check.yml** : lint/validité YAML

Voir `docs/CI.md`.
<!-- CI:END -->9-phase-ondes-gravitationnelles/
* 1<!-- CI:BEGIN -->
### CI (Workflows canoniques)

[![sanity-main](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-main.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-main.yml)
[![sanity-echo](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-echo.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-echo.yml)
[![ci-yaml-check](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/ci-yaml-check.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/ci-yaml-check.yml)

- **sanity-main.yml** : diag quotidien / dispatch / push (artefacts)
- **sanity-echo.yml** : smoke déclenchable manuellement
- **ci-yaml-check.yml** : lint/validité YAML

Voir `docs/CI.md`.
<!-- CI:END -->-monte-carlo-global-8d/
  Code source (package) :
* mcgt/ — Module Python (API interne).
  * scalar\_perturbations.py
  * phase.py
  * **init**.py
  * backends/ref\_phase.py
  * CHANGELOG.md
  * pyproject.toml
  Configurations :
* zz-configuration/
  * mcgt-global-config.ini — Configuration globale (référence).
  * mcgt-global-config.ini.template
  * camb\_exact\_plateau.ini
  * gw\_phase.ini
  * scalar\_perturbations.ini
  * GWTC-3-confident-events.json
  * pdot\_plateau\_vs\_z.dat
  * meta\_template.json — (référence croisée avec zz-manifests/)
  * README.md
  Données :
* zz-data/chapter{<!-- CI:BEGIN -->
### CI (Workflows canoniques)

[![sanity-main](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-main.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-main.yml)
[![sanity-echo](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-echo.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-echo.yml)
[![ci-yaml-check](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/ci-yaml-check.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/ci-yaml-check.yml)

- **sanity-main.yml** : diag quotidien / dispatch / push (artefacts)
- **sanity-echo.yml** : smoke déclenchable manuellement
- **ci-yaml-check.yml** : lint/validité YAML

Voir `docs/CI.md`.
<!-- CI:END -->1..1<!-- CI:BEGIN -->
### CI (Workflows canoniques)

[![sanity-main](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-main.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-main.yml)
[![sanity-echo](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-echo.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-echo.yml)
[![ci-yaml-check](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/ci-yaml-check.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/ci-yaml-check.yml)

- **sanity-main.yml** : diag quotidien / dispatch / push (artefacts)
- **sanity-echo.yml** : smoke déclenchable manuellement
- **ci-yaml-check.yml** : lint/validité YAML

Voir `docs/CI.md`.
<!-- CI:END -->}/ — Données structurées par chapitre (CSV/DAT/JSON).
  Figures :
* zz-figures/chapter{<!-- CI:BEGIN -->
### CI (Workflows canoniques)

[![sanity-main](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-main.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-main.yml)
[![sanity-echo](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-echo.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-echo.yml)
[![ci-yaml-check](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/ci-yaml-check.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/ci-yaml-check.yml)

- **sanity-main.yml** : diag quotidien / dispatch / push (artefacts)
- **sanity-echo.yml** : smoke déclenchable manuellement
- **ci-yaml-check.yml** : lint/validité YAML

Voir `docs/CI.md`.
<!-- CI:END -->1..1<!-- CI:BEGIN -->
### CI (Workflows canoniques)

[![sanity-main](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-main.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-main.yml)
[![sanity-echo](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-echo.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-echo.yml)
[![ci-yaml-check](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/ci-yaml-check.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/ci-yaml-check.yml)

- **sanity-main.yml** : diag quotidien / dispatch / push (artefacts)
- **sanity-echo.yml** : smoke déclenchable manuellement
- **ci-yaml-check.yml** : lint/validité YAML

Voir `docs/CI.md`.
<!-- CI:END -->}/ — Figures générées (PNG).
  Scripts & outils :
* zz-scripts/chapter{<!-- CI:BEGIN -->
### CI (Workflows canoniques)

[![sanity-main](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-main.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-main.yml)
[![sanity-echo](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-echo.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-echo.yml)
[![ci-yaml-check](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/ci-yaml-check.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/ci-yaml-check.yml)

- **sanity-main.yml** : diag quotidien / dispatch / push (artefacts)
- **sanity-echo.yml** : smoke déclenchable manuellement
- **ci-yaml-check.yml** : lint/validité YAML

Voir `docs/CI.md`.
<!-- CI:END -->1..1<!-- CI:BEGIN -->
### CI (Workflows canoniques)

[![sanity-main](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-main.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-main.yml)
[![sanity-echo](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-echo.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-echo.yml)
[![ci-yaml-check](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/ci-yaml-check.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/ci-yaml-check.yml)

- **sanity-main.yml** : diag quotidien / dispatch / push (artefacts)
- **sanity-echo.yml** : smoke déclenchable manuellement
- **ci-yaml-check.yml** : lint/validité YAML

Voir `docs/CI.md`.
<!-- CI:END -->}/ — Scripts de génération & tracé.
* zz-scripts/chapter<!-- CI:BEGIN -->
### CI (Workflows canoniques)

[![sanity-main](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-main.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-main.yml)
[![sanity-echo](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-echo.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-echo.yml)
[![ci-yaml-check](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/ci-yaml-check.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/ci-yaml-check.yml)

- **sanity-main.yml** : diag quotidien / dispatch / push (artefacts)
- **sanity-echo.yml** : smoke déclenchable manuellement
- **ci-yaml-check.yml** : lint/validité YAML

Voir `docs/CI.md`.
<!-- CI:END -->3/utils/ — Utilitaires (ex. conversion jalons).
* zz-scripts/chapter<!-- CI:BEGIN -->
### CI (Workflows canoniques)

[![sanity-main](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-main.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-main.yml)
[![sanity-echo](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-echo.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-echo.yml)
[![ci-yaml-check](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/ci-yaml-check.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/ci-yaml-check.yml)

- **sanity-main.yml** : diag quotidien / dispatch / push (artefacts)
- **sanity-echo.yml** : smoke déclenchable manuellement
- **ci-yaml-check.yml** : lint/validité YAML

Voir `docs/CI.md`.
<!-- CI:END -->7/tests/ — Tests dédiés chapitre 7.
* zz-scripts/chapter<!-- CI:BEGIN -->
### CI (Workflows canoniques)

[![sanity-main](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-main.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-main.yml)
[![sanity-echo](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-echo.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-echo.yml)
[![ci-yaml-check](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/ci-yaml-check.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/ci-yaml-check.yml)

- **sanity-main.yml** : diag quotidien / dispatch / push (artefacts)
- **sanity-echo.yml** : smoke déclenchable manuellement
- **ci-yaml-check.yml** : lint/validité YAML

Voir `docs/CI.md`.
<!-- CI:END -->7/utils/ — Utilitaires (k-grid, toy\_model).
* zz-scripts/chapter<!-- CI:BEGIN -->
### CI (Workflows canoniques)

[![sanity-main](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-main.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-main.yml)
[![sanity-echo](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-echo.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-echo.yml)
[![ci-yaml-check](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/ci-yaml-check.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/ci-yaml-check.yml)

- **sanity-main.yml** : diag quotidien / dispatch / push (artefacts)
- **sanity-echo.yml** : smoke déclenchable manuellement
- **ci-yaml-check.yml** : lint/validité YAML

Voir `docs/CI.md`.
<!-- CI:END -->8/utils/ — Utilitaires (extractions BAO/SN).
* zz-scripts/manifest\_tools/ — Outils manifeste.
  * populate\_manifest.py, verify\_manifest.py
  Manifests & diagnostics :
* zz-manifests/
  * manifest\_master.json
  * manifest\_publication.json (et éventuellement .bak)
  * manifest\_report.json
  * manifest\_report.md
  * figure\_manifest.csv
  * add\_to\_manifest.py
  * migration\_map.json
  * meta\_template.json
  * README\_manifest.md
  * diag\_consistency.py
  * chapters/
    * chapter\_manifest\_<!-- CI:BEGIN -->
### CI (Workflows canoniques)

[![sanity-main](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-main.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-main.yml)
[![sanity-echo](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-echo.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-echo.yml)
[![ci-yaml-check](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/ci-yaml-check.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/ci-yaml-check.yml)

- **sanity-main.yml** : diag quotidien / dispatch / push (artefacts)
- **sanity-echo.yml** : smoke déclenchable manuellement
- **ci-yaml-check.yml** : lint/validité YAML

Voir `docs/CI.md`.
<!-- CI:END -->1.json
    * chapter\_manifest\_<!-- CI:BEGIN -->
### CI (Workflows canoniques)

[![sanity-main](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-main.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-main.yml)
[![sanity-echo](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-echo.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-echo.yml)
[![ci-yaml-check](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/ci-yaml-check.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/ci-yaml-check.yml)

- **sanity-main.yml** : diag quotidien / dispatch / push (artefacts)
- **sanity-echo.yml** : smoke déclenchable manuellement
- **ci-yaml-check.yml** : lint/validité YAML

Voir `docs/CI.md`.
<!-- CI:END -->2.json
    * chapter\_manifest\_<!-- CI:BEGIN -->
### CI (Workflows canoniques)

[![sanity-main](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-main.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-main.yml)
[![sanity-echo](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-echo.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-echo.yml)
[![ci-yaml-check](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/ci-yaml-check.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/ci-yaml-check.yml)

- **sanity-main.yml** : diag quotidien / dispatch / push (artefacts)
- **sanity-echo.yml** : smoke déclenchable manuellement
- **ci-yaml-check.yml** : lint/validité YAML

Voir `docs/CI.md`.
<!-- CI:END -->3.json
    * chapter\_manifest\_<!-- CI:BEGIN -->
### CI (Workflows canoniques)

[![sanity-main](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-main.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-main.yml)
[![sanity-echo](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-echo.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-echo.yml)
[![ci-yaml-check](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/ci-yaml-check.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/ci-yaml-check.yml)

- **sanity-main.yml** : diag quotidien / dispatch / push (artefacts)
- **sanity-echo.yml** : smoke déclenchable manuellement
- **ci-yaml-check.yml** : lint/validité YAML

Voir `docs/CI.md`.
<!-- CI:END -->4.json
    * chapter\_manifest\_<!-- CI:BEGIN -->
### CI (Workflows canoniques)

[![sanity-main](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-main.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-main.yml)
[![sanity-echo](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-echo.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-echo.yml)
[![ci-yaml-check](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/ci-yaml-check.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/ci-yaml-check.yml)

- **sanity-main.yml** : diag quotidien / dispatch / push (artefacts)
- **sanity-echo.yml** : smoke déclenchable manuellement
- **ci-yaml-check.yml** : lint/validité YAML

Voir `docs/CI.md`.
<!-- CI:END -->5.json
    * chapter\_manifest\_<!-- CI:BEGIN -->
### CI (Workflows canoniques)

[![sanity-main](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-main.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-main.yml)
[![sanity-echo](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-echo.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-echo.yml)
[![ci-yaml-check](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/ci-yaml-check.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/ci-yaml-check.yml)

- **sanity-main.yml** : diag quotidien / dispatch / push (artefacts)
- **sanity-echo.yml** : smoke déclenchable manuellement
- **ci-yaml-check.yml** : lint/validité YAML

Voir `docs/CI.md`.
<!-- CI:END -->6.json
    * chapter\_manifest\_<!-- CI:BEGIN -->
### CI (Workflows canoniques)

[![sanity-main](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-main.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-main.yml)
[![sanity-echo](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-echo.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-echo.yml)
[![ci-yaml-check](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/ci-yaml-check.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/ci-yaml-check.yml)

- **sanity-main.yml** : diag quotidien / dispatch / push (artefacts)
- **sanity-echo.yml** : smoke déclenchable manuellement
- **ci-yaml-check.yml** : lint/validité YAML

Voir `docs/CI.md`.
<!-- CI:END -->7.json
    * chapter\_manifest\_<!-- CI:BEGIN -->
### CI (Workflows canoniques)

[![sanity-main](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-main.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-main.yml)
[![sanity-echo](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-echo.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-echo.yml)
[![ci-yaml-check](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/ci-yaml-check.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/ci-yaml-check.yml)

- **sanity-main.yml** : diag quotidien / dispatch / push (artefacts)
- **sanity-echo.yml** : smoke déclenchable manuellement
- **ci-yaml-check.yml** : lint/validité YAML

Voir `docs/CI.md`.
<!-- CI:END -->8.json
    * chapter\_manifest\_<!-- CI:BEGIN -->
### CI (Workflows canoniques)

[![sanity-main](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-main.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-main.yml)
[![sanity-echo](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-echo.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-echo.yml)
[![ci-yaml-check](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/ci-yaml-check.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/ci-yaml-check.yml)

- **sanity-main.yml** : diag quotidien / dispatch / push (artefacts)
- **sanity-echo.yml** : smoke déclenchable manuellement
- **ci-yaml-check.yml** : lint/validité YAML

Voir `docs/CI.md`.
<!-- CI:END -->9.json
    * chapter\_manifest\_1<!-- CI:BEGIN -->
### CI (Workflows canoniques)

[![sanity-main](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-main.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-main.yml)
[![sanity-echo](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-echo.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-echo.yml)
[![ci-yaml-check](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/ci-yaml-check.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/ci-yaml-check.yml)

- **sanity-main.yml** : diag quotidien / dispatch / push (artefacts)
- **sanity-echo.yml** : smoke déclenchable manuellement
- **ci-yaml-check.yml** : lint/validité YAML

Voir `docs/CI.md`.
<!-- CI:END -->.json
  * reports/
  Schémas :
* zz-schemas/
  * <!-- CI:BEGIN -->
### CI (Workflows canoniques)

[![sanity-main](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-main.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-main.yml)
[![sanity-echo](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-echo.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-echo.yml)
[![ci-yaml-check](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/ci-yaml-check.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/ci-yaml-check.yml)

- **sanity-main.yml** : diag quotidien / dispatch / push (artefacts)
- **sanity-echo.yml** : smoke déclenchable manuellement
- **ci-yaml-check.yml** : lint/validité YAML

Voir `docs/CI.md`.
<!-- CI:END -->2\_optimal\_parameters.schema.json
  * <!-- CI:BEGIN -->
### CI (Workflows canoniques)

[![sanity-main](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-main.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-main.yml)
[![sanity-echo](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-echo.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-echo.yml)
[![ci-yaml-check](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/ci-yaml-check.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/ci-yaml-check.yml)

- **sanity-main.yml** : diag quotidien / dispatch / push (artefacts)
- **sanity-echo.yml** : smoke déclenchable manuellement
- **ci-yaml-check.yml** : lint/validité YAML

Voir `docs/CI.md`.
<!-- CI:END -->2\_spec\_spectrum.schema.json
  * <!-- CI:BEGIN -->
### CI (Workflows canoniques)

[![sanity-main](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-main.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-main.yml)
[![sanity-echo](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-echo.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-echo.yml)
[![ci-yaml-check](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/ci-yaml-check.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/ci-yaml-check.yml)

- **sanity-main.yml** : diag quotidien / dispatch / push (artefacts)
- **sanity-echo.yml** : smoke déclenchable manuellement
- **ci-yaml-check.yml** : lint/validité YAML

Voir `docs/CI.md`.
<!-- CI:END -->3\_meta\_stability\_fR.schema.json
  * <!-- CI:BEGIN -->
### CI (Workflows canoniques)

[![sanity-main](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-main.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-main.yml)
[![sanity-echo](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-echo.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-echo.yml)
[![ci-yaml-check](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/ci-yaml-check.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/ci-yaml-check.yml)

- **sanity-main.yml** : diag quotidien / dispatch / push (artefacts)
- **sanity-echo.yml** : smoke déclenchable manuellement
- **ci-yaml-check.yml** : lint/validité YAML

Voir `docs/CI.md`.
<!-- CI:END -->5\_nucleosynthesis\_parameters.schema.json
  * <!-- CI:BEGIN -->
### CI (Workflows canoniques)

[![sanity-main](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-main.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-main.yml)
[![sanity-echo](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-echo.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-echo.yml)
[![ci-yaml-check](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/ci-yaml-check.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/ci-yaml-check.yml)

- **sanity-main.yml** : diag quotidien / dispatch / push (artefacts)
- **sanity-echo.yml** : smoke déclenchable manuellement
- **ci-yaml-check.yml** : lint/validité YAML

Voir `docs/CI.md`.
<!-- CI:END -->6\_cmb\_params.schema.json
  * <!-- CI:BEGIN -->
### CI (Workflows canoniques)

[![sanity-main](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-main.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-main.yml)
[![sanity-echo](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-echo.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-echo.yml)
[![ci-yaml-check](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/ci-yaml-check.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/ci-yaml-check.yml)

- **sanity-main.yml** : diag quotidien / dispatch / push (artefacts)
- **sanity-echo.yml** : smoke déclenchable manuellement
- **ci-yaml-check.yml** : lint/validité YAML

Voir `docs/CI.md`.
<!-- CI:END -->7\_meta\_perturbations.schema.json
  * <!-- CI:BEGIN -->
### CI (Workflows canoniques)

[![sanity-main](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-main.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-main.yml)
[![sanity-echo](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-echo.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-echo.yml)
[![ci-yaml-check](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/ci-yaml-check.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/ci-yaml-check.yml)

- **sanity-main.yml** : diag quotidien / dispatch / push (artefacts)
- **sanity-echo.yml** : smoke déclenchable manuellement
- **ci-yaml-check.yml** : lint/validité YAML

Voir `docs/CI.md`.
<!-- CI:END -->7\_params\_perturbations.schema.json
  * <!-- CI:BEGIN -->
### CI (Workflows canoniques)

[![sanity-main](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-main.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-main.yml)
[![sanity-echo](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-echo.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-echo.yml)
[![ci-yaml-check](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/ci-yaml-check.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/ci-yaml-check.yml)

- **sanity-main.yml** : diag quotidien / dispatch / push (artefacts)
- **sanity-echo.yml** : smoke déclenchable manuellement
- **ci-yaml-check.yml** : lint/validité YAML

Voir `docs/CI.md`.
<!-- CI:END -->9\_best\_params.schema.json
  * <!-- CI:BEGIN -->
### CI (Workflows canoniques)

[![sanity-main](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-main.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-main.yml)
[![sanity-echo](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-echo.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-echo.yml)
[![ci-yaml-check](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/ci-yaml-check.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/ci-yaml-check.yml)

- **sanity-main.yml** : diag quotidien / dispatch / push (artefacts)
- **sanity-echo.yml** : smoke déclenchable manuellement
- **ci-yaml-check.yml** : lint/validité YAML

Voir `docs/CI.md`.
<!-- CI:END -->9\_phases\_imrphenom.meta.schema.json
  * comparison\_milestones\_table\_schema.json
  * jalons\_comparaison\_table\_schema.json
  * mc\_best\_schema.json
  * mc\_config\_schema.json
  * mc\_results\_table\_schema.json
  * meta\_schema.json
  * metrics\_phase\_schema.json
  * README.md
  * README\_SCHEMAS.md
  * results\_schema\_examples.json
  * validate\_csv\_schema.py
  * validate\_csv\_table.py
  * validate\_json.py
  * validation\_globals.json
  Checklists :
* zz-checklists/
  * CHAPTER<!-- CI:BEGIN -->
### CI (Workflows canoniques)

[![sanity-main](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-main.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-main.yml)
[![sanity-echo](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-echo.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-echo.yml)
[![ci-yaml-check](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/ci-yaml-check.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/ci-yaml-check.yml)

- **sanity-main.yml** : diag quotidien / dispatch / push (artefacts)
- **sanity-echo.yml** : smoke déclenchable manuellement
- **ci-yaml-check.yml** : lint/validité YAML

Voir `docs/CI.md`.
<!-- CI:END -->1\_CHECKLIST.txt
  * CHAPTER<!-- CI:BEGIN -->
### CI (Workflows canoniques)

[![sanity-main](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-main.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-main.yml)
[![sanity-echo](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-echo.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-echo.yml)
[![ci-yaml-check](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/ci-yaml-check.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/ci-yaml-check.yml)

- **sanity-main.yml** : diag quotidien / dispatch / push (artefacts)
- **sanity-echo.yml** : smoke déclenchable manuellement
- **ci-yaml-check.yml** : lint/validité YAML

Voir `docs/CI.md`.
<!-- CI:END -->2\_CHECKLIST.txt
  * CHAPTER<!-- CI:BEGIN -->
### CI (Workflows canoniques)

[![sanity-main](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-main.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-main.yml)
[![sanity-echo](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-echo.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-echo.yml)
[![ci-yaml-check](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/ci-yaml-check.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/ci-yaml-check.yml)

- **sanity-main.yml** : diag quotidien / dispatch / push (artefacts)
- **sanity-echo.yml** : smoke déclenchable manuellement
- **ci-yaml-check.yml** : lint/validité YAML

Voir `docs/CI.md`.
<!-- CI:END -->3\_CHECKLIST.txt
  * CHAPTER<!-- CI:BEGIN -->
### CI (Workflows canoniques)

[![sanity-main](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-main.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-main.yml)
[![sanity-echo](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-echo.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-echo.yml)
[![ci-yaml-check](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/ci-yaml-check.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/ci-yaml-check.yml)

- **sanity-main.yml** : diag quotidien / dispatch / push (artefacts)
- **sanity-echo.yml** : smoke déclenchable manuellement
- **ci-yaml-check.yml** : lint/validité YAML

Voir `docs/CI.md`.
<!-- CI:END -->4\_CHECKLIST.txt
  * CHAPTER<!-- CI:BEGIN -->
### CI (Workflows canoniques)

[![sanity-main](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-main.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-main.yml)
[![sanity-echo](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-echo.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-echo.yml)
[![ci-yaml-check](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/ci-yaml-check.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/ci-yaml-check.yml)

- **sanity-main.yml** : diag quotidien / dispatch / push (artefacts)
- **sanity-echo.yml** : smoke déclenchable manuellement
- **ci-yaml-check.yml** : lint/validité YAML

Voir `docs/CI.md`.
<!-- CI:END -->5\_CHECKLIST.txt
  * CHAPTER<!-- CI:BEGIN -->
### CI (Workflows canoniques)

[![sanity-main](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-main.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-main.yml)
[![sanity-echo](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-echo.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-echo.yml)
[![ci-yaml-check](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/ci-yaml-check.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/ci-yaml-check.yml)

- **sanity-main.yml** : diag quotidien / dispatch / push (artefacts)
- **sanity-echo.yml** : smoke déclenchable manuellement
- **ci-yaml-check.yml** : lint/validité YAML

Voir `docs/CI.md`.
<!-- CI:END -->6\_CHECKLIST.txt
  * CHAPTER<!-- CI:BEGIN -->
### CI (Workflows canoniques)

[![sanity-main](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-main.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-main.yml)
[![sanity-echo](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-echo.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-echo.yml)
[![ci-yaml-check](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/ci-yaml-check.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/ci-yaml-check.yml)

- **sanity-main.yml** : diag quotidien / dispatch / push (artefacts)
- **sanity-echo.yml** : smoke déclenchable manuellement
- **ci-yaml-check.yml** : lint/validité YAML

Voir `docs/CI.md`.
<!-- CI:END -->7\_CHECKLIST.txt
  * CHAPTER<!-- CI:BEGIN -->
### CI (Workflows canoniques)

[![sanity-main](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-main.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-main.yml)
[![sanity-echo](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-echo.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-echo.yml)
[![ci-yaml-check](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/ci-yaml-check.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/ci-yaml-check.yml)

- **sanity-main.yml** : diag quotidien / dispatch / push (artefacts)
- **sanity-echo.yml** : smoke déclenchable manuellement
- **ci-yaml-check.yml** : lint/validité YAML

Voir `docs/CI.md`.
<!-- CI:END -->8\_CHECKLIST.txt
  * CHAPTER<!-- CI:BEGIN -->
### CI (Workflows canoniques)

[![sanity-main](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-main.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-main.yml)
[![sanity-echo](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-echo.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-echo.yml)
[![ci-yaml-check](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/ci-yaml-check.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/ci-yaml-check.yml)

- **sanity-main.yml** : diag quotidien / dispatch / push (artefacts)
- **sanity-echo.yml** : smoke déclenchable manuellement
- **ci-yaml-check.yml** : lint/validité YAML

Voir `docs/CI.md`.
<!-- CI:END -->9\_CHECKLIST.txt
  * CHAPTER1<!-- CI:BEGIN -->
### CI (Workflows canoniques)

[![sanity-main](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-main.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-main.yml)
[![sanity-echo](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-echo.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-echo.yml)
[![ci-yaml-check](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/ci-yaml-check.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/ci-yaml-check.yml)

- **sanity-main.yml** : diag quotidien / dispatch / push (artefacts)
- **sanity-echo.yml** : smoke déclenchable manuellement
- **ci-yaml-check.yml** : lint/validité YAML

Voir `docs/CI.md`.
<!-- CI:END -->\_CHECKLIST.txt
  Tests :
* zz-tests/
  * pytest.ini
  * test\_manifest.py
  * test\_schemas.py
  Workflows CI :
* zz-workflows/
  * ci.yml
  * release.yml
  * README.md
---
## 2) Contenu des chapitres (LaTeX)
Chaque dossier de chapitre contient :
* <prefix>\_conceptuel.tex
* <prefix>\_details.tex (ou \_calibration\_conceptuel.tex pour le chap. 1)
* CHAPTERXX\_GUIDE.txt (notes, exigences, jalons spécifiques)
Liste :
* Chapitre 1 – Introduction conceptuelle (<!-- CI:BEGIN -->
### CI (Workflows canoniques)

[![sanity-main](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-main.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-main.yml)
[![sanity-echo](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-echo.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-echo.yml)
[![ci-yaml-check](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/ci-yaml-check.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/ci-yaml-check.yml)

- **sanity-main.yml** : diag quotidien / dispatch / push (artefacts)
- **sanity-echo.yml** : smoke déclenchable manuellement
- **ci-yaml-check.yml** : lint/validité YAML

Voir `docs/CI.md`.
<!-- CI:END -->1-introduction-applications/)
  * <!-- CI:BEGIN -->
### CI (Workflows canoniques)

[![sanity-main](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-main.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-main.yml)
[![sanity-echo](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-echo.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-echo.yml)
[![ci-yaml-check](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/ci-yaml-check.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/ci-yaml-check.yml)

- **sanity-main.yml** : diag quotidien / dispatch / push (artefacts)
- **sanity-echo.yml** : smoke déclenchable manuellement
- **ci-yaml-check.yml** : lint/validité YAML

Voir `docs/CI.md`.
<!-- CI:END -->1\_introduction\_conceptuel.tex
  * <!-- CI:BEGIN -->
### CI (Workflows canoniques)

[![sanity-main](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-main.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-main.yml)
[![sanity-echo](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-echo.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-echo.yml)
[![ci-yaml-check](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/ci-yaml-check.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/ci-yaml-check.yml)

- **sanity-main.yml** : diag quotidien / dispatch / push (artefacts)
- **sanity-echo.yml** : smoke déclenchable manuellement
- **ci-yaml-check.yml** : lint/validité YAML

Voir `docs/CI.md`.
<!-- CI:END -->1\_applications\_calibration\_conceptuel.tex
  * CHAPTER<!-- CI:BEGIN -->
### CI (Workflows canoniques)

[![sanity-main](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-main.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-main.yml)
[![sanity-echo](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-echo.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-echo.yml)
[![ci-yaml-check](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/ci-yaml-check.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/ci-yaml-check.yml)

- **sanity-main.yml** : diag quotidien / dispatch / push (artefacts)
- **sanity-echo.yml** : smoke déclenchable manuellement
- **ci-yaml-check.yml** : lint/validité YAML

Voir `docs/CI.md`.
<!-- CI:END -->1\_GUIDE.txt
* Chapitre 2 – Validation chronologique (<!-- CI:BEGIN -->
### CI (Workflows canoniques)

[![sanity-main](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-main.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-main.yml)
[![sanity-echo](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-echo.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-echo.yml)
[![ci-yaml-check](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/ci-yaml-check.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/ci-yaml-check.yml)

- **sanity-main.yml** : diag quotidien / dispatch / push (artefacts)
- **sanity-echo.yml** : smoke déclenchable manuellement
- **ci-yaml-check.yml** : lint/validité YAML

Voir `docs/CI.md`.
<!-- CI:END -->2-validation-chronologique/)
  * <!-- CI:BEGIN -->
### CI (Workflows canoniques)

[![sanity-main](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-main.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-main.yml)
[![sanity-echo](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-echo.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-echo.yml)
[![ci-yaml-check](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/ci-yaml-check.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/ci-yaml-check.yml)

- **sanity-main.yml** : diag quotidien / dispatch / push (artefacts)
- **sanity-echo.yml** : smoke déclenchable manuellement
- **ci-yaml-check.yml** : lint/validité YAML

Voir `docs/CI.md`.
<!-- CI:END -->2\_validation\_chronologique\_conceptuel.tex
  * <!-- CI:BEGIN -->
### CI (Workflows canoniques)

[![sanity-main](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-main.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-main.yml)
[![sanity-echo](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-echo.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-echo.yml)
[![ci-yaml-check](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/ci-yaml-check.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/ci-yaml-check.yml)

- **sanity-main.yml** : diag quotidien / dispatch / push (artefacts)
- **sanity-echo.yml** : smoke déclenchable manuellement
- **ci-yaml-check.yml** : lint/validité YAML

Voir `docs/CI.md`.
<!-- CI:END -->2\_validation\_chronologique\_details.tex
  * CHAPTER<!-- CI:BEGIN -->
### CI (Workflows canoniques)

[![sanity-main](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-main.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-main.yml)
[![sanity-echo](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-echo.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-echo.yml)
[![ci-yaml-check](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/ci-yaml-check.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/ci-yaml-check.yml)

- **sanity-main.yml** : diag quotidien / dispatch / push (artefacts)
- **sanity-echo.yml** : smoke déclenchable manuellement
- **ci-yaml-check.yml** : lint/validité YAML

Voir `docs/CI.md`.
<!-- CI:END -->2\_GUIDE.txt
* Chapitre 3 – Stabilité f(R) (<!-- CI:BEGIN -->
### CI (Workflows canoniques)

[![sanity-main](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-main.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-main.yml)
[![sanity-echo](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-echo.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-echo.yml)
[![ci-yaml-check](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/ci-yaml-check.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/ci-yaml-check.yml)

- **sanity-main.yml** : diag quotidien / dispatch / push (artefacts)
- **sanity-echo.yml** : smoke déclenchable manuellement
- **ci-yaml-check.yml** : lint/validité YAML

Voir `docs/CI.md`.
<!-- CI:END -->3-stabilite-fR/)
  * <!-- CI:BEGIN -->
### CI (Workflows canoniques)

[![sanity-main](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-main.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-main.yml)
[![sanity-echo](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-echo.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-echo.yml)
[![ci-yaml-check](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/ci-yaml-check.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/ci-yaml-check.yml)

- **sanity-main.yml** : diag quotidien / dispatch / push (artefacts)
- **sanity-echo.yml** : smoke déclenchable manuellement
- **ci-yaml-check.yml** : lint/validité YAML

Voir `docs/CI.md`.
<!-- CI:END -->3\_stabilite\_fR\_conceptuel.tex
  * <!-- CI:BEGIN -->
### CI (Workflows canoniques)

[![sanity-main](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-main.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-main.yml)
[![sanity-echo](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-echo.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-echo.yml)
[![ci-yaml-check](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/ci-yaml-check.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/ci-yaml-check.yml)

- **sanity-main.yml** : diag quotidien / dispatch / push (artefacts)
- **sanity-echo.yml** : smoke déclenchable manuellement
- **ci-yaml-check.yml** : lint/validité YAML

Voir `docs/CI.md`.
<!-- CI:END -->3\_stabilite\_fR\_details.tex
  * CHAPTER<!-- CI:BEGIN -->
### CI (Workflows canoniques)

[![sanity-main](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-main.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-main.yml)
[![sanity-echo](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-echo.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-echo.yml)
[![ci-yaml-check](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/ci-yaml-check.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/ci-yaml-check.yml)

- **sanity-main.yml** : diag quotidien / dispatch / push (artefacts)
- **sanity-echo.yml** : smoke déclenchable manuellement
- **ci-yaml-check.yml** : lint/validité YAML

Voir `docs/CI.md`.
<!-- CI:END -->3\_GUIDE.txt
* Chapitre 4 – Invariants adimensionnels (<!-- CI:BEGIN -->
### CI (Workflows canoniques)

[![sanity-main](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-main.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-main.yml)
[![sanity-echo](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-echo.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-echo.yml)
[![ci-yaml-check](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/ci-yaml-check.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/ci-yaml-check.yml)

- **sanity-main.yml** : diag quotidien / dispatch / push (artefacts)
- **sanity-echo.yml** : smoke déclenchable manuellement
- **ci-yaml-check.yml** : lint/validité YAML

Voir `docs/CI.md`.
<!-- CI:END -->4-invariants-adimensionnels/)
  * <!-- CI:BEGIN -->
### CI (Workflows canoniques)

[![sanity-main](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-main.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-main.yml)
[![sanity-echo](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-echo.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-echo.yml)
[![ci-yaml-check](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/ci-yaml-check.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/ci-yaml-check.yml)

- **sanity-main.yml** : diag quotidien / dispatch / push (artefacts)
- **sanity-echo.yml** : smoke déclenchable manuellement
- **ci-yaml-check.yml** : lint/validité YAML

Voir `docs/CI.md`.
<!-- CI:END -->4\_invariants\_adimensionnels\_conceptuel.tex
  * <!-- CI:BEGIN -->
### CI (Workflows canoniques)

[![sanity-main](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-main.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-main.yml)
[![sanity-echo](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-echo.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-echo.yml)
[![ci-yaml-check](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/ci-yaml-check.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/ci-yaml-check.yml)

- **sanity-main.yml** : diag quotidien / dispatch / push (artefacts)
- **sanity-echo.yml** : smoke déclenchable manuellement
- **ci-yaml-check.yml** : lint/validité YAML

Voir `docs/CI.md`.
<!-- CI:END -->4\_invariants\_adimensionnels\_details.tex
  * CHAPTER<!-- CI:BEGIN -->
### CI (Workflows canoniques)

[![sanity-main](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-main.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-main.yml)
[![sanity-echo](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-echo.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-echo.yml)
[![ci-yaml-check](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/ci-yaml-check.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/ci-yaml-check.yml)

- **sanity-main.yml** : diag quotidien / dispatch / push (artefacts)
- **sanity-echo.yml** : smoke déclenchable manuellement
- **ci-yaml-check.yml** : lint/validité YAML

Voir `docs/CI.md`.
<!-- CI:END -->4\_GUIDE.txt
* Chapitre 5 – Nucléosynthèse primordiale (<!-- CI:BEGIN -->
### CI (Workflows canoniques)

[![sanity-main](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-main.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-main.yml)
[![sanity-echo](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-echo.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-echo.yml)
[![ci-yaml-check](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/ci-yaml-check.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/ci-yaml-check.yml)

- **sanity-main.yml** : diag quotidien / dispatch / push (artefacts)
- **sanity-echo.yml** : smoke déclenchable manuellement
- **ci-yaml-check.yml** : lint/validité YAML

Voir `docs/CI.md`.
<!-- CI:END -->5-nucleosynthese-primordiale/)
  * <!-- CI:BEGIN -->
### CI (Workflows canoniques)

[![sanity-main](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-main.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-main.yml)
[![sanity-echo](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-echo.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-echo.yml)
[![ci-yaml-check](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/ci-yaml-check.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/ci-yaml-check.yml)

- **sanity-main.yml** : diag quotidien / dispatch / push (artefacts)
- **sanity-echo.yml** : smoke déclenchable manuellement
- **ci-yaml-check.yml** : lint/validité YAML

Voir `docs/CI.md`.
<!-- CI:END -->5\_nucleosynthese\_primordiale\_conceptuel.tex
  * <!-- CI:BEGIN -->
### CI (Workflows canoniques)

[![sanity-main](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-main.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-main.yml)
[![sanity-echo](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-echo.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-echo.yml)
[![ci-yaml-check](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/ci-yaml-check.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/ci-yaml-check.yml)

- **sanity-main.yml** : diag quotidien / dispatch / push (artefacts)
- **sanity-echo.yml** : smoke déclenchable manuellement
- **ci-yaml-check.yml** : lint/validité YAML

Voir `docs/CI.md`.
<!-- CI:END -->5\_nucleosynthese\_primordiale\_details.tex
  * CHAPTER<!-- CI:BEGIN -->
### CI (Workflows canoniques)

[![sanity-main](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-main.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-main.yml)
[![sanity-echo](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-echo.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-echo.yml)
[![ci-yaml-check](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/ci-yaml-check.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/ci-yaml-check.yml)

- **sanity-main.yml** : diag quotidien / dispatch / push (artefacts)
- **sanity-echo.yml** : smoke déclenchable manuellement
- **ci-yaml-check.yml** : lint/validité YAML

Voir `docs/CI.md`.
<!-- CI:END -->5\_GUIDE.txt
* Chapitre 6 – Rayonnement CMB (<!-- CI:BEGIN -->
### CI (Workflows canoniques)

[![sanity-main](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-main.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-main.yml)
[![sanity-echo](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-echo.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-echo.yml)
[![ci-yaml-check](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/ci-yaml-check.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/ci-yaml-check.yml)

- **sanity-main.yml** : diag quotidien / dispatch / push (artefacts)
- **sanity-echo.yml** : smoke déclenchable manuellement
- **ci-yaml-check.yml** : lint/validité YAML

Voir `docs/CI.md`.
<!-- CI:END -->6-rayonnement-cmb/)
  * <!-- CI:BEGIN -->
### CI (Workflows canoniques)

[![sanity-main](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-main.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-main.yml)
[![sanity-echo](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-echo.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-echo.yml)
[![ci-yaml-check](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/ci-yaml-check.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/ci-yaml-check.yml)

- **sanity-main.yml** : diag quotidien / dispatch / push (artefacts)
- **sanity-echo.yml** : smoke déclenchable manuellement
- **ci-yaml-check.yml** : lint/validité YAML

Voir `docs/CI.md`.
<!-- CI:END -->6\_cmb\_conceptuel.tex
  * <!-- CI:BEGIN -->
### CI (Workflows canoniques)

[![sanity-main](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-main.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-main.yml)
[![sanity-echo](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-echo.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-echo.yml)
[![ci-yaml-check](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/ci-yaml-check.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/ci-yaml-check.yml)

- **sanity-main.yml** : diag quotidien / dispatch / push (artefacts)
- **sanity-echo.yml** : smoke déclenchable manuellement
- **ci-yaml-check.yml** : lint/validité YAML

Voir `docs/CI.md`.
<!-- CI:END -->6\_cmb\_details.tex
  * CHAPTER<!-- CI:BEGIN -->
### CI (Workflows canoniques)

[![sanity-main](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-main.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-main.yml)
[![sanity-echo](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-echo.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-echo.yml)
[![ci-yaml-check](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/ci-yaml-check.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/ci-yaml-check.yml)

- **sanity-main.yml** : diag quotidien / dispatch / push (artefacts)
- **sanity-echo.yml** : smoke déclenchable manuellement
- **ci-yaml-check.yml** : lint/validité YAML

Voir `docs/CI.md`.
<!-- CI:END -->6\_GUIDE.txt
* Chapitre 7 – Perturbations scalaires (<!-- CI:BEGIN -->
### CI (Workflows canoniques)

[![sanity-main](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-main.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-main.yml)
[![sanity-echo](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-echo.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-echo.yml)
[![ci-yaml-check](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/ci-yaml-check.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/ci-yaml-check.yml)

- **sanity-main.yml** : diag quotidien / dispatch / push (artefacts)
- **sanity-echo.yml** : smoke déclenchable manuellement
- **ci-yaml-check.yml** : lint/validité YAML

Voir `docs/CI.md`.
<!-- CI:END -->7-perturbations-scalaires/)
  * <!-- CI:BEGIN -->
### CI (Workflows canoniques)

[![sanity-main](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-main.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-main.yml)
[![sanity-echo](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-echo.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-echo.yml)
[![ci-yaml-check](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/ci-yaml-check.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/ci-yaml-check.yml)

- **sanity-main.yml** : diag quotidien / dispatch / push (artefacts)
- **sanity-echo.yml** : smoke déclenchable manuellement
- **ci-yaml-check.yml** : lint/validité YAML

Voir `docs/CI.md`.
<!-- CI:END -->7\_perturbations\_scalaires\_conceptuel.tex
  * <!-- CI:BEGIN -->
### CI (Workflows canoniques)

[![sanity-main](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-main.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-main.yml)
[![sanity-echo](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-echo.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-echo.yml)
[![ci-yaml-check](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/ci-yaml-check.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/ci-yaml-check.yml)

- **sanity-main.yml** : diag quotidien / dispatch / push (artefacts)
- **sanity-echo.yml** : smoke déclenchable manuellement
- **ci-yaml-check.yml** : lint/validité YAML

Voir `docs/CI.md`.
<!-- CI:END -->7\_perturbations\_scalaires\_details.tex
  * CHAPTER<!-- CI:BEGIN -->
### CI (Workflows canoniques)

[![sanity-main](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-main.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-main.yml)
[![sanity-echo](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-echo.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-echo.yml)
[![ci-yaml-check](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/ci-yaml-check.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/ci-yaml-check.yml)

- **sanity-main.yml** : diag quotidien / dispatch / push (artefacts)
- **sanity-echo.yml** : smoke déclenchable manuellement
- **ci-yaml-check.yml** : lint/validité YAML

Voir `docs/CI.md`.
<!-- CI:END -->7\_GUIDE.txt
* Chapitre 8 – Couplage sombre (<!-- CI:BEGIN -->
### CI (Workflows canoniques)

[![sanity-main](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-main.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-main.yml)
[![sanity-echo](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-echo.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-echo.yml)
[![ci-yaml-check](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/ci-yaml-check.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/ci-yaml-check.yml)

- **sanity-main.yml** : diag quotidien / dispatch / push (artefacts)
- **sanity-echo.yml** : smoke déclenchable manuellement
- **ci-yaml-check.yml** : lint/validité YAML

Voir `docs/CI.md`.
<!-- CI:END -->8-couplage-sombre/)
  * <!-- CI:BEGIN -->
### CI (Workflows canoniques)

[![sanity-main](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-main.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-main.yml)
[![sanity-echo](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-echo.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-echo.yml)
[![ci-yaml-check](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/ci-yaml-check.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/ci-yaml-check.yml)

- **sanity-main.yml** : diag quotidien / dispatch / push (artefacts)
- **sanity-echo.yml** : smoke déclenchable manuellement
- **ci-yaml-check.yml** : lint/validité YAML

Voir `docs/CI.md`.
<!-- CI:END -->8\_couplage\_sombre\_conceptuel.tex
  * <!-- CI:BEGIN -->
### CI (Workflows canoniques)

[![sanity-main](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-main.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-main.yml)
[![sanity-echo](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-echo.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-echo.yml)
[![ci-yaml-check](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/ci-yaml-check.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/ci-yaml-check.yml)

- **sanity-main.yml** : diag quotidien / dispatch / push (artefacts)
- **sanity-echo.yml** : smoke déclenchable manuellement
- **ci-yaml-check.yml** : lint/validité YAML

Voir `docs/CI.md`.
<!-- CI:END -->8\_couplage\_sombre\_details.tex
  * CHAPTER<!-- CI:BEGIN -->
### CI (Workflows canoniques)

[![sanity-main](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-main.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-main.yml)
[![sanity-echo](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-echo.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-echo.yml)
[![ci-yaml-check](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/ci-yaml-check.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/ci-yaml-check.yml)

- **sanity-main.yml** : diag quotidien / dispatch / push (artefacts)
- **sanity-echo.yml** : smoke déclenchable manuellement
- **ci-yaml-check.yml** : lint/validité YAML

Voir `docs/CI.md`.
<!-- CI:END -->8\_GUIDE.txt
* Chapitre 9 – Phase ondes gravitationnelles (<!-- CI:BEGIN -->
### CI (Workflows canoniques)

[![sanity-main](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-main.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-main.yml)
[![sanity-echo](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-echo.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-echo.yml)
[![ci-yaml-check](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/ci-yaml-check.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/ci-yaml-check.yml)

- **sanity-main.yml** : diag quotidien / dispatch / push (artefacts)
- **sanity-echo.yml** : smoke déclenchable manuellement
- **ci-yaml-check.yml** : lint/validité YAML

Voir `docs/CI.md`.
<!-- CI:END -->9-phase-ondes-gravitationnelles/)
  * <!-- CI:BEGIN -->
### CI (Workflows canoniques)

[![sanity-main](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-main.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-main.yml)
[![sanity-echo](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-echo.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-echo.yml)
[![ci-yaml-check](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/ci-yaml-check.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/ci-yaml-check.yml)

- **sanity-main.yml** : diag quotidien / dispatch / push (artefacts)
- **sanity-echo.yml** : smoke déclenchable manuellement
- **ci-yaml-check.yml** : lint/validité YAML

Voir `docs/CI.md`.
<!-- CI:END -->9\_phase\_ondes\_grav\_conceptuel.tex
  * <!-- CI:BEGIN -->
### CI (Workflows canoniques)

[![sanity-main](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-main.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-main.yml)
[![sanity-echo](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-echo.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-echo.yml)
[![ci-yaml-check](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/ci-yaml-check.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/ci-yaml-check.yml)

- **sanity-main.yml** : diag quotidien / dispatch / push (artefacts)
- **sanity-echo.yml** : smoke déclenchable manuellement
- **ci-yaml-check.yml** : lint/validité YAML

Voir `docs/CI.md`.
<!-- CI:END -->9\_phase\_ondes\_grav\_details.tex
  * CHAPTER<!-- CI:BEGIN -->
### CI (Workflows canoniques)

[![sanity-main](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-main.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-main.yml)
[![sanity-echo](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-echo.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-echo.yml)
[![ci-yaml-check](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/ci-yaml-check.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/ci-yaml-check.yml)

- **sanity-main.yml** : diag quotidien / dispatch / push (artefacts)
- **sanity-echo.yml** : smoke déclenchable manuellement
- **ci-yaml-check.yml** : lint/validité YAML

Voir `docs/CI.md`.
<!-- CI:END -->9\_GUIDE.txt
* Chapitre 1<!-- CI:BEGIN -->
### CI (Workflows canoniques)

[![sanity-main](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-main.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-main.yml)
[![sanity-echo](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-echo.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-echo.yml)
[![ci-yaml-check](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/ci-yaml-check.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/ci-yaml-check.yml)

- **sanity-main.yml** : diag quotidien / dispatch / push (artefacts)
- **sanity-echo.yml** : smoke déclenchable manuellement
- **ci-yaml-check.yml** : lint/validité YAML

Voir `docs/CI.md`.
<!-- CI:END --> – Monte Carlo global 8D (1<!-- CI:BEGIN -->
### CI (Workflows canoniques)

[![sanity-main](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-main.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-main.yml)
[![sanity-echo](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-echo.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-echo.yml)
[![ci-yaml-check](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/ci-yaml-check.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/ci-yaml-check.yml)

- **sanity-main.yml** : diag quotidien / dispatch / push (artefacts)
- **sanity-echo.yml** : smoke déclenchable manuellement
- **ci-yaml-check.yml** : lint/validité YAML

Voir `docs/CI.md`.
<!-- CI:END -->-monte-carlo-global-8d/)
  * 1<!-- CI:BEGIN -->
### CI (Workflows canoniques)

[![sanity-main](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-main.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-main.yml)
[![sanity-echo](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-echo.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-echo.yml)
[![ci-yaml-check](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/ci-yaml-check.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/ci-yaml-check.yml)

- **sanity-main.yml** : diag quotidien / dispatch / push (artefacts)
- **sanity-echo.yml** : smoke déclenchable manuellement
- **ci-yaml-check.yml** : lint/validité YAML

Voir `docs/CI.md`.
<!-- CI:END -->\_monte\_carlo\_global\_conceptuel.tex
  * 1<!-- CI:BEGIN -->
### CI (Workflows canoniques)

[![sanity-main](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-main.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-main.yml)
[![sanity-echo](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-echo.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-echo.yml)
[![ci-yaml-check](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/ci-yaml-check.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/ci-yaml-check.yml)

- **sanity-main.yml** : diag quotidien / dispatch / push (artefacts)
- **sanity-echo.yml** : smoke déclenchable manuellement
- **ci-yaml-check.yml** : lint/validité YAML

Voir `docs/CI.md`.
<!-- CI:END -->\_monte\_carlo\_global\_details.tex
  * CHAPTER1<!-- CI:BEGIN -->
### CI (Workflows canoniques)

[![sanity-main](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-main.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-main.yml)
[![sanity-echo](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-echo.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-echo.yml)
[![ci-yaml-check](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/ci-yaml-check.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/ci-yaml-check.yml)

- **sanity-main.yml** : diag quotidien / dispatch / push (artefacts)
- **sanity-echo.yml** : smoke déclenchable manuellement
- **ci-yaml-check.yml** : lint/validité YAML

Voir `docs/CI.md`.
<!-- CI:END -->\_GUIDE.txt
---
## 3) Configurations & package Python
* zz-configuration/mcgt-global-config.ini : paramètres transverses (chemins de données/figures, tolérances, seeds, options graphiques, etc.).
* zz-configuration/\*.ini spécifiques (ex. camb\_exact\_plateau.ini, scalar\_perturbations.ini, gw\_phase.ini).
* zz-configuration/GWTC-3-confident-events.json ; zz-configuration/pdot\_plateau\_vs\_z.dat ; zz-configuration/meta\_template.json ; zz-configuration/mcgt-global-config.ini.template ; zz-configuration/README.md.
* mcgt/ : API Python interne (ex. calculs de phase, solveurs de perturbations, backends de référence). mcgt/backends/ref\_phase.py fournit la phase de ref.
* mcgt/CHANGELOG.md ; mcgt/pyproject.toml.
---
## 4) Données (zz-data/)
Organisation par chapitre, exemples (liste non exhaustive) :
* zz-data/chapter<!-- CI:BEGIN -->
### CI (Workflows canoniques)

[![sanity-main](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-main.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-main.yml)
[![sanity-echo](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-echo.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-echo.yml)
[![ci-yaml-check](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/ci-yaml-check.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/ci-yaml-check.yml)

- **sanity-main.yml** : diag quotidien / dispatch / push (artefacts)
- **sanity-echo.yml** : smoke déclenchable manuellement
- **ci-yaml-check.yml** : lint/validité YAML

Voir `docs/CI.md`.
<!-- CI:END -->1/
  * <!-- CI:BEGIN -->
### CI (Workflows canoniques)

[![sanity-main](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-main.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-main.yml)
[![sanity-echo](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-echo.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-echo.yml)
[![ci-yaml-check](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/ci-yaml-check.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/ci-yaml-check.yml)

- **sanity-main.yml** : diag quotidien / dispatch / push (artefacts)
- **sanity-echo.yml** : smoke déclenchable manuellement
- **ci-yaml-check.yml** : lint/validité YAML

Voir `docs/CI.md`.
<!-- CI:END -->1\_optimized\_data.csv
  * <!-- CI:BEGIN -->
### CI (Workflows canoniques)

[![sanity-main](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-main.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-main.yml)
[![sanity-echo](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-echo.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-echo.yml)
[![ci-yaml-check](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/ci-yaml-check.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/ci-yaml-check.yml)

- **sanity-main.yml** : diag quotidien / dispatch / push (artefacts)
- **sanity-echo.yml** : smoke déclenchable manuellement
- **ci-yaml-check.yml** : lint/validité YAML

Voir `docs/CI.md`.
<!-- CI:END -->1\_optimized\_data\_and\_derivatives.csv
  * <!-- CI:BEGIN -->
### CI (Workflows canoniques)

[![sanity-main](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-main.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-main.yml)
[![sanity-echo](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-echo.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-echo.yml)
[![ci-yaml-check](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/ci-yaml-check.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/ci-yaml-check.yml)

- **sanity-main.yml** : diag quotidien / dispatch / push (artefacts)
- **sanity-echo.yml** : smoke déclenchable manuellement
- **ci-yaml-check.yml** : lint/validité YAML

Voir `docs/CI.md`.
<!-- CI:END -->1\_optimized\_grid\_data.dat
  * <!-- CI:BEGIN -->
### CI (Workflows canoniques)

[![sanity-main](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-main.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-main.yml)
[![sanity-echo](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-echo.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-echo.yml)
[![ci-yaml-check](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/ci-yaml-check.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/ci-yaml-check.yml)

- **sanity-main.yml** : diag quotidien / dispatch / push (artefacts)
- **sanity-echo.yml** : smoke déclenchable manuellement
- **ci-yaml-check.yml** : lint/validité YAML

Voir `docs/CI.md`.
<!-- CI:END -->1\_P\_vs\_T.dat
  * <!-- CI:BEGIN -->
### CI (Workflows canoniques)

[![sanity-main](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-main.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-main.yml)
[![sanity-echo](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-echo.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-echo.yml)
[![ci-yaml-check](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/ci-yaml-check.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/ci-yaml-check.yml)

- **sanity-main.yml** : diag quotidien / dispatch / push (artefacts)
- **sanity-echo.yml** : smoke déclenchable manuellement
- **ci-yaml-check.yml** : lint/validité YAML

Voir `docs/CI.md`.
<!-- CI:END -->1\_initial\_grid\_data.dat
  * <!-- CI:BEGIN -->
### CI (Workflows canoniques)

[![sanity-main](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-main.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-main.yml)
[![sanity-echo](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-echo.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-echo.yml)
[![ci-yaml-check](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/ci-yaml-check.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/ci-yaml-check.yml)

- **sanity-main.yml** : diag quotidien / dispatch / push (artefacts)
- **sanity-echo.yml** : smoke déclenchable manuellement
- **ci-yaml-check.yml** : lint/validité YAML

Voir `docs/CI.md`.
<!-- CI:END -->1\_P\_derivative\_initial.csv
  * <!-- CI:BEGIN -->
### CI (Workflows canoniques)

[![sanity-main](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-main.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-main.yml)
[![sanity-echo](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-echo.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-echo.yml)
[![ci-yaml-check](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/ci-yaml-check.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/ci-yaml-check.yml)

- **sanity-main.yml** : diag quotidien / dispatch / push (artefacts)
- **sanity-echo.yml** : smoke déclenchable manuellement
- **ci-yaml-check.yml** : lint/validité YAML

Voir `docs/CI.md`.
<!-- CI:END -->1\_P\_derivative\_optimized.csv
  * <!-- CI:BEGIN -->
### CI (Workflows canoniques)

[![sanity-main](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-main.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-main.yml)
[![sanity-echo](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-echo.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-echo.yml)
[![ci-yaml-check](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/ci-yaml-check.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/ci-yaml-check.yml)

- **sanity-main.yml** : diag quotidien / dispatch / push (artefacts)
- **sanity-echo.yml** : smoke déclenchable manuellement
- **ci-yaml-check.yml** : lint/validité YAML

Voir `docs/CI.md`.
<!-- CI:END -->1\_relative\_error\_timeline.csv
  * <!-- CI:BEGIN -->
### CI (Workflows canoniques)

[![sanity-main](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-main.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-main.yml)
[![sanity-echo](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-echo.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-echo.yml)
[![ci-yaml-check](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/ci-yaml-check.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/ci-yaml-check.yml)

- **sanity-main.yml** : diag quotidien / dispatch / push (artefacts)
- **sanity-echo.yml** : smoke déclenchable manuellement
- **ci-yaml-check.yml** : lint/validité YAML

Voir `docs/CI.md`.
<!-- CI:END -->1\_timeline\_milestones.csv
  * <!-- CI:BEGIN -->
### CI (Workflows canoniques)

[![sanity-main](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-main.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-main.yml)
[![sanity-echo](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-echo.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-echo.yml)
[![ci-yaml-check](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/ci-yaml-check.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/ci-yaml-check.yml)

- **sanity-main.yml** : diag quotidien / dispatch / push (artefacts)
- **sanity-echo.yml** : smoke déclenchable manuellement
- **ci-yaml-check.yml** : lint/validité YAML

Voir `docs/CI.md`.
<!-- CI:END -->1\_dimensionless\_invariants.csv
* zz-data/chapter<!-- CI:BEGIN -->
### CI (Workflows canoniques)

[![sanity-main](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-main.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-main.yml)
[![sanity-echo](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-echo.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-echo.yml)
[![ci-yaml-check](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/ci-yaml-check.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/ci-yaml-check.yml)

- **sanity-main.yml** : diag quotidien / dispatch / push (artefacts)
- **sanity-echo.yml** : smoke déclenchable manuellement
- **ci-yaml-check.yml** : lint/validité YAML

Voir `docs/CI.md`.
<!-- CI:END -->2/
  * <!-- CI:BEGIN -->
### CI (Workflows canoniques)

[![sanity-main](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-main.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-main.yml)
[![sanity-echo](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-echo.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-echo.yml)
[![ci-yaml-check](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/ci-yaml-check.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/ci-yaml-check.yml)

- **sanity-main.yml** : diag quotidien / dispatch / push (artefacts)
- **sanity-echo.yml** : smoke déclenchable manuellement
- **ci-yaml-check.yml** : lint/validité YAML

Voir `docs/CI.md`.
<!-- CI:END -->2\_optimal\_parameters.json, <!-- CI:BEGIN -->
### CI (Workflows canoniques)

[![sanity-main](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-main.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-main.yml)
[![sanity-echo](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-echo.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-echo.yml)
[![ci-yaml-check](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/ci-yaml-check.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/ci-yaml-check.yml)

- **sanity-main.yml** : diag quotidien / dispatch / push (artefacts)
- **sanity-echo.yml** : smoke déclenchable manuellement
- **ci-yaml-check.yml** : lint/validité YAML

Voir `docs/CI.md`.
<!-- CI:END -->2\_primordial\_spectrum\_spec.json
  * <!-- CI:BEGIN -->
### CI (Workflows canoniques)

[![sanity-main](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-main.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-main.yml)
[![sanity-echo](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-echo.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-echo.yml)
[![ci-yaml-check](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/ci-yaml-check.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/ci-yaml-check.yml)

- **sanity-main.yml** : diag quotidien / dispatch / push (artefacts)
- **sanity-echo.yml** : smoke déclenchable manuellement
- **ci-yaml-check.yml** : lint/validité YAML

Voir `docs/CI.md`.
<!-- CI:END -->2\_P\_vs\_T\_grid\_data.dat, <!-- CI:BEGIN -->
### CI (Workflows canoniques)

[![sanity-main](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-main.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-main.yml)
[![sanity-echo](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-echo.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-echo.yml)
[![ci-yaml-check](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/ci-yaml-check.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/ci-yaml-check.yml)

- **sanity-main.yml** : diag quotidien / dispatch / push (artefacts)
- **sanity-echo.yml** : smoke déclenchable manuellement
- **ci-yaml-check.yml** : lint/validité YAML

Voir `docs/CI.md`.
<!-- CI:END -->2\_P\_derivative\_data.dat
  * <!-- CI:BEGIN -->
### CI (Workflows canoniques)

[![sanity-main](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-main.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-main.yml)
[![sanity-echo](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-echo.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-echo.yml)
[![ci-yaml-check](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/ci-yaml-check.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/ci-yaml-check.yml)

- **sanity-main.yml** : diag quotidien / dispatch / push (artefacts)
- **sanity-echo.yml** : smoke déclenchable manuellement
- **ci-yaml-check.yml** : lint/validité YAML

Voir `docs/CI.md`.
<!-- CI:END -->2\_As\_ns\_vs\_alpha.csv, <!-- CI:BEGIN -->
### CI (Workflows canoniques)

[![sanity-main](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-main.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-main.yml)
[![sanity-echo](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-echo.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-echo.yml)
[![ci-yaml-check](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/ci-yaml-check.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/ci-yaml-check.yml)

- **sanity-main.yml** : diag quotidien / dispatch / push (artefacts)
- **sanity-echo.yml** : smoke déclenchable manuellement
- **ci-yaml-check.yml** : lint/validité YAML

Voir `docs/CI.md`.
<!-- CI:END -->2\_P\_R\_sampling.csv
  * <!-- CI:BEGIN -->
### CI (Workflows canoniques)

[![sanity-main](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-main.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-main.yml)
[![sanity-echo](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-echo.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-echo.yml)
[![ci-yaml-check](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/ci-yaml-check.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/ci-yaml-check.yml)

- **sanity-main.yml** : diag quotidien / dispatch / push (artefacts)
- **sanity-echo.yml** : smoke déclenchable manuellement
- **ci-yaml-check.yml** : lint/validité YAML

Voir `docs/CI.md`.
<!-- CI:END -->2\_FG\_series.csv
  * <!-- CI:BEGIN -->
### CI (Workflows canoniques)

[![sanity-main](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-main.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-main.yml)
[![sanity-echo](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-echo.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-echo.yml)
[![ci-yaml-check](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/ci-yaml-check.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/ci-yaml-check.yml)

- **sanity-main.yml** : diag quotidien / dispatch / push (artefacts)
- **sanity-echo.yml** : smoke déclenchable manuellement
- **ci-yaml-check.yml** : lint/validité YAML

Voir `docs/CI.md`.
<!-- CI:END -->2\_timeline\_milestones.csv, <!-- CI:BEGIN -->
### CI (Workflows canoniques)

[![sanity-main](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-main.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-main.yml)
[![sanity-echo](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-echo.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-echo.yml)
[![ci-yaml-check](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/ci-yaml-check.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/ci-yaml-check.yml)

- **sanity-main.yml** : diag quotidien / dispatch / push (artefacts)
- **sanity-echo.yml** : smoke déclenchable manuellement
- **ci-yaml-check.yml** : lint/validité YAML

Voir `docs/CI.md`.
<!-- CI:END -->2\_relative\_error\_timeline.csv, <!-- CI:BEGIN -->
### CI (Workflows canoniques)

[![sanity-main](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-main.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-main.yml)
[![sanity-echo](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-echo.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-echo.yml)
[![ci-yaml-check](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/ci-yaml-check.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/ci-yaml-check.yml)

- **sanity-main.yml** : diag quotidien / dispatch / push (artefacts)
- **sanity-echo.yml** : smoke déclenchable manuellement
- **ci-yaml-check.yml** : lint/validité YAML

Voir `docs/CI.md`.
<!-- CI:END -->2\_milestones\_meta.csv
* zz-data/chapter<!-- CI:BEGIN -->
### CI (Workflows canoniques)

[![sanity-main](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-main.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-main.yml)
[![sanity-echo](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-echo.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-echo.yml)
[![ci-yaml-check](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/ci-yaml-check.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/ci-yaml-check.yml)

- **sanity-main.yml** : diag quotidien / dispatch / push (artefacts)
- **sanity-echo.yml** : smoke déclenchable manuellement
- **ci-yaml-check.yml** : lint/validité YAML

Voir `docs/CI.md`.
<!-- CI:END -->3/
  * <!-- CI:BEGIN -->
### CI (Workflows canoniques)

[![sanity-main](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-main.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-main.yml)
[![sanity-echo](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-echo.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-echo.yml)
[![ci-yaml-check](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/ci-yaml-check.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/ci-yaml-check.yml)

- **sanity-main.yml** : diag quotidien / dispatch / push (artefacts)
- **sanity-echo.yml** : smoke déclenchable manuellement
- **ci-yaml-check.yml** : lint/validité YAML

Voir `docs/CI.md`.
<!-- CI:END -->3\_fR\_stability\_meta.json
  * <!-- CI:BEGIN -->
### CI (Workflows canoniques)

[![sanity-main](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-main.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-main.yml)
[![sanity-echo](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-echo.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-echo.yml)
[![ci-yaml-check](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/ci-yaml-check.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/ci-yaml-check.yml)

- **sanity-main.yml** : diag quotidien / dispatch / push (artefacts)
- **sanity-echo.yml** : smoke déclenchable manuellement
- **ci-yaml-check.yml** : lint/validité YAML

Voir `docs/CI.md`.
<!-- CI:END -->3\_fR\_stability\_data.csv, <!-- CI:BEGIN -->
### CI (Workflows canoniques)

[![sanity-main](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-main.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-main.yml)
[![sanity-echo](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-echo.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-echo.yml)
[![ci-yaml-check](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/ci-yaml-check.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/ci-yaml-check.yml)

- **sanity-main.yml** : diag quotidien / dispatch / push (artefacts)
- **sanity-echo.yml** : smoke déclenchable manuellement
- **ci-yaml-check.yml** : lint/validité YAML

Voir `docs/CI.md`.
<!-- CI:END -->3\_fR\_stability\_domain.csv, <!-- CI:BEGIN -->
### CI (Workflows canoniques)

[![sanity-main](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-main.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-main.yml)
[![sanity-echo](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-echo.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-echo.yml)
[![ci-yaml-check](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/ci-yaml-check.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/ci-yaml-check.yml)

- **sanity-main.yml** : diag quotidien / dispatch / push (artefacts)
- **sanity-echo.yml** : smoke déclenchable manuellement
- **ci-yaml-check.yml** : lint/validité YAML

Voir `docs/CI.md`.
<!-- CI:END -->3\_fR\_stability\_boundary.csv
  * <!-- CI:BEGIN -->
### CI (Workflows canoniques)

[![sanity-main](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-main.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-main.yml)
[![sanity-echo](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-echo.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-echo.yml)
[![ci-yaml-check](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/ci-yaml-check.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/ci-yaml-check.yml)

- **sanity-main.yml** : diag quotidien / dispatch / push (artefacts)
- **sanity-echo.yml** : smoke déclenchable manuellement
- **ci-yaml-check.yml** : lint/validité YAML

Voir `docs/CI.md`.
<!-- CI:END -->3\_ricci\_fR\_vs\_T.csv, <!-- CI:BEGIN -->
### CI (Workflows canoniques)

[![sanity-main](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-main.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-main.yml)
[![sanity-echo](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-echo.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-echo.yml)
[![ci-yaml-check](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/ci-yaml-check.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/ci-yaml-check.yml)

- **sanity-main.yml** : diag quotidien / dispatch / push (artefacts)
- **sanity-echo.yml** : smoke déclenchable manuellement
- **ci-yaml-check.yml** : lint/validité YAML

Voir `docs/CI.md`.
<!-- CI:END -->3\_ricci\_fR\_vs\_z.csv, <!-- CI:BEGIN -->
### CI (Workflows canoniques)

[![sanity-main](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-main.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-main.yml)
[![sanity-echo](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-echo.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-echo.yml)
[![ci-yaml-check](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/ci-yaml-check.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/ci-yaml-check.yml)

- **sanity-main.yml** : diag quotidien / dispatch / push (artefacts)
- **sanity-echo.yml** : smoke déclenchable manuellement
- **ci-yaml-check.yml** : lint/validité YAML

Voir `docs/CI.md`.
<!-- CI:END -->3\_ricci\_fR\_milestones.csv
* zz-data/chapter<!-- CI:BEGIN -->
### CI (Workflows canoniques)

[![sanity-main](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-main.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-main.yml)
[![sanity-echo](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-echo.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-echo.yml)
[![ci-yaml-check](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/ci-yaml-check.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/ci-yaml-check.yml)

- **sanity-main.yml** : diag quotidien / dispatch / push (artefacts)
- **sanity-echo.yml** : smoke déclenchable manuellement
- **ci-yaml-check.yml** : lint/validité YAML

Voir `docs/CI.md`.
<!-- CI:END -->4/
  * <!-- CI:BEGIN -->
### CI (Workflows canoniques)

[![sanity-main](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-main.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-main.yml)
[![sanity-echo](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-echo.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-echo.yml)
[![ci-yaml-check](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/ci-yaml-check.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/ci-yaml-check.yml)

- **sanity-main.yml** : diag quotidien / dispatch / push (artefacts)
- **sanity-echo.yml** : smoke déclenchable manuellement
- **ci-yaml-check.yml** : lint/validité YAML

Voir `docs/CI.md`.
<!-- CI:END -->4\_dimensionless\_invariants.csv
  * <!-- CI:BEGIN -->
### CI (Workflows canoniques)

[![sanity-main](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-main.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-main.yml)
[![sanity-echo](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-echo.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-echo.yml)
[![ci-yaml-check](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/ci-yaml-check.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/ci-yaml-check.yml)

- **sanity-main.yml** : diag quotidien / dispatch / push (artefacts)
- **sanity-echo.yml** : smoke déclenchable manuellement
- **ci-yaml-check.yml** : lint/validité YAML

Voir `docs/CI.md`.
<!-- CI:END -->4\_P\_vs\_T.dat
* zz-data/chapter<!-- CI:BEGIN -->
### CI (Workflows canoniques)

[![sanity-main](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-main.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-main.yml)
[![sanity-echo](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-echo.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-echo.yml)
[![ci-yaml-check](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/ci-yaml-check.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/ci-yaml-check.yml)

- **sanity-main.yml** : diag quotidien / dispatch / push (artefacts)
- **sanity-echo.yml** : smoke déclenchable manuellement
- **ci-yaml-check.yml** : lint/validité YAML

Voir `docs/CI.md`.
<!-- CI:END -->5/
  * <!-- CI:BEGIN -->
### CI (Workflows canoniques)

[![sanity-main](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-main.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-main.yml)
[![sanity-echo](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-echo.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-echo.yml)
[![ci-yaml-check](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/ci-yaml-check.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/ci-yaml-check.yml)

- **sanity-main.yml** : diag quotidien / dispatch / push (artefacts)
- **sanity-echo.yml** : smoke déclenchable manuellement
- **ci-yaml-check.yml** : lint/validité YAML

Voir `docs/CI.md`.
<!-- CI:END -->5\_bbn\_params.json, <!-- CI:BEGIN -->
### CI (Workflows canoniques)

[![sanity-main](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-main.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-main.yml)
[![sanity-echo](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-echo.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-echo.yml)
[![ci-yaml-check](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/ci-yaml-check.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/ci-yaml-check.yml)

- **sanity-main.yml** : diag quotidien / dispatch / push (artefacts)
- **sanity-echo.yml** : smoke déclenchable manuellement
- **ci-yaml-check.yml** : lint/validité YAML

Voir `docs/CI.md`.
<!-- CI:END -->5\_bbn\_grid.csv
  * <!-- CI:BEGIN -->
### CI (Workflows canoniques)

[![sanity-main](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-main.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-main.yml)
[![sanity-echo](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-echo.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-echo.yml)
[![ci-yaml-check](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/ci-yaml-check.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/ci-yaml-check.yml)

- **sanity-main.yml** : diag quotidien / dispatch / push (artefacts)
- **sanity-echo.yml** : smoke déclenchable manuellement
- **ci-yaml-check.yml** : lint/validité YAML

Voir `docs/CI.md`.
<!-- CI:END -->5\_bbn\_data.csv, <!-- CI:BEGIN -->
### CI (Workflows canoniques)

[![sanity-main](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-main.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-main.yml)
[![sanity-echo](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-echo.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-echo.yml)
[![ci-yaml-check](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/ci-yaml-check.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/ci-yaml-check.yml)

- **sanity-main.yml** : diag quotidien / dispatch / push (artefacts)
- **sanity-echo.yml** : smoke déclenchable manuellement
- **ci-yaml-check.yml** : lint/validité YAML

Voir `docs/CI.md`.
<!-- CI:END -->5\_bbn\_invariants.csv
  * <!-- CI:BEGIN -->
### CI (Workflows canoniques)

[![sanity-main](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-main.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-main.yml)
[![sanity-echo](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-echo.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-echo.yml)
[![ci-yaml-check](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/ci-yaml-check.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/ci-yaml-check.yml)

- **sanity-main.yml** : diag quotidien / dispatch / push (artefacts)
- **sanity-echo.yml** : smoke déclenchable manuellement
- **ci-yaml-check.yml** : lint/validité YAML

Voir `docs/CI.md`.
<!-- CI:END -->5\_chi2\_bbn\_vs\_T.csv, <!-- CI:BEGIN -->
### CI (Workflows canoniques)

[![sanity-main](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-main.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-main.yml)
[![sanity-echo](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-echo.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-echo.yml)
[![ci-yaml-check](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/ci-yaml-check.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/ci-yaml-check.yml)

- **sanity-main.yml** : diag quotidien / dispatch / push (artefacts)
- **sanity-echo.yml** : smoke déclenchable manuellement
- **ci-yaml-check.yml** : lint/validité YAML

Voir `docs/CI.md`.
<!-- CI:END -->5\_dchi2\_vs\_T.csv
  * <!-- CI:BEGIN -->
### CI (Workflows canoniques)

[![sanity-main](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-main.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-main.yml)
[![sanity-echo](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-echo.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-echo.yml)
[![ci-yaml-check](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/ci-yaml-check.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/ci-yaml-check.yml)

- **sanity-main.yml** : diag quotidien / dispatch / push (artefacts)
- **sanity-echo.yml** : smoke déclenchable manuellement
- **ci-yaml-check.yml** : lint/validité YAML

Voir `docs/CI.md`.
<!-- CI:END -->5\_bbn\_milestones.csv
* zz-data/chapter<!-- CI:BEGIN -->
### CI (Workflows canoniques)

[![sanity-main](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-main.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-main.yml)
[![sanity-echo](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-echo.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-echo.yml)
[![ci-yaml-check](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/ci-yaml-check.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/ci-yaml-check.yml)

- **sanity-main.yml** : diag quotidien / dispatch / push (artefacts)
- **sanity-echo.yml** : smoke déclenchable manuellement
- **ci-yaml-check.yml** : lint/validité YAML

Voir `docs/CI.md`.
<!-- CI:END -->6/
  * <!-- CI:BEGIN -->
### CI (Workflows canoniques)

[![sanity-main](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-main.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-main.yml)
[![sanity-echo](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-echo.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-echo.yml)
[![ci-yaml-check](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/ci-yaml-check.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/ci-yaml-check.yml)

- **sanity-main.yml** : diag quotidien / dispatch / push (artefacts)
- **sanity-echo.yml** : smoke déclenchable manuellement
- **ci-yaml-check.yml** : lint/validité YAML

Voir `docs/CI.md`.
<!-- CI:END -->6\_params\_cmb.json
  * <!-- CI:BEGIN -->
### CI (Workflows canoniques)

[![sanity-main](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-main.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-main.yml)
[![sanity-echo](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-echo.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-echo.yml)
[![ci-yaml-check](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/ci-yaml-check.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/ci-yaml-check.yml)

- **sanity-main.yml** : diag quotidien / dispatch / push (artefacts)
- **sanity-echo.yml** : smoke déclenchable manuellement
- **ci-yaml-check.yml** : lint/validité YAML

Voir `docs/CI.md`.
<!-- CI:END -->6\_alpha\_evolution.csv
  * <!-- CI:BEGIN -->
### CI (Workflows canoniques)

[![sanity-main](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-main.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-main.yml)
[![sanity-echo](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-echo.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-echo.yml)
[![ci-yaml-check](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/ci-yaml-check.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/ci-yaml-check.yml)

- **sanity-main.yml** : diag quotidien / dispatch / push (artefacts)
- **sanity-echo.yml** : smoke déclenchable manuellement
- **ci-yaml-check.yml** : lint/validité YAML

Voir `docs/CI.md`.
<!-- CI:END -->6\_cls\_spectrum.dat, <!-- CI:BEGIN -->
### CI (Workflows canoniques)

[![sanity-main](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-main.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-main.yml)
[![sanity-echo](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-echo.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-echo.yml)
[![ci-yaml-check](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/ci-yaml-check.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/ci-yaml-check.yml)

- **sanity-main.yml** : diag quotidien / dispatch / push (artefacts)
- **sanity-echo.yml** : smoke déclenchable manuellement
- **ci-yaml-check.yml** : lint/validité YAML

Voir `docs/CI.md`.
<!-- CI:END -->6\_cls\_spectrum\_lcdm.dat
  * <!-- CI:BEGIN -->
### CI (Workflows canoniques)

[![sanity-main](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-main.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-main.yml)
[![sanity-echo](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-echo.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-echo.yml)
[![ci-yaml-check](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/ci-yaml-check.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/ci-yaml-check.yml)

- **sanity-main.yml** : diag quotidien / dispatch / push (artefacts)
- **sanity-echo.yml** : smoke déclenchable manuellement
- **ci-yaml-check.yml** : lint/validité YAML

Voir `docs/CI.md`.
<!-- CI:END -->6\_cmb\_full\_results.csv, <!-- CI:BEGIN -->
### CI (Workflows canoniques)

[![sanity-main](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-main.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-main.yml)
[![sanity-echo](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-echo.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-echo.yml)
[![ci-yaml-check](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/ci-yaml-check.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/ci-yaml-check.yml)

- **sanity-main.yml** : diag quotidien / dispatch / push (artefacts)
- **sanity-echo.yml** : smoke déclenchable manuellement
- **ci-yaml-check.yml** : lint/validité YAML

Voir `docs/CI.md`.
<!-- CI:END -->6\_cmb\_chi2\_scan2D.csv
  * <!-- CI:BEGIN -->
### CI (Workflows canoniques)

[![sanity-main](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-main.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-main.yml)
[![sanity-echo](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-echo.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-echo.yml)
[![ci-yaml-check](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/ci-yaml-check.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/ci-yaml-check.yml)

- **sanity-main.yml** : diag quotidien / dispatch / push (artefacts)
- **sanity-echo.yml** : smoke déclenchable manuellement
- **ci-yaml-check.yml** : lint/validité YAML

Voir `docs/CI.md`.
<!-- CI:END -->6\_delta\_cls.csv, <!-- CI:BEGIN -->
### CI (Workflows canoniques)

[![sanity-main](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-main.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-main.yml)
[![sanity-echo](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-echo.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-echo.yml)
[![ci-yaml-check](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/ci-yaml-check.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/ci-yaml-check.yml)

- **sanity-main.yml** : diag quotidien / dispatch / push (artefacts)
- **sanity-echo.yml** : smoke déclenchable manuellement
- **ci-yaml-check.yml** : lint/validité YAML

Voir `docs/CI.md`.
<!-- CI:END -->6\_delta\_cls\_relative.csv
  * <!-- CI:BEGIN -->
### CI (Workflows canoniques)

[![sanity-main](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-main.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-main.yml)
[![sanity-echo](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-echo.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-echo.yml)
[![ci-yaml-check](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/ci-yaml-check.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/ci-yaml-check.yml)

- **sanity-main.yml** : diag quotidien / dispatch / push (artefacts)
- **sanity-echo.yml** : smoke déclenchable manuellement
- **ci-yaml-check.yml** : lint/validité YAML

Voir `docs/CI.md`.
<!-- CI:END -->6\_delta\_rs\_scan.csv, <!-- CI:BEGIN -->
### CI (Workflows canoniques)

[![sanity-main](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-main.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-main.yml)
[![sanity-echo](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-echo.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-echo.yml)
[![ci-yaml-check](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/ci-yaml-check.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/ci-yaml-check.yml)

- **sanity-main.yml** : diag quotidien / dispatch / push (artefacts)
- **sanity-echo.yml** : smoke déclenchable manuellement
- **ci-yaml-check.yml** : lint/validité YAML

Voir `docs/CI.md`.
<!-- CI:END -->6\_delta\_rs\_scan2D.csv, <!-- CI:BEGIN -->
### CI (Workflows canoniques)

[![sanity-main](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-main.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-main.yml)
[![sanity-echo](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-echo.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-echo.yml)
[![ci-yaml-check](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/ci-yaml-check.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/ci-yaml-check.yml)

- **sanity-main.yml** : diag quotidien / dispatch / push (artefacts)
- **sanity-echo.yml** : smoke déclenchable manuellement
- **ci-yaml-check.yml** : lint/validité YAML

Voir `docs/CI.md`.
<!-- CI:END -->6\_delta\_rs\_scan\_full.csv
  * <!-- CI:BEGIN -->
### CI (Workflows canoniques)

[![sanity-main](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-main.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-main.yml)
[![sanity-echo](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-echo.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-echo.yml)
[![ci-yaml-check](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/ci-yaml-check.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/ci-yaml-check.yml)

- **sanity-main.yml** : diag quotidien / dispatch / push (artefacts)
- **sanity-echo.yml** : smoke déclenchable manuellement
- **ci-yaml-check.yml** : lint/validité YAML

Voir `docs/CI.md`.
<!-- CI:END -->6\_delta\_Tm\_scan.csv, <!-- CI:BEGIN -->
### CI (Workflows canoniques)

[![sanity-main](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-main.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-main.yml)
[![sanity-echo](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-echo.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-echo.yml)
[![ci-yaml-check](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/ci-yaml-check.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/ci-yaml-check.yml)

- **sanity-main.yml** : diag quotidien / dispatch / push (artefacts)
- **sanity-echo.yml** : smoke déclenchable manuellement
- **ci-yaml-check.yml** : lint/validité YAML

Voir `docs/CI.md`.
<!-- CI:END -->6\_hubble\_mcgt.dat
  * <!-- CI:BEGIN -->
### CI (Workflows canoniques)

[![sanity-main](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-main.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-main.yml)
[![sanity-echo](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-echo.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-echo.yml)
[![ci-yaml-check](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/ci-yaml-check.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/ci-yaml-check.yml)

- **sanity-main.yml** : diag quotidien / dispatch / push (artefacts)
- **sanity-echo.yml** : smoke déclenchable manuellement
- **ci-yaml-check.yml** : lint/validité YAML

Voir `docs/CI.md`.
<!-- CI:END -->1\_P\_vs\_T.dat
* zz-data/chapter<!-- CI:BEGIN -->
### CI (Workflows canoniques)

[![sanity-main](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-main.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-main.yml)
[![sanity-echo](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-echo.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-echo.yml)
[![ci-yaml-check](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/ci-yaml-check.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/ci-yaml-check.yml)

- **sanity-main.yml** : diag quotidien / dispatch / push (artefacts)
- **sanity-echo.yml** : smoke déclenchable manuellement
- **ci-yaml-check.yml** : lint/validité YAML

Voir `docs/CI.md`.
<!-- CI:END -->7/
  * <!-- CI:BEGIN -->
### CI (Workflows canoniques)

[![sanity-main](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-main.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-main.yml)
[![sanity-echo](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-echo.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-echo.yml)
[![ci-yaml-check](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/ci-yaml-check.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/ci-yaml-check.yml)

- **sanity-main.yml** : diag quotidien / dispatch / push (artefacts)
- **sanity-echo.yml** : smoke déclenchable manuellement
- **ci-yaml-check.yml** : lint/validité YAML

Voir `docs/CI.md`.
<!-- CI:END -->7\_perturbations\_params.json, <!-- CI:BEGIN -->
### CI (Workflows canoniques)

[![sanity-main](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-main.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-main.yml)
[![sanity-echo](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-echo.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-echo.yml)
[![ci-yaml-check](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/ci-yaml-check.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/ci-yaml-check.yml)

- **sanity-main.yml** : diag quotidien / dispatch / push (artefacts)
- **sanity-echo.yml** : smoke déclenchable manuellement
- **ci-yaml-check.yml** : lint/validité YAML

Voir `docs/CI.md`.
<!-- CI:END -->7\_perturbations\_meta.json
  * <!-- CI:BEGIN -->
### CI (Workflows canoniques)

[![sanity-main](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-main.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-main.yml)
[![sanity-echo](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-echo.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-echo.yml)
[![ci-yaml-check](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/ci-yaml-check.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/ci-yaml-check.yml)

- **sanity-main.yml** : diag quotidien / dispatch / push (artefacts)
- **sanity-echo.yml** : smoke déclenchable manuellement
- **ci-yaml-check.yml** : lint/validité YAML

Voir `docs/CI.md`.
<!-- CI:END -->7\_cs2\_matrix.csv, <!-- CI:BEGIN -->
### CI (Workflows canoniques)

[![sanity-main](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-main.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-main.yml)
[![sanity-echo](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-echo.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-echo.yml)
[![ci-yaml-check](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/ci-yaml-check.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/ci-yaml-check.yml)

- **sanity-main.yml** : diag quotidien / dispatch / push (artefacts)
- **sanity-echo.yml** : smoke déclenchable manuellement
- **ci-yaml-check.yml** : lint/validité YAML

Voir `docs/CI.md`.
<!-- CI:END -->7\_delta\_phi\_matrix.csv
  * <!-- CI:BEGIN -->
### CI (Workflows canoniques)

[![sanity-main](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-main.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-main.yml)
[![sanity-echo](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-echo.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-echo.yml)
[![ci-yaml-check](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/ci-yaml-check.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/ci-yaml-check.yml)

- **sanity-main.yml** : diag quotidien / dispatch / push (artefacts)
- **sanity-echo.yml** : smoke déclenchable manuellement
- **ci-yaml-check.yml** : lint/validité YAML

Voir `docs/CI.md`.
<!-- CI:END -->7\_dcs2\_vs\_k.csv, <!-- CI:BEGIN -->
### CI (Workflows canoniques)

[![sanity-main](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-main.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-main.yml)
[![sanity-echo](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-echo.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-echo.yml)
[![ci-yaml-check](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/ci-yaml-check.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/ci-yaml-check.yml)

- **sanity-main.yml** : diag quotidien / dispatch / push (artefacts)
- **sanity-echo.yml** : smoke déclenchable manuellement
- **ci-yaml-check.yml** : lint/validité YAML

Voir `docs/CI.md`.
<!-- CI:END -->7\_ddelta\_phi\_vs\_k.csv
  * <!-- CI:BEGIN -->
### CI (Workflows canoniques)

[![sanity-main](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-main.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-main.yml)
[![sanity-echo](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-echo.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-echo.yml)
[![ci-yaml-check](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/ci-yaml-check.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/ci-yaml-check.yml)

- **sanity-main.yml** : diag quotidien / dispatch / push (artefacts)
- **sanity-echo.yml** : smoke déclenchable manuellement
- **ci-yaml-check.yml** : lint/validité YAML

Voir `docs/CI.md`.
<!-- CI:END -->7\_perturbations\_domain.csv, <!-- CI:BEGIN -->
### CI (Workflows canoniques)

[![sanity-main](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-main.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-main.yml)
[![sanity-echo](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-echo.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-echo.yml)
[![ci-yaml-check](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/ci-yaml-check.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/ci-yaml-check.yml)

- **sanity-main.yml** : diag quotidien / dispatch / push (artefacts)
- **sanity-echo.yml** : smoke déclenchable manuellement
- **ci-yaml-check.yml** : lint/validité YAML

Voir `docs/CI.md`.
<!-- CI:END -->7\_perturbations\_boundary.csv
  * <!-- CI:BEGIN -->
### CI (Workflows canoniques)

[![sanity-main](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-main.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-main.yml)
[![sanity-echo](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-echo.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-echo.yml)
[![ci-yaml-check](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/ci-yaml-check.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/ci-yaml-check.yml)

- **sanity-main.yml** : diag quotidien / dispatch / push (artefacts)
- **sanity-echo.yml** : smoke déclenchable manuellement
- **ci-yaml-check.yml** : lint/validité YAML

Voir `docs/CI.md`.
<!-- CI:END -->7\_scalar\_invariants.csv, <!-- CI:BEGIN -->
### CI (Workflows canoniques)

[![sanity-main](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-main.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-main.yml)
[![sanity-echo](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-echo.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-echo.yml)
[![ci-yaml-check](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/ci-yaml-check.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/ci-yaml-check.yml)

- **sanity-main.yml** : diag quotidien / dispatch / push (artefacts)
- **sanity-echo.yml** : smoke déclenchable manuellement
- **ci-yaml-check.yml** : lint/validité YAML

Voir `docs/CI.md`.
<!-- CI:END -->7\_phase\_run.csv
  * <!-- CI:BEGIN -->
### CI (Workflows canoniques)

[![sanity-main](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-main.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-main.yml)
[![sanity-echo](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-echo.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-echo.yml)
[![ci-yaml-check](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/ci-yaml-check.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/ci-yaml-check.yml)

- **sanity-main.yml** : diag quotidien / dispatch / push (artefacts)
- **sanity-echo.yml** : smoke déclenchable manuellement
- **ci-yaml-check.yml** : lint/validité YAML

Voir `docs/CI.md`.
<!-- CI:END -->7\_perturbations\_main\_data.csv, <!-- CI:BEGIN -->
### CI (Workflows canoniques)

[![sanity-main](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-main.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-main.yml)
[![sanity-echo](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-echo.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-echo.yml)
[![ci-yaml-check](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/ci-yaml-check.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/ci-yaml-check.yml)

- **sanity-main.yml** : diag quotidien / dispatch / push (artefacts)
- **sanity-echo.yml** : smoke déclenchable manuellement
- **ci-yaml-check.yml** : lint/validité YAML

Voir `docs/CI.md`.
<!-- CI:END -->7\_scalar\_perturbations\_results.csv
* zz-data/chapter<!-- CI:BEGIN -->
### CI (Workflows canoniques)

[![sanity-main](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-main.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-main.yml)
[![sanity-echo](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-echo.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-echo.yml)
[![ci-yaml-check](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/ci-yaml-check.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/ci-yaml-check.yml)

- **sanity-main.yml** : diag quotidien / dispatch / push (artefacts)
- **sanity-echo.yml** : smoke déclenchable manuellement
- **ci-yaml-check.yml** : lint/validité YAML

Voir `docs/CI.md`.
<!-- CI:END -->8/
  * <!-- CI:BEGIN -->
### CI (Workflows canoniques)

[![sanity-main](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-main.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-main.yml)
[![sanity-echo](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-echo.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-echo.yml)
[![ci-yaml-check](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/ci-yaml-check.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/ci-yaml-check.yml)

- **sanity-main.yml** : diag quotidien / dispatch / push (artefacts)
- **sanity-echo.yml** : smoke déclenchable manuellement
- **ci-yaml-check.yml** : lint/validité YAML

Voir `docs/CI.md`.
<!-- CI:END -->8\_coupling\_params.json, <!-- CI:BEGIN -->
### CI (Workflows canoniques)

[![sanity-main](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-main.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-main.yml)
[![sanity-echo](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-echo.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-echo.yml)
[![ci-yaml-check](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/ci-yaml-check.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/ci-yaml-check.yml)

- **sanity-main.yml** : diag quotidien / dispatch / push (artefacts)
- **sanity-echo.yml** : smoke déclenchable manuellement
- **ci-yaml-check.yml** : lint/validité YAML

Voir `docs/CI.md`.
<!-- CI:END -->8\_chi2\_scan2D.csv, <!-- CI:BEGIN -->
### CI (Workflows canoniques)

[![sanity-main](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-main.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-main.yml)
[![sanity-echo](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-echo.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-echo.yml)
[![ci-yaml-check](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/ci-yaml-check.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/ci-yaml-check.yml)

- **sanity-main.yml** : diag quotidien / dispatch / push (artefacts)
- **sanity-echo.yml** : smoke déclenchable manuellement
- **ci-yaml-check.yml** : lint/validité YAML

Voir `docs/CI.md`.
<!-- CI:END -->8\_chi2\_total\_vs\_q<!-- CI:BEGIN -->
### CI (Workflows canoniques)

[![sanity-main](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-main.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-main.yml)
[![sanity-echo](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-echo.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-echo.yml)
[![ci-yaml-check](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/ci-yaml-check.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/ci-yaml-check.yml)

- **sanity-main.yml** : diag quotidien / dispatch / push (artefacts)
- **sanity-echo.yml** : smoke déclenchable manuellement
- **ci-yaml-check.yml** : lint/validité YAML

Voir `docs/CI.md`.
<!-- CI:END -->.csv
  * <!-- CI:BEGIN -->
### CI (Workflows canoniques)

[![sanity-main](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-main.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-main.yml)
[![sanity-echo](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-echo.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-echo.yml)
[![ci-yaml-check](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/ci-yaml-check.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/ci-yaml-check.yml)

- **sanity-main.yml** : diag quotidien / dispatch / push (artefacts)
- **sanity-echo.yml** : smoke déclenchable manuellement
- **ci-yaml-check.yml** : lint/validité YAML

Voir `docs/CI.md`.
<!-- CI:END -->8\_bao\_data.csv, <!-- CI:BEGIN -->
### CI (Workflows canoniques)

[![sanity-main](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-main.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-main.yml)
[![sanity-echo](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-echo.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-echo.yml)
[![ci-yaml-check](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/ci-yaml-check.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/ci-yaml-check.yml)

- **sanity-main.yml** : diag quotidien / dispatch / push (artefacts)
- **sanity-echo.yml** : smoke déclenchable manuellement
- **ci-yaml-check.yml** : lint/validité YAML

Voir `docs/CI.md`.
<!-- CI:END -->8\_pantheon\_data.csv
  * <!-- CI:BEGIN -->
### CI (Workflows canoniques)

[![sanity-main](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-main.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-main.yml)
[![sanity-echo](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-echo.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-echo.yml)
[![ci-yaml-check](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/ci-yaml-check.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/ci-yaml-check.yml)

- **sanity-main.yml** : diag quotidien / dispatch / push (artefacts)
- **sanity-echo.yml** : smoke déclenchable manuellement
- **ci-yaml-check.yml** : lint/validité YAML

Voir `docs/CI.md`.
<!-- CI:END -->8\_dv\_theory\_z.csv, <!-- CI:BEGIN -->
### CI (Workflows canoniques)

[![sanity-main](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-main.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-main.yml)
[![sanity-echo](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-echo.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-echo.yml)
[![ci-yaml-check](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/ci-yaml-check.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/ci-yaml-check.yml)

- **sanity-main.yml** : diag quotidien / dispatch / push (artefacts)
- **sanity-echo.yml** : smoke déclenchable manuellement
- **ci-yaml-check.yml** : lint/validité YAML

Voir `docs/CI.md`.
<!-- CI:END -->8\_dv\_theory\_q<!-- CI:BEGIN -->
### CI (Workflows canoniques)

[![sanity-main](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-main.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-main.yml)
[![sanity-echo](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-echo.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-echo.yml)
[![ci-yaml-check](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/ci-yaml-check.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/ci-yaml-check.yml)

- **sanity-main.yml** : diag quotidien / dispatch / push (artefacts)
- **sanity-echo.yml** : smoke déclenchable manuellement
- **ci-yaml-check.yml** : lint/validité YAML

Voir `docs/CI.md`.
<!-- CI:END -->star.csv
  * <!-- CI:BEGIN -->
### CI (Workflows canoniques)

[![sanity-main](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-main.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-main.yml)
[![sanity-echo](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-echo.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-echo.yml)
[![ci-yaml-check](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/ci-yaml-check.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/ci-yaml-check.yml)

- **sanity-main.yml** : diag quotidien / dispatch / push (artefacts)
- **sanity-echo.yml** : smoke déclenchable manuellement
- **ci-yaml-check.yml** : lint/validité YAML

Voir `docs/CI.md`.
<!-- CI:END -->8\_mu\_theory\_z.csv, <!-- CI:BEGIN -->
### CI (Workflows canoniques)

[![sanity-main](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-main.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-main.yml)
[![sanity-echo](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-echo.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-echo.yml)
[![ci-yaml-check](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/ci-yaml-check.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/ci-yaml-check.yml)

- **sanity-main.yml** : diag quotidien / dispatch / push (artefacts)
- **sanity-echo.yml** : smoke déclenchable manuellement
- **ci-yaml-check.yml** : lint/validité YAML

Voir `docs/CI.md`.
<!-- CI:END -->8\_mu\_theory\_q<!-- CI:BEGIN -->
### CI (Workflows canoniques)

[![sanity-main](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-main.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-main.yml)
[![sanity-echo](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-echo.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-echo.yml)
[![ci-yaml-check](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/ci-yaml-check.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/ci-yaml-check.yml)

- **sanity-main.yml** : diag quotidien / dispatch / push (artefacts)
- **sanity-echo.yml** : smoke déclenchable manuellement
- **ci-yaml-check.yml** : lint/validité YAML

Voir `docs/CI.md`.
<!-- CI:END -->star.csv
  * <!-- CI:BEGIN -->
### CI (Workflows canoniques)

[![sanity-main](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-main.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-main.yml)
[![sanity-echo](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-echo.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-echo.yml)
[![ci-yaml-check](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/ci-yaml-check.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/ci-yaml-check.yml)

- **sanity-main.yml** : diag quotidien / dispatch / push (artefacts)
- **sanity-echo.yml** : smoke déclenchable manuellement
- **ci-yaml-check.yml** : lint/validité YAML

Voir `docs/CI.md`.
<!-- CI:END -->8\_coupling\_milestones.csv, <!-- CI:BEGIN -->
### CI (Workflows canoniques)

[![sanity-main](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-main.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-main.yml)
[![sanity-echo](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-echo.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-echo.yml)
[![ci-yaml-check](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/ci-yaml-check.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/ci-yaml-check.yml)

- **sanity-main.yml** : diag quotidien / dispatch / push (artefacts)
- **sanity-echo.yml** : smoke déclenchable manuellement
- **ci-yaml-check.yml** : lint/validité YAML

Voir `docs/CI.md`.
<!-- CI:END -->8\_chi2\_derivative.csv
* zz-data/chapter<!-- CI:BEGIN -->
### CI (Workflows canoniques)

[![sanity-main](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-main.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-main.yml)
[![sanity-echo](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-echo.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-echo.yml)
[![ci-yaml-check](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/ci-yaml-check.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/ci-yaml-check.yml)

- **sanity-main.yml** : diag quotidien / dispatch / push (artefacts)
- **sanity-echo.yml** : smoke déclenchable manuellement
- **ci-yaml-check.yml** : lint/validité YAML

Voir `docs/CI.md`.
<!-- CI:END -->9/
  * <!-- CI:BEGIN -->
### CI (Workflows canoniques)

[![sanity-main](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-main.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-main.yml)
[![sanity-echo](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-echo.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-echo.yml)
[![ci-yaml-check](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/ci-yaml-check.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/ci-yaml-check.yml)

- **sanity-main.yml** : diag quotidien / dispatch / push (artefacts)
- **sanity-echo.yml** : smoke déclenchable manuellement
- **ci-yaml-check.yml** : lint/validité YAML

Voir `docs/CI.md`.
<!-- CI:END -->9\_best\_params.json
  * <!-- CI:BEGIN -->
### CI (Workflows canoniques)

[![sanity-main](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-main.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-main.yml)
[![sanity-echo](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-echo.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-echo.yml)
[![ci-yaml-check](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/ci-yaml-check.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/ci-yaml-check.yml)

- **sanity-main.yml** : diag quotidien / dispatch / push (artefacts)
- **sanity-echo.yml** : smoke déclenchable manuellement
- **ci-yaml-check.yml** : lint/validité YAML

Voir `docs/CI.md`.
<!-- CI:END -->9\_metrics\_phase.json, <!-- CI:BEGIN -->
### CI (Workflows canoniques)

[![sanity-main](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-main.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-main.yml)
[![sanity-echo](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-echo.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-echo.yml)
[![ci-yaml-check](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/ci-yaml-check.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/ci-yaml-check.yml)

- **sanity-main.yml** : diag quotidien / dispatch / push (artefacts)
- **sanity-echo.yml** : smoke déclenchable manuellement
- **ci-yaml-check.yml** : lint/validité YAML

Voir `docs/CI.md`.
<!-- CI:END -->9\_comparison\_milestones.csv (+ .meta.json, .flagged.csv)
  * <!-- CI:BEGIN -->
### CI (Workflows canoniques)

[![sanity-main](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-main.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-main.yml)
[![sanity-echo](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-echo.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-echo.yml)
[![ci-yaml-check](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/ci-yaml-check.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/ci-yaml-check.yml)

- **sanity-main.yml** : diag quotidien / dispatch / push (artefacts)
- **sanity-echo.yml** : smoke déclenchable manuellement
- **ci-yaml-check.yml** : lint/validité YAML

Voir `docs/CI.md`.
<!-- CI:END -->9\_phases\_imrphenom.csv (+ .meta.json)
  * <!-- CI:BEGIN -->
### CI (Workflows canoniques)

[![sanity-main](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-main.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-main.yml)
[![sanity-echo](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-echo.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-echo.yml)
[![ci-yaml-check](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/ci-yaml-check.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/ci-yaml-check.yml)

- **sanity-main.yml** : diag quotidien / dispatch / push (artefacts)
- **sanity-echo.yml** : smoke déclenchable manuellement
- **ci-yaml-check.yml** : lint/validité YAML

Voir `docs/CI.md`.
<!-- CI:END -->9\_phases\_mcgt.csv, <!-- CI:BEGIN -->
### CI (Workflows canoniques)

[![sanity-main](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-main.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-main.yml)
[![sanity-echo](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-echo.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-echo.yml)
[![ci-yaml-check](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/ci-yaml-check.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/ci-yaml-check.yml)

- **sanity-main.yml** : diag quotidien / dispatch / push (artefacts)
- **sanity-echo.yml** : smoke déclenchable manuellement
- **ci-yaml-check.yml** : lint/validité YAML

Voir `docs/CI.md`.
<!-- CI:END -->9\_phases\_mcgt\_prepoly.csv
  * <!-- CI:BEGIN -->
### CI (Workflows canoniques)

[![sanity-main](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-main.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-main.yml)
[![sanity-echo](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-echo.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-echo.yml)
[![ci-yaml-check](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/ci-yaml-check.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/ci-yaml-check.yml)

- **sanity-main.yml** : diag quotidien / dispatch / push (artefacts)
- **sanity-echo.yml** : smoke déclenchable manuellement
- **ci-yaml-check.yml** : lint/validité YAML

Voir `docs/CI.md`.
<!-- CI:END -->9\_phase\_diff.csv, gwtc3\_confident\_parameters.json
* zz-data/chapter1<!-- CI:BEGIN -->
### CI (Workflows canoniques)

[![sanity-main](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-main.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-main.yml)
[![sanity-echo](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-echo.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-echo.yml)
[![ci-yaml-check](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/ci-yaml-check.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/ci-yaml-check.yml)

- **sanity-main.yml** : diag quotidien / dispatch / push (artefacts)
- **sanity-echo.yml** : smoke déclenchable manuellement
- **ci-yaml-check.yml** : lint/validité YAML

Voir `docs/CI.md`.
<!-- CI:END -->/
  * 1<!-- CI:BEGIN -->
### CI (Workflows canoniques)

[![sanity-main](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-main.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-main.yml)
[![sanity-echo](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-echo.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-echo.yml)
[![ci-yaml-check](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/ci-yaml-check.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/ci-yaml-check.yml)

- **sanity-main.yml** : diag quotidien / dispatch / push (artefacts)
- **sanity-echo.yml** : smoke déclenchable manuellement
- **ci-yaml-check.yml** : lint/validité YAML

Voir `docs/CI.md`.
<!-- CI:END -->\_mc\_config.json
  * 1<!-- CI:BEGIN -->
### CI (Workflows canoniques)

[![sanity-main](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-main.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-main.yml)
[![sanity-echo](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-echo.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-echo.yml)
[![ci-yaml-check](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/ci-yaml-check.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/ci-yaml-check.yml)

- **sanity-main.yml** : diag quotidien / dispatch / push (artefacts)
- **sanity-echo.yml** : smoke déclenchable manuellement
- **ci-yaml-check.yml** : lint/validité YAML

Voir `docs/CI.md`.
<!-- CI:END -->\_mc\_results.csv (+ variantes .circ.csv, .agg.csv, .circ.with\_fpeak.csv)
  * 1<!-- CI:BEGIN -->
### CI (Workflows canoniques)

[![sanity-main](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-main.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-main.yml)
[![sanity-echo](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-echo.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-echo.yml)
[![ci-yaml-check](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/ci-yaml-check.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/ci-yaml-check.yml)

- **sanity-main.yml** : diag quotidien / dispatch / push (artefacts)
- **sanity-echo.yml** : smoke déclenchable manuellement
- **ci-yaml-check.yml** : lint/validité YAML

Voir `docs/CI.md`.
<!-- CI:END -->\_mc\_samples.csv, 1<!-- CI:BEGIN -->
### CI (Workflows canoniques)

[![sanity-main](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-main.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-main.yml)
[![sanity-echo](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-echo.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-echo.yml)
[![ci-yaml-check](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/ci-yaml-check.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/ci-yaml-check.yml)

- **sanity-main.yml** : diag quotidien / dispatch / push (artefacts)
- **sanity-echo.yml** : smoke déclenchable manuellement
- **ci-yaml-check.yml** : lint/validité YAML

Voir `docs/CI.md`.
<!-- CI:END -->\_mc\_milestones\_eval.csv
  * 1<!-- CI:BEGIN -->
### CI (Workflows canoniques)

[![sanity-main](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-main.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-main.yml)
[![sanity-echo](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-echo.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-echo.yml)
[![ci-yaml-check](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/ci-yaml-check.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/ci-yaml-check.yml)

- **sanity-main.yml** : diag quotidien / dispatch / push (artefacts)
- **sanity-echo.yml** : smoke déclenchable manuellement
- **ci-yaml-check.yml** : lint/validité YAML

Voir `docs/CI.md`.
<!-- CI:END -->\_mc\_best.json, 1<!-- CI:BEGIN -->
### CI (Workflows canoniques)

[![sanity-main](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-main.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-main.yml)
[![sanity-echo](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-echo.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-echo.yml)
[![ci-yaml-check](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/ci-yaml-check.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/ci-yaml-check.yml)

- **sanity-main.yml** : diag quotidien / dispatch / push (artefacts)
- **sanity-echo.yml** : smoke déclenchable manuellement
- **ci-yaml-check.yml** : lint/validité YAML

Voir `docs/CI.md`.
<!-- CI:END -->\_mc\_best\_bootstrap.json
---
## 5) Scripts (zz-scripts/)
Chaque chapitre dispose de générateurs de données generate\_data\_chapterXX.py et de traceurs plot\_fig\*.py. Exemples :
* zz-scripts/chapter<!-- CI:BEGIN -->
### CI (Workflows canoniques)

[![sanity-main](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-main.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-main.yml)
[![sanity-echo](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-echo.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-echo.yml)
[![ci-yaml-check](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/ci-yaml-check.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/ci-yaml-check.yml)

- **sanity-main.yml** : diag quotidien / dispatch / push (artefacts)
- **sanity-echo.yml** : smoke déclenchable manuellement
- **ci-yaml-check.yml** : lint/validité YAML

Voir `docs/CI.md`.
<!-- CI:END -->1/
  * generate\_data\_chapter<!-- CI:BEGIN -->
### CI (Workflows canoniques)

[![sanity-main](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-main.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-main.yml)
[![sanity-echo](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-echo.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-echo.yml)
[![ci-yaml-check](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/ci-yaml-check.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/ci-yaml-check.yml)

- **sanity-main.yml** : diag quotidien / dispatch / push (artefacts)
- **sanity-echo.yml** : smoke déclenchable manuellement
- **ci-yaml-check.yml** : lint/validité YAML

Voir `docs/CI.md`.
<!-- CI:END -->1.py, plot\_fig<!-- CI:BEGIN -->
### CI (Workflows canoniques)

[![sanity-main](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-main.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-main.yml)
[![sanity-echo](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-echo.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-echo.yml)
[![ci-yaml-check](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/ci-yaml-check.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/ci-yaml-check.yml)

- **sanity-main.yml** : diag quotidien / dispatch / push (artefacts)
- **sanity-echo.yml** : smoke déclenchable manuellement
- **ci-yaml-check.yml** : lint/validité YAML

Voir `docs/CI.md`.
<!-- CI:END -->1\_early\_plateau.py, plot\_fig<!-- CI:BEGIN -->
### CI (Workflows canoniques)

[![sanity-main](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-main.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-main.yml)
[![sanity-echo](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-echo.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-echo.yml)
[![ci-yaml-check](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/ci-yaml-check.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/ci-yaml-check.yml)

- **sanity-main.yml** : diag quotidien / dispatch / push (artefacts)
- **sanity-echo.yml** : smoke déclenchable manuellement
- **ci-yaml-check.yml** : lint/validité YAML

Voir `docs/CI.md`.
<!-- CI:END -->2\_logistic\_calibration.py, plot\_fig<!-- CI:BEGIN -->
### CI (Workflows canoniques)

[![sanity-main](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-main.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-main.yml)
[![sanity-echo](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-echo.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-echo.yml)
[![ci-yaml-check](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/ci-yaml-check.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/ci-yaml-check.yml)

- **sanity-main.yml** : diag quotidien / dispatch / push (artefacts)
- **sanity-echo.yml** : smoke déclenchable manuellement
- **ci-yaml-check.yml** : lint/validité YAML

Voir `docs/CI.md`.
<!-- CI:END -->3\_relative\_error\_timeline.py, plot\_fig<!-- CI:BEGIN -->
### CI (Workflows canoniques)

[![sanity-main](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-main.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-main.yml)
[![sanity-echo](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-echo.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-echo.yml)
[![ci-yaml-check](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/ci-yaml-check.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/ci-yaml-check.yml)

- **sanity-main.yml** : diag quotidien / dispatch / push (artefacts)
- **sanity-echo.yml** : smoke déclenchable manuellement
- **ci-yaml-check.yml** : lint/validité YAML

Voir `docs/CI.md`.
<!-- CI:END -->4\_P\_vs\_T\_evolution.py, plot\_fig<!-- CI:BEGIN -->
### CI (Workflows canoniques)

[![sanity-main](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-main.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-main.yml)
[![sanity-echo](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-echo.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-echo.yml)
[![ci-yaml-check](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/ci-yaml-check.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/ci-yaml-check.yml)

- **sanity-main.yml** : diag quotidien / dispatch / push (artefacts)
- **sanity-echo.yml** : smoke déclenchable manuellement
- **ci-yaml-check.yml** : lint/validité YAML

Voir `docs/CI.md`.
<!-- CI:END -->5\_I1\_vs\_T.py, plot\_fig<!-- CI:BEGIN -->
### CI (Workflows canoniques)

[![sanity-main](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-main.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-main.yml)
[![sanity-echo](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-echo.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-echo.yml)
[![ci-yaml-check](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/ci-yaml-check.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/ci-yaml-check.yml)

- **sanity-main.yml** : diag quotidien / dispatch / push (artefacts)
- **sanity-echo.yml** : smoke déclenchable manuellement
- **ci-yaml-check.yml** : lint/validité YAML

Voir `docs/CI.md`.
<!-- CI:END -->6\_P\_derivative\_comparison.py, requirements.txt
* zz-scripts/chapter<!-- CI:BEGIN -->
### CI (Workflows canoniques)

[![sanity-main](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-main.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-main.yml)
[![sanity-echo](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-echo.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-echo.yml)
[![ci-yaml-check](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/ci-yaml-check.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/ci-yaml-check.yml)

- **sanity-main.yml** : diag quotidien / dispatch / push (artefacts)
- **sanity-echo.yml** : smoke déclenchable manuellement
- **ci-yaml-check.yml** : lint/validité YAML

Voir `docs/CI.md`.
<!-- CI:END -->2/
  * extract\_sympy\_FG.ipynb
  * generate\_data\_chapter<!-- CI:BEGIN -->
### CI (Workflows canoniques)

[![sanity-main](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-main.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-main.yml)
[![sanity-echo](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-echo.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-echo.yml)
[![ci-yaml-check](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/ci-yaml-check.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/ci-yaml-check.yml)

- **sanity-main.yml** : diag quotidien / dispatch / push (artefacts)
- **sanity-echo.yml** : smoke déclenchable manuellement
- **ci-yaml-check.yml** : lint/validité YAML

Voir `docs/CI.md`.
<!-- CI:END -->2.py, primordial\_spectrum.py, plot\_fig<!-- CI:BEGIN -->
### CI (Workflows canoniques)

[![sanity-main](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-main.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-main.yml)
[![sanity-echo](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-echo.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-echo.yml)
[![ci-yaml-check](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/ci-yaml-check.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/ci-yaml-check.yml)

- **sanity-main.yml** : diag quotidien / dispatch / push (artefacts)
- **sanity-echo.yml** : smoke déclenchable manuellement
- **ci-yaml-check.yml** : lint/validité YAML

Voir `docs/CI.md`.
<!-- CI:END --><!-- CI:BEGIN -->
### CI (Workflows canoniques)

[![sanity-main](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-main.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-main.yml)
[![sanity-echo](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-echo.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-echo.yml)
[![ci-yaml-check](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/ci-yaml-check.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/ci-yaml-check.yml)

- **sanity-main.yml** : diag quotidien / dispatch / push (artefacts)
- **sanity-echo.yml** : smoke déclenchable manuellement
- **ci-yaml-check.yml** : lint/validité YAML

Voir `docs/CI.md`.
<!-- CI:END -->\_spectrum.py, plot\_fig<!-- CI:BEGIN -->
### CI (Workflows canoniques)

[![sanity-main](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-main.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-main.yml)
[![sanity-echo](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-echo.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-echo.yml)
[![ci-yaml-check](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/ci-yaml-check.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/ci-yaml-check.yml)

- **sanity-main.yml** : diag quotidien / dispatch / push (artefacts)
- **sanity-echo.yml** : smoke déclenchable manuellement
- **ci-yaml-check.yml** : lint/validité YAML

Voir `docs/CI.md`.
<!-- CI:END -->1\_P\_vs\_T\_evolution.py, plot\_fig<!-- CI:BEGIN -->
### CI (Workflows canoniques)

[![sanity-main](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-main.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-main.yml)
[![sanity-echo](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-echo.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-echo.yml)
[![ci-yaml-check](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/ci-yaml-check.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/ci-yaml-check.yml)

- **sanity-main.yml** : diag quotidien / dispatch / push (artefacts)
- **sanity-echo.yml** : smoke déclenchable manuellement
- **ci-yaml-check.yml** : lint/validité YAML

Voir `docs/CI.md`.
<!-- CI:END -->2\_calibration.py, plot\_fig<!-- CI:BEGIN -->
### CI (Workflows canoniques)

[![sanity-main](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-main.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-main.yml)
[![sanity-echo](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-echo.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-echo.yml)
[![ci-yaml-check](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/ci-yaml-check.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/ci-yaml-check.yml)

- **sanity-main.yml** : diag quotidien / dispatch / push (artefacts)
- **sanity-echo.yml** : smoke déclenchable manuellement
- **ci-yaml-check.yml** : lint/validité YAML

Voir `docs/CI.md`.
<!-- CI:END -->3\_relative\_errors.py, plot\_fig<!-- CI:BEGIN -->
### CI (Workflows canoniques)

[![sanity-main](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-main.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-main.yml)
[![sanity-echo](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-echo.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-echo.yml)
[![ci-yaml-check](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/ci-yaml-check.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/ci-yaml-check.yml)

- **sanity-main.yml** : diag quotidien / dispatch / push (artefacts)
- **sanity-echo.yml** : smoke déclenchable manuellement
- **ci-yaml-check.yml** : lint/validité YAML

Voir `docs/CI.md`.
<!-- CI:END -->4\_pipeline\_diagram.py, plot\_fig<!-- CI:BEGIN -->
### CI (Workflows canoniques)

[![sanity-main](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-main.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-main.yml)
[![sanity-echo](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-echo.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-echo.yml)
[![ci-yaml-check](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/ci-yaml-check.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/ci-yaml-check.yml)

- **sanity-main.yml** : diag quotidien / dispatch / push (artefacts)
- **sanity-echo.yml** : smoke déclenchable manuellement
- **ci-yaml-check.yml** : lint/validité YAML

Voir `docs/CI.md`.
<!-- CI:END -->5\_FG\_series.py, plot\_fig<!-- CI:BEGIN -->
### CI (Workflows canoniques)

[![sanity-main](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-main.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-main.yml)
[![sanity-echo](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-echo.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-echo.yml)
[![ci-yaml-check](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/ci-yaml-check.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/ci-yaml-check.yml)

- **sanity-main.yml** : diag quotidien / dispatch / push (artefacts)
- **sanity-echo.yml** : smoke déclenchable manuellement
- **ci-yaml-check.yml** : lint/validité YAML

Voir `docs/CI.md`.
<!-- CI:END -->6\_alpha\_fit.py, requirements.txt
* zz-scripts/chapter<!-- CI:BEGIN -->
### CI (Workflows canoniques)

[![sanity-main](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-main.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-main.yml)
[![sanity-echo](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-echo.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-echo.yml)
[![ci-yaml-check](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/ci-yaml-check.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/ci-yaml-check.yml)

- **sanity-main.yml** : diag quotidien / dispatch / push (artefacts)
- **sanity-echo.yml** : smoke déclenchable manuellement
- **ci-yaml-check.yml** : lint/validité YAML

Voir `docs/CI.md`.
<!-- CI:END -->3/
  * generate\_data\_chapter<!-- CI:BEGIN -->
### CI (Workflows canoniques)

[![sanity-main](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-main.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-main.yml)
[![sanity-echo](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-echo.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-echo.yml)
[![ci-yaml-check](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/ci-yaml-check.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/ci-yaml-check.yml)

- **sanity-main.yml** : diag quotidien / dispatch / push (artefacts)
- **sanity-echo.yml** : smoke déclenchable manuellement
- **ci-yaml-check.yml** : lint/validité YAML

Voir `docs/CI.md`.
<!-- CI:END -->3.py, plot\_fig<!-- CI:BEGIN -->
### CI (Workflows canoniques)

[![sanity-main](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-main.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-main.yml)
[![sanity-echo](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-echo.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-echo.yml)
[![ci-yaml-check](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/ci-yaml-check.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/ci-yaml-check.yml)

- **sanity-main.yml** : diag quotidien / dispatch / push (artefacts)
- **sanity-echo.yml** : smoke déclenchable manuellement
- **ci-yaml-check.yml** : lint/validité YAML

Voir `docs/CI.md`.
<!-- CI:END -->1\_fR\_stability\_domain.py, plot\_fig<!-- CI:BEGIN -->
### CI (Workflows canoniques)

[![sanity-main](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-main.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-main.yml)
[![sanity-echo](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-echo.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-echo.yml)
[![ci-yaml-check](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/ci-yaml-check.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/ci-yaml-check.yml)

- **sanity-main.yml** : diag quotidien / dispatch / push (artefacts)
- **sanity-echo.yml** : smoke déclenchable manuellement
- **ci-yaml-check.yml** : lint/validité YAML

Voir `docs/CI.md`.
<!-- CI:END -->2\_fR\_fRR\_vs\_f.py, plot\_fig<!-- CI:BEGIN -->
### CI (Workflows canoniques)

[![sanity-main](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-main.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-main.yml)
[![sanity-echo](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-echo.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-echo.yml)
[![ci-yaml-check](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/ci-yaml-check.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/ci-yaml-check.yml)

- **sanity-main.yml** : diag quotidien / dispatch / push (artefacts)
- **sanity-echo.yml** : smoke déclenchable manuellement
- **ci-yaml-check.yml** : lint/validité YAML

Voir `docs/CI.md`.
<!-- CI:END -->3\_ms2\_R<!-- CI:BEGIN -->
### CI (Workflows canoniques)

[![sanity-main](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-main.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-main.yml)
[![sanity-echo](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-echo.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-echo.yml)
[![ci-yaml-check](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/ci-yaml-check.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/ci-yaml-check.yml)

- **sanity-main.yml** : diag quotidien / dispatch / push (artefacts)
- **sanity-echo.yml** : smoke déclenchable manuellement
- **ci-yaml-check.yml** : lint/validité YAML

Voir `docs/CI.md`.
<!-- CI:END -->\_vs\_f.py, plot\_fig<!-- CI:BEGIN -->
### CI (Workflows canoniques)

[![sanity-main](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-main.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-main.yml)
[![sanity-echo](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-echo.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-echo.yml)
[![ci-yaml-check](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/ci-yaml-check.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/ci-yaml-check.yml)

- **sanity-main.yml** : diag quotidien / dispatch / push (artefacts)
- **sanity-echo.yml** : smoke déclenchable manuellement
- **ci-yaml-check.yml** : lint/validité YAML

Voir `docs/CI.md`.
<!-- CI:END -->4\_fR\_fRR\_vs\_f.py, plot\_fig<!-- CI:BEGIN -->
### CI (Workflows canoniques)

[![sanity-main](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-main.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-main.yml)
[![sanity-echo](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-echo.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-echo.yml)
[![ci-yaml-check](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/ci-yaml-check.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/ci-yaml-check.yml)

- **sanity-main.yml** : diag quotidien / dispatch / push (artefacts)
- **sanity-echo.yml** : smoke déclenchable manuellement
- **ci-yaml-check.yml** : lint/validité YAML

Voir `docs/CI.md`.
<!-- CI:END -->5\_interpolated\_milestones.py, plot\_fig<!-- CI:BEGIN -->
### CI (Workflows canoniques)

[![sanity-main](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-main.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-main.yml)
[![sanity-echo](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-echo.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-echo.yml)
[![ci-yaml-check](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/ci-yaml-check.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/ci-yaml-check.yml)

- **sanity-main.yml** : diag quotidien / dispatch / push (artefacts)
- **sanity-echo.yml** : smoke déclenchable manuellement
- **ci-yaml-check.yml** : lint/validité YAML

Voir `docs/CI.md`.
<!-- CI:END -->6\_grid\_quality.py, plot\_fig<!-- CI:BEGIN -->
### CI (Workflows canoniques)

[![sanity-main](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-main.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-main.yml)
[![sanity-echo](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-echo.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-echo.yml)
[![ci-yaml-check](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/ci-yaml-check.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/ci-yaml-check.yml)

- **sanity-main.yml** : diag quotidien / dispatch / push (artefacts)
- **sanity-echo.yml** : smoke déclenchable manuellement
- **ci-yaml-check.yml** : lint/validité YAML

Voir `docs/CI.md`.
<!-- CI:END -->7\_ricci\_fR\_vs\_z.py, plot\_fig<!-- CI:BEGIN -->
### CI (Workflows canoniques)

[![sanity-main](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-main.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-main.yml)
[![sanity-echo](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-echo.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-echo.yml)
[![ci-yaml-check](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/ci-yaml-check.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/ci-yaml-check.yml)

- **sanity-main.yml** : diag quotidien / dispatch / push (artefacts)
- **sanity-echo.yml** : smoke déclenchable manuellement
- **ci-yaml-check.yml** : lint/validité YAML

Voir `docs/CI.md`.
<!-- CI:END -->8\_ricci\_fR\_vs\_T.py, requirements.txt
  * utils/<!-- CI:BEGIN -->
### CI (Workflows canoniques)

[![sanity-main](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-main.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-main.yml)
[![sanity-echo](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-echo.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-echo.yml)
[![ci-yaml-check](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/ci-yaml-check.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/ci-yaml-check.yml)

- **sanity-main.yml** : diag quotidien / dispatch / push (artefacts)
- **sanity-echo.yml** : smoke déclenchable manuellement
- **ci-yaml-check.yml** : lint/validité YAML

Voir `docs/CI.md`.
<!-- CI:END -->3\_ricci\_fR\_milestones\_enhanced.csv, utils/convert\_milestones.py
* zz-scripts/chapter<!-- CI:BEGIN -->
### CI (Workflows canoniques)

[![sanity-main](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-main.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-main.yml)
[![sanity-echo](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-echo.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-echo.yml)
[![ci-yaml-check](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/ci-yaml-check.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/ci-yaml-check.yml)

- **sanity-main.yml** : diag quotidien / dispatch / push (artefacts)
- **sanity-echo.yml** : smoke déclenchable manuellement
- **ci-yaml-check.yml** : lint/validité YAML

Voir `docs/CI.md`.
<!-- CI:END -->4/
  * generate\_data\_chapter<!-- CI:BEGIN -->
### CI (Workflows canoniques)

[![sanity-main](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-main.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-main.yml)
[![sanity-echo](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-echo.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-echo.yml)
[![ci-yaml-check](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/ci-yaml-check.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/ci-yaml-check.yml)

- **sanity-main.yml** : diag quotidien / dispatch / push (artefacts)
- **sanity-echo.yml** : smoke déclenchable manuellement
- **ci-yaml-check.yml** : lint/validité YAML

Voir `docs/CI.md`.
<!-- CI:END -->4.py, plot\_fig<!-- CI:BEGIN -->
### CI (Workflows canoniques)

[![sanity-main](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-main.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-main.yml)
[![sanity-echo](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-echo.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-echo.yml)
[![ci-yaml-check](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/ci-yaml-check.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/ci-yaml-check.yml)

- **sanity-main.yml** : diag quotidien / dispatch / push (artefacts)
- **sanity-echo.yml** : smoke déclenchable manuellement
- **ci-yaml-check.yml** : lint/validité YAML

Voir `docs/CI.md`.
<!-- CI:END -->1\_invariants\_schematic.py, plot\_fig<!-- CI:BEGIN -->
### CI (Workflows canoniques)

[![sanity-main](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-main.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-main.yml)
[![sanity-echo](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-echo.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-echo.yml)
[![ci-yaml-check](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/ci-yaml-check.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/ci-yaml-check.yml)

- **sanity-main.yml** : diag quotidien / dispatch / push (artefacts)
- **sanity-echo.yml** : smoke déclenchable manuellement
- **ci-yaml-check.yml** : lint/validité YAML

Voir `docs/CI.md`.
<!-- CI:END -->2\_invariants\_histogram.py, plot\_fig<!-- CI:BEGIN -->
### CI (Workflows canoniques)

[![sanity-main](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-main.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-main.yml)
[![sanity-echo](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-echo.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-echo.yml)
[![ci-yaml-check](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/ci-yaml-check.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/ci-yaml-check.yml)

- **sanity-main.yml** : diag quotidien / dispatch / push (artefacts)
- **sanity-echo.yml** : smoke déclenchable manuellement
- **ci-yaml-check.yml** : lint/validité YAML

Voir `docs/CI.md`.
<!-- CI:END -->3\_invariants\_vs\_T.py, plot\_fig<!-- CI:BEGIN -->
### CI (Workflows canoniques)

[![sanity-main](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-main.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-main.yml)
[![sanity-echo](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-echo.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-echo.yml)
[![ci-yaml-check](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/ci-yaml-check.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/ci-yaml-check.yml)

- **sanity-main.yml** : diag quotidien / dispatch / push (artefacts)
- **sanity-echo.yml** : smoke déclenchable manuellement
- **ci-yaml-check.yml** : lint/validité YAML

Voir `docs/CI.md`.
<!-- CI:END -->4\_relative\_deviations.py, requirements.txt
* zz-scripts/chapter<!-- CI:BEGIN -->
### CI (Workflows canoniques)

[![sanity-main](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-main.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-main.yml)
[![sanity-echo](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-echo.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-echo.yml)
[![ci-yaml-check](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/ci-yaml-check.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/ci-yaml-check.yml)

- **sanity-main.yml** : diag quotidien / dispatch / push (artefacts)
- **sanity-echo.yml** : smoke déclenchable manuellement
- **ci-yaml-check.yml** : lint/validité YAML

Voir `docs/CI.md`.
<!-- CI:END -->5/
  * generate\_data\_chapter<!-- CI:BEGIN -->
### CI (Workflows canoniques)

[![sanity-main](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-main.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-main.yml)
[![sanity-echo](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-echo.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-echo.yml)
[![ci-yaml-check](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/ci-yaml-check.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/ci-yaml-check.yml)

- **sanity-main.yml** : diag quotidien / dispatch / push (artefacts)
- **sanity-echo.yml** : smoke déclenchable manuellement
- **ci-yaml-check.yml** : lint/validité YAML

Voir `docs/CI.md`.
<!-- CI:END -->5.py, plot\_fig<!-- CI:BEGIN -->
### CI (Workflows canoniques)

[![sanity-main](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-main.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-main.yml)
[![sanity-echo](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-echo.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-echo.yml)
[![ci-yaml-check](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/ci-yaml-check.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/ci-yaml-check.yml)

- **sanity-main.yml** : diag quotidien / dispatch / push (artefacts)
- **sanity-echo.yml** : smoke déclenchable manuellement
- **ci-yaml-check.yml** : lint/validité YAML

Voir `docs/CI.md`.
<!-- CI:END -->1\_bbn\_reaction\_network.py, plot\_fig<!-- CI:BEGIN -->
### CI (Workflows canoniques)

[![sanity-main](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-main.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-main.yml)
[![sanity-echo](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-echo.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-echo.yml)
[![ci-yaml-check](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/ci-yaml-check.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/ci-yaml-check.yml)

- **sanity-main.yml** : diag quotidien / dispatch / push (artefacts)
- **sanity-echo.yml** : smoke déclenchable manuellement
- **ci-yaml-check.yml** : lint/validité YAML

Voir `docs/CI.md`.
<!-- CI:END -->2\_dh\_model\_vs\_obs.py, plot\_fig<!-- CI:BEGIN -->
### CI (Workflows canoniques)

[![sanity-main](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-main.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-main.yml)
[![sanity-echo](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-echo.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-echo.yml)
[![ci-yaml-check](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/ci-yaml-check.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/ci-yaml-check.yml)

- **sanity-main.yml** : diag quotidien / dispatch / push (artefacts)
- **sanity-echo.yml** : smoke déclenchable manuellement
- **ci-yaml-check.yml** : lint/validité YAML

Voir `docs/CI.md`.
<!-- CI:END -->3\_yp\_model\_vs\_obs.py, plot\_fig<!-- CI:BEGIN -->
### CI (Workflows canoniques)

[![sanity-main](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-main.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-main.yml)
[![sanity-echo](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-echo.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-echo.yml)
[![ci-yaml-check](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/ci-yaml-check.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/ci-yaml-check.yml)

- **sanity-main.yml** : diag quotidien / dispatch / push (artefacts)
- **sanity-echo.yml** : smoke déclenchable manuellement
- **ci-yaml-check.yml** : lint/validité YAML

Voir `docs/CI.md`.
<!-- CI:END -->4\_chi2\_vs\_T.py, requirements.txt
* zz-scripts/chapter<!-- CI:BEGIN -->
### CI (Workflows canoniques)

[![sanity-main](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-main.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-main.yml)
[![sanity-echo](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-echo.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-echo.yml)
[![ci-yaml-check](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/ci-yaml-check.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/ci-yaml-check.yml)

- **sanity-main.yml** : diag quotidien / dispatch / push (artefacts)
- **sanity-echo.yml** : smoke déclenchable manuellement
- **ci-yaml-check.yml** : lint/validité YAML

Voir `docs/CI.md`.
<!-- CI:END -->6/
  * generate\_data\_chapter<!-- CI:BEGIN -->
### CI (Workflows canoniques)

[![sanity-main](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-main.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-main.yml)
[![sanity-echo](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-echo.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-echo.yml)
[![ci-yaml-check](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/ci-yaml-check.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/ci-yaml-check.yml)

- **sanity-main.yml** : diag quotidien / dispatch / push (artefacts)
- **sanity-echo.yml** : smoke déclenchable manuellement
- **ci-yaml-check.yml** : lint/validité YAML

Voir `docs/CI.md`.
<!-- CI:END -->6.py, generate\_pdot\_plateau\_vs\_z.py, plot\_fig<!-- CI:BEGIN -->
### CI (Workflows canoniques)

[![sanity-main](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-main.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-main.yml)
[![sanity-echo](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-echo.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-echo.yml)
[![ci-yaml-check](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/ci-yaml-check.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/ci-yaml-check.yml)

- **sanity-main.yml** : diag quotidien / dispatch / push (artefacts)
- **sanity-echo.yml** : smoke déclenchable manuellement
- **ci-yaml-check.yml** : lint/validité YAML

Voir `docs/CI.md`.
<!-- CI:END -->1\_cmb\_dataflow\_diagram.py, plot\_fig<!-- CI:BEGIN -->
### CI (Workflows canoniques)

[![sanity-main](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-main.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-main.yml)
[![sanity-echo](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-echo.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-echo.yml)
[![ci-yaml-check](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/ci-yaml-check.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/ci-yaml-check.yml)

- **sanity-main.yml** : diag quotidien / dispatch / push (artefacts)
- **sanity-echo.yml** : smoke déclenchable manuellement
- **ci-yaml-check.yml** : lint/validité YAML

Voir `docs/CI.md`.
<!-- CI:END -->2\_cls\_lcdm\_vs\_mcgt.py, plot\_fig<!-- CI:BEGIN -->
### CI (Workflows canoniques)

[![sanity-main](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-main.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-main.yml)
[![sanity-echo](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-echo.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-echo.yml)
[![ci-yaml-check](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/ci-yaml-check.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/ci-yaml-check.yml)

- **sanity-main.yml** : diag quotidien / dispatch / push (artefacts)
- **sanity-echo.yml** : smoke déclenchable manuellement
- **ci-yaml-check.yml** : lint/validité YAML

Voir `docs/CI.md`.
<!-- CI:END -->3\_delta\_cls\_relative.py, plot\_fig<!-- CI:BEGIN -->
### CI (Workflows canoniques)

[![sanity-main](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-main.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-main.yml)
[![sanity-echo](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-echo.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-echo.yml)
[![ci-yaml-check](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/ci-yaml-check.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/ci-yaml-check.yml)

- **sanity-main.yml** : diag quotidien / dispatch / push (artefacts)
- **sanity-echo.yml** : smoke déclenchable manuellement
- **ci-yaml-check.yml** : lint/validité YAML

Voir `docs/CI.md`.
<!-- CI:END -->4\_delta\_rs\_vs\_params.py, plot\_fig<!-- CI:BEGIN -->
### CI (Workflows canoniques)

[![sanity-main](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-main.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-main.yml)
[![sanity-echo](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-echo.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-echo.yml)
[![ci-yaml-check](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/ci-yaml-check.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/ci-yaml-check.yml)

- **sanity-main.yml** : diag quotidien / dispatch / push (artefacts)
- **sanity-echo.yml** : smoke déclenchable manuellement
- **ci-yaml-check.yml** : lint/validité YAML

Voir `docs/CI.md`.
<!-- CI:END -->5\_delta\_chi2\_heatmap.py, run\_camb\_chapter<!-- CI:BEGIN -->
### CI (Workflows canoniques)

[![sanity-main](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-main.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-main.yml)
[![sanity-echo](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-echo.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-echo.yml)
[![ci-yaml-check](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/ci-yaml-check.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/ci-yaml-check.yml)

- **sanity-main.yml** : diag quotidien / dispatch / push (artefacts)
- **sanity-echo.yml** : smoke déclenchable manuellement
- **ci-yaml-check.yml** : lint/validité YAML

Voir `docs/CI.md`.
<!-- CI:END -->6.bat, requirements.txt
* zz-scripts/chapter<!-- CI:BEGIN -->
### CI (Workflows canoniques)

[![sanity-main](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-main.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-main.yml)
[![sanity-echo](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-echo.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-echo.yml)
[![ci-yaml-check](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/ci-yaml-check.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/ci-yaml-check.yml)

- **sanity-main.yml** : diag quotidien / dispatch / push (artefacts)
- **sanity-echo.yml** : smoke déclenchable manuellement
- **ci-yaml-check.yml** : lint/validité YAML

Voir `docs/CI.md`.
<!-- CI:END -->7/
  * generate\_data\_chapter<!-- CI:BEGIN -->
### CI (Workflows canoniques)

[![sanity-main](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-main.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-main.yml)
[![sanity-echo](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-echo.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-echo.yml)
[![ci-yaml-check](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/ci-yaml-check.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/ci-yaml-check.yml)

- **sanity-main.yml** : diag quotidien / dispatch / push (artefacts)
- **sanity-echo.yml** : smoke déclenchable manuellement
- **ci-yaml-check.yml** : lint/validité YAML

Voir `docs/CI.md`.
<!-- CI:END -->7.py, launch\_scalar\_perturbations\_solver.py, launch\_solver\_chapter<!-- CI:BEGIN -->
### CI (Workflows canoniques)

[![sanity-main](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-main.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-main.yml)
[![sanity-echo](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-echo.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-echo.yml)
[![ci-yaml-check](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/ci-yaml-check.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/ci-yaml-check.yml)

- **sanity-main.yml** : diag quotidien / dispatch / push (artefacts)
- **sanity-echo.yml** : smoke déclenchable manuellement
- **ci-yaml-check.yml** : lint/validité YAML

Voir `docs/CI.md`.
<!-- CI:END -->7.sh, plot\_fig<!-- CI:BEGIN -->
### CI (Workflows canoniques)

[![sanity-main](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-main.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-main.yml)
[![sanity-echo](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-echo.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-echo.yml)
[![ci-yaml-check](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/ci-yaml-check.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/ci-yaml-check.yml)

- **sanity-main.yml** : diag quotidien / dispatch / push (artefacts)
- **sanity-echo.yml** : smoke déclenchable manuellement
- **ci-yaml-check.yml** : lint/validité YAML

Voir `docs/CI.md`.
<!-- CI:END -->1\_cs2\_heatmap.py, plot\_fig<!-- CI:BEGIN -->
### CI (Workflows canoniques)

[![sanity-main](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-main.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-main.yml)
[![sanity-echo](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-echo.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-echo.yml)
[![ci-yaml-check](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/ci-yaml-check.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/ci-yaml-check.yml)

- **sanity-main.yml** : diag quotidien / dispatch / push (artefacts)
- **sanity-echo.yml** : smoke déclenchable manuellement
- **ci-yaml-check.yml** : lint/validité YAML

Voir `docs/CI.md`.
<!-- CI:END -->2\_delta\_phi\_heatmap.py, plot\_fig<!-- CI:BEGIN -->
### CI (Workflows canoniques)

[![sanity-main](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-main.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-main.yml)
[![sanity-echo](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-echo.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-echo.yml)
[![ci-yaml-check](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/ci-yaml-check.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/ci-yaml-check.yml)

- **sanity-main.yml** : diag quotidien / dispatch / push (artefacts)
- **sanity-echo.yml** : smoke déclenchable manuellement
- **ci-yaml-check.yml** : lint/validité YAML

Voir `docs/CI.md`.
<!-- CI:END -->6\_comparison.py, plot\_fig<!-- CI:BEGIN -->
### CI (Workflows canoniques)

[![sanity-main](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-main.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-main.yml)
[![sanity-echo](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-echo.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-echo.yml)
[![ci-yaml-check](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/ci-yaml-check.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/ci-yaml-check.yml)

- **sanity-main.yml** : diag quotidien / dispatch / push (artefacts)
- **sanity-echo.yml** : smoke déclenchable manuellement
- **ci-yaml-check.yml** : lint/validité YAML

Voir `docs/CI.md`.
<!-- CI:END -->3\_invariant\_I1.py, plot\_fig<!-- CI:BEGIN -->
### CI (Workflows canoniques)

[![sanity-main](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-main.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-main.yml)
[![sanity-echo](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-echo.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-echo.yml)
[![ci-yaml-check](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/ci-yaml-check.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/ci-yaml-check.yml)

- **sanity-main.yml** : diag quotidien / dispatch / push (artefacts)
- **sanity-echo.yml** : smoke déclenchable manuellement
- **ci-yaml-check.yml** : lint/validité YAML

Voir `docs/CI.md`.
<!-- CI:END -->4\_dcs2\_vs\_k.py, plot\_fig<!-- CI:BEGIN -->
### CI (Workflows canoniques)

[![sanity-main](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-main.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-main.yml)
[![sanity-echo](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-echo.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-echo.yml)
[![ci-yaml-check](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/ci-yaml-check.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/ci-yaml-check.yml)

- **sanity-main.yml** : diag quotidien / dispatch / push (artefacts)
- **sanity-echo.yml** : smoke déclenchable manuellement
- **ci-yaml-check.yml** : lint/validité YAML

Voir `docs/CI.md`.
<!-- CI:END -->5\_ddelta\_phi\_vs\_k.py, plot\_fig<!-- CI:BEGIN -->
### CI (Workflows canoniques)

[![sanity-main](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-main.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-main.yml)
[![sanity-echo](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-echo.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-echo.yml)
[![ci-yaml-check](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/ci-yaml-check.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/ci-yaml-check.yml)

- **sanity-main.yml** : diag quotidien / dispatch / push (artefacts)
- **sanity-echo.yml** : smoke déclenchable manuellement
- **ci-yaml-check.yml** : lint/validité YAML

Voir `docs/CI.md`.
<!-- CI:END -->7\_invariant\_I2.py, requirements.txt
  * tests/test\_chapter<!-- CI:BEGIN -->
### CI (Workflows canoniques)

[![sanity-main](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-main.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-main.yml)
[![sanity-echo](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-echo.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-echo.yml)
[![ci-yaml-check](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/ci-yaml-check.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/ci-yaml-check.yml)

- **sanity-main.yml** : diag quotidien / dispatch / push (artefacts)
- **sanity-echo.yml** : smoke déclenchable manuellement
- **ci-yaml-check.yml** : lint/validité YAML

Voir `docs/CI.md`.
<!-- CI:END -->7.py
  * utils/test\_kgrid.py, utils/toy\_model.py
* zz-scripts/chapter<!-- CI:BEGIN -->
### CI (Workflows canoniques)

[![sanity-main](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-main.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-main.yml)
[![sanity-echo](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-echo.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-echo.yml)
[![ci-yaml-check](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/ci-yaml-check.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/ci-yaml-check.yml)

- **sanity-main.yml** : diag quotidien / dispatch / push (artefacts)
- **sanity-echo.yml** : smoke déclenchable manuellement
- **ci-yaml-check.yml** : lint/validité YAML

Voir `docs/CI.md`.
<!-- CI:END -->8/
  * generate\_coupling\_milestones.py, generate\_data\_chapter<!-- CI:BEGIN -->
### CI (Workflows canoniques)

[![sanity-main](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-main.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-main.yml)
[![sanity-echo](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-echo.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-echo.yml)
[![ci-yaml-check](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/ci-yaml-check.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/ci-yaml-check.yml)

- **sanity-main.yml** : diag quotidien / dispatch / push (artefacts)
- **sanity-echo.yml** : smoke déclenchable manuellement
- **ci-yaml-check.yml** : lint/validité YAML

Voir `docs/CI.md`.
<!-- CI:END -->8.py, plot\_fig<!-- CI:BEGIN -->
### CI (Workflows canoniques)

[![sanity-main](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-main.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-main.yml)
[![sanity-echo](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-echo.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-echo.yml)
[![ci-yaml-check](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/ci-yaml-check.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/ci-yaml-check.yml)

- **sanity-main.yml** : diag quotidien / dispatch / push (artefacts)
- **sanity-echo.yml** : smoke déclenchable manuellement
- **ci-yaml-check.yml** : lint/validité YAML

Voir `docs/CI.md`.
<!-- CI:END -->1\_chi2\_total\_vs\_q<!-- CI:BEGIN -->
### CI (Workflows canoniques)

[![sanity-main](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-main.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-main.yml)
[![sanity-echo](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-echo.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-echo.yml)
[![ci-yaml-check](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/ci-yaml-check.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/ci-yaml-check.yml)

- **sanity-main.yml** : diag quotidien / dispatch / push (artefacts)
- **sanity-echo.yml** : smoke déclenchable manuellement
- **ci-yaml-check.yml** : lint/validité YAML

Voir `docs/CI.md`.
<!-- CI:END -->.py, plot\_fig<!-- CI:BEGIN -->
### CI (Workflows canoniques)

[![sanity-main](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-main.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-main.yml)
[![sanity-echo](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-echo.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-echo.yml)
[![ci-yaml-check](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/ci-yaml-check.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/ci-yaml-check.yml)

- **sanity-main.yml** : diag quotidien / dispatch / push (artefacts)
- **sanity-echo.yml** : smoke déclenchable manuellement
- **ci-yaml-check.yml** : lint/validité YAML

Voir `docs/CI.md`.
<!-- CI:END -->2\_dv\_vs\_z.py, plot\_fig<!-- CI:BEGIN -->
### CI (Workflows canoniques)

[![sanity-main](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-main.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-main.yml)
[![sanity-echo](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-echo.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-echo.yml)
[![ci-yaml-check](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/ci-yaml-check.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/ci-yaml-check.yml)

- **sanity-main.yml** : diag quotidien / dispatch / push (artefacts)
- **sanity-echo.yml** : smoke déclenchable manuellement
- **ci-yaml-check.yml** : lint/validité YAML

Voir `docs/CI.md`.
<!-- CI:END -->3\_mu\_vs\_z.py, plot\_fig<!-- CI:BEGIN -->
### CI (Workflows canoniques)

[![sanity-main](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-main.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-main.yml)
[![sanity-echo](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-echo.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-echo.yml)
[![ci-yaml-check](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/ci-yaml-check.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/ci-yaml-check.yml)

- **sanity-main.yml** : diag quotidien / dispatch / push (artefacts)
- **sanity-echo.yml** : smoke déclenchable manuellement
- **ci-yaml-check.yml** : lint/validité YAML

Voir `docs/CI.md`.
<!-- CI:END -->4\_chi2\_heatmap.py, plot\_fig<!-- CI:BEGIN -->
### CI (Workflows canoniques)

[![sanity-main](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-main.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-main.yml)
[![sanity-echo](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-echo.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-echo.yml)
[![ci-yaml-check](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/ci-yaml-check.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/ci-yaml-check.yml)

- **sanity-main.yml** : diag quotidien / dispatch / push (artefacts)
- **sanity-echo.yml** : smoke déclenchable manuellement
- **ci-yaml-check.yml** : lint/validité YAML

Voir `docs/CI.md`.
<!-- CI:END -->5\_residuals.py, plot\_fig<!-- CI:BEGIN -->
### CI (Workflows canoniques)

[![sanity-main](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-main.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-main.yml)
[![sanity-echo](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-echo.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-echo.yml)
[![ci-yaml-check](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/ci-yaml-check.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/ci-yaml-check.yml)

- **sanity-main.yml** : diag quotidien / dispatch / push (artefacts)
- **sanity-echo.yml** : smoke déclenchable manuellement
- **ci-yaml-check.yml** : lint/validité YAML

Voir `docs/CI.md`.
<!-- CI:END -->6\_normalized\_residuals\_distribution.py, plot\_fig<!-- CI:BEGIN -->
### CI (Workflows canoniques)

[![sanity-main](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-main.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-main.yml)
[![sanity-echo](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-echo.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-echo.yml)
[![ci-yaml-check](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/ci-yaml-check.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/ci-yaml-check.yml)

- **sanity-main.yml** : diag quotidien / dispatch / push (artefacts)
- **sanity-echo.yml** : smoke déclenchable manuellement
- **ci-yaml-check.yml** : lint/validité YAML

Voir `docs/CI.md`.
<!-- CI:END -->7\_chi2\_profile.py, requirements.txt
  * utils/cosmo.py, utils/coupling\_example\_model.py, utils/extract\_bao\_data.py, utils/extract\_pantheon\_plus\_data.py, utils/generate\_coupling\_milestones.py, utils/verify\_z\_grid.py
* zz-scripts/chapter<!-- CI:BEGIN -->
### CI (Workflows canoniques)

[![sanity-main](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-main.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-main.yml)
[![sanity-echo](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-echo.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-echo.yml)
[![ci-yaml-check](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/ci-yaml-check.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/ci-yaml-check.yml)

- **sanity-main.yml** : diag quotidien / dispatch / push (artefacts)
- **sanity-echo.yml** : smoke déclenchable manuellement
- **ci-yaml-check.yml** : lint/validité YAML

Voir `docs/CI.md`.
<!-- CI:END -->9/
  * apply\_poly\_unwrap\_rebranch.py, check\_p95\_methods.py, extract\_phenom\_phase.py, fetch\_gwtc3\_confident.py, flag\_jalons.py, generate\_data\_chapter<!-- CI:BEGIN -->
### CI (Workflows canoniques)

[![sanity-main](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-main.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-main.yml)
[![sanity-echo](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-echo.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-echo.yml)
[![ci-yaml-check](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/ci-yaml-check.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/ci-yaml-check.yml)

- **sanity-main.yml** : diag quotidien / dispatch / push (artefacts)
- **sanity-echo.yml** : smoke déclenchable manuellement
- **ci-yaml-check.yml** : lint/validité YAML

Voir `docs/CI.md`.
<!-- CI:END -->9.py, generate\_mcgt\_raw\_phase.py, opt\_poly\_rebranch.py
  * plot\_fig<!-- CI:BEGIN -->
### CI (Workflows canoniques)

[![sanity-main](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-main.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-main.yml)
[![sanity-echo](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-echo.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-echo.yml)
[![ci-yaml-check](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/ci-yaml-check.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/ci-yaml-check.yml)

- **sanity-main.yml** : diag quotidien / dispatch / push (artefacts)
- **sanity-echo.yml** : smoke déclenchable manuellement
- **ci-yaml-check.yml** : lint/validité YAML

Voir `docs/CI.md`.
<!-- CI:END -->1\_phase\_overlay.py, plot\_fig<!-- CI:BEGIN -->
### CI (Workflows canoniques)

[![sanity-main](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-main.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-main.yml)
[![sanity-echo](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-echo.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-echo.yml)
[![ci-yaml-check](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/ci-yaml-check.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/ci-yaml-check.yml)

- **sanity-main.yml** : diag quotidien / dispatch / push (artefacts)
- **sanity-echo.yml** : smoke déclenchable manuellement
- **ci-yaml-check.yml** : lint/validité YAML

Voir `docs/CI.md`.
<!-- CI:END -->2\_residual\_phase.py, plot\_fig<!-- CI:BEGIN -->
### CI (Workflows canoniques)

[![sanity-main](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-main.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-main.yml)
[![sanity-echo](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-echo.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-echo.yml)
[![ci-yaml-check](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/ci-yaml-check.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/ci-yaml-check.yml)

- **sanity-main.yml** : diag quotidien / dispatch / push (artefacts)
- **sanity-echo.yml** : smoke déclenchable manuellement
- **ci-yaml-check.yml** : lint/validité YAML

Voir `docs/CI.md`.
<!-- CI:END -->3\_hist\_absdphi\_2<!-- CI:BEGIN -->
### CI (Workflows canoniques)

[![sanity-main](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-main.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-main.yml)
[![sanity-echo](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-echo.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-echo.yml)
[![ci-yaml-check](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/ci-yaml-check.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/ci-yaml-check.yml)

- **sanity-main.yml** : diag quotidien / dispatch / push (artefacts)
- **sanity-echo.yml** : smoke déclenchable manuellement
- **ci-yaml-check.yml** : lint/validité YAML

Voir `docs/CI.md`.
<!-- CI:END -->\_3<!-- CI:BEGIN -->
### CI (Workflows canoniques)

[![sanity-main](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-main.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-main.yml)
[![sanity-echo](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-echo.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-echo.yml)
[![ci-yaml-check](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/ci-yaml-check.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/ci-yaml-check.yml)

- **sanity-main.yml** : diag quotidien / dispatch / push (artefacts)
- **sanity-echo.yml** : smoke déclenchable manuellement
- **ci-yaml-check.yml** : lint/validité YAML

Voir `docs/CI.md`.
<!-- CI:END --><!-- CI:BEGIN -->
### CI (Workflows canoniques)

[![sanity-main](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-main.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-main.yml)
[![sanity-echo](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-echo.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-echo.yml)
[![ci-yaml-check](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/ci-yaml-check.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/ci-yaml-check.yml)

- **sanity-main.yml** : diag quotidien / dispatch / push (artefacts)
- **sanity-echo.yml** : smoke déclenchable manuellement
- **ci-yaml-check.yml** : lint/validité YAML

Voir `docs/CI.md`.
<!-- CI:END -->.py, plot\_fig<!-- CI:BEGIN -->
### CI (Workflows canoniques)

[![sanity-main](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-main.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-main.yml)
[![sanity-echo](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-echo.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-echo.yml)
[![ci-yaml-check](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/ci-yaml-check.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/ci-yaml-check.yml)

- **sanity-main.yml** : diag quotidien / dispatch / push (artefacts)
- **sanity-echo.yml** : smoke déclenchable manuellement
- **ci-yaml-check.yml** : lint/validité YAML

Voir `docs/CI.md`.
<!-- CI:END -->4\_absdphi\_milestones\_vs\_f.py, plot\_fig<!-- CI:BEGIN -->
### CI (Workflows canoniques)

[![sanity-main](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-main.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-main.yml)
[![sanity-echo](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-echo.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-echo.yml)
[![ci-yaml-check](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/ci-yaml-check.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/ci-yaml-check.yml)

- **sanity-main.yml** : diag quotidien / dispatch / push (artefacts)
- **sanity-echo.yml** : smoke déclenchable manuellement
- **ci-yaml-check.yml** : lint/validité YAML

Voir `docs/CI.md`.
<!-- CI:END -->5\_scatter\_phi\_at\_fpeak.py, requirements.txt
* zz-scripts/chapter1<!-- CI:BEGIN -->
### CI (Workflows canoniques)

[![sanity-main](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-main.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-main.yml)
[![sanity-echo](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-echo.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-echo.yml)
[![ci-yaml-check](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/ci-yaml-check.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/ci-yaml-check.yml)

- **sanity-main.yml** : diag quotidien / dispatch / push (artefacts)
- **sanity-echo.yml** : smoke déclenchable manuellement
- **ci-yaml-check.yml** : lint/validité YAML

Voir `docs/CI.md`.
<!-- CI:END -->/
  * add\_phi\_at\_fpeak.py, bootstrap\_topk\_p95.py, check\_metrics\_consistency.py, diag\_phi\_fpeak.py, eval\_primary\_metrics\_2<!-- CI:BEGIN -->
### CI (Workflows canoniques)

[![sanity-main](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-main.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-main.yml)
[![sanity-echo](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-echo.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-echo.yml)
[![ci-yaml-check](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/ci-yaml-check.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/ci-yaml-check.yml)

- **sanity-main.yml** : diag quotidien / dispatch / push (artefacts)
- **sanity-echo.yml** : smoke déclenchable manuellement
- **ci-yaml-check.yml** : lint/validité YAML

Voir `docs/CI.md`.
<!-- CI:END -->\_3<!-- CI:BEGIN -->
### CI (Workflows canoniques)

[![sanity-main](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-main.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-main.yml)
[![sanity-echo](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-echo.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-echo.yml)
[![ci-yaml-check](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/ci-yaml-check.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/ci-yaml-check.yml)

- **sanity-main.yml** : diag quotidien / dispatch / push (artefacts)
- **sanity-echo.yml** : smoke déclenchable manuellement
- **ci-yaml-check.yml** : lint/validité YAML

Voir `docs/CI.md`.
<!-- CI:END --><!-- CI:BEGIN -->
### CI (Workflows canoniques)

[![sanity-main](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-main.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-main.yml)
[![sanity-echo](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-echo.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-echo.yml)
[![ci-yaml-check](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/ci-yaml-check.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/ci-yaml-check.yml)

- **sanity-main.yml** : diag quotidien / dispatch / push (artefacts)
- **sanity-echo.yml** : smoke déclenchable manuellement
- **ci-yaml-check.yml** : lint/validité YAML

Voir `docs/CI.md`.
<!-- CI:END -->.py, generate\_data\_chapter1<!-- CI:BEGIN -->
### CI (Workflows canoniques)

[![sanity-main](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-main.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-main.yml)
[![sanity-echo](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-echo.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-echo.yml)
[![ci-yaml-check](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/ci-yaml-check.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/ci-yaml-check.yml)

- **sanity-main.yml** : diag quotidien / dispatch / push (artefacts)
- **sanity-echo.yml** : smoke déclenchable manuellement
- **ci-yaml-check.yml** : lint/validité YAML

Voir `docs/CI.md`.
<!-- CI:END -->.py, inspect\_topk\_residuals.py, qc\_wrapped\_vs\_unwrapped.py, recompute\_p95\_circular.py, regen\_fig<!-- CI:BEGIN -->
### CI (Workflows canoniques)

[![sanity-main](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-main.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-main.yml)
[![sanity-echo](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-echo.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-echo.yml)
[![ci-yaml-check](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/ci-yaml-check.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/ci-yaml-check.yml)

- **sanity-main.yml** : diag quotidien / dispatch / push (artefacts)
- **sanity-echo.yml** : smoke déclenchable manuellement
- **ci-yaml-check.yml** : lint/validité YAML

Voir `docs/CI.md`.
<!-- CI:END -->5\_using\_circp95.py
  * plot\_fig<!-- CI:BEGIN -->
### CI (Workflows canoniques)

[![sanity-main](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-main.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-main.yml)
[![sanity-echo](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-echo.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-echo.yml)
[![ci-yaml-check](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/ci-yaml-check.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/ci-yaml-check.yml)

- **sanity-main.yml** : diag quotidien / dispatch / push (artefacts)
- **sanity-echo.yml** : smoke déclenchable manuellement
- **ci-yaml-check.yml** : lint/validité YAML

Voir `docs/CI.md`.
<!-- CI:END -->1\_iso\_p95\_maps.py, plot\_fig<!-- CI:BEGIN -->
### CI (Workflows canoniques)

[![sanity-main](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-main.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-main.yml)
[![sanity-echo](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-echo.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-echo.yml)
[![ci-yaml-check](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/ci-yaml-check.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/ci-yaml-check.yml)

- **sanity-main.yml** : diag quotidien / dispatch / push (artefacts)
- **sanity-echo.yml** : smoke déclenchable manuellement
- **ci-yaml-check.yml** : lint/validité YAML

Voir `docs/CI.md`.
<!-- CI:END -->2\_scatter\_phi\_at\_fpeak.py, plot\_fig<!-- CI:BEGIN -->
### CI (Workflows canoniques)

[![sanity-main](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-main.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-main.yml)
[![sanity-echo](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-echo.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-echo.yml)
[![ci-yaml-check](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/ci-yaml-check.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/ci-yaml-check.yml)

- **sanity-main.yml** : diag quotidien / dispatch / push (artefacts)
- **sanity-echo.yml** : smoke déclenchable manuellement
- **ci-yaml-check.yml** : lint/validité YAML

Voir `docs/CI.md`.
<!-- CI:END -->3\_convergence\_p95\_vs\_n.py, plot\_fig<!-- CI:BEGIN -->
### CI (Workflows canoniques)

[![sanity-main](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-main.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-main.yml)
[![sanity-echo](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-echo.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-echo.yml)
[![ci-yaml-check](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/ci-yaml-check.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/ci-yaml-check.yml)

- **sanity-main.yml** : diag quotidien / dispatch / push (artefacts)
- **sanity-echo.yml** : smoke déclenchable manuellement
- **ci-yaml-check.yml** : lint/validité YAML

Voir `docs/CI.md`.
<!-- CI:END -->3b\_bootstrap\_coverage\_vs\_n.py, plot\_fig<!-- CI:BEGIN -->
### CI (Workflows canoniques)

[![sanity-main](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-main.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-main.yml)
[![sanity-echo](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-echo.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-echo.yml)
[![ci-yaml-check](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/ci-yaml-check.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/ci-yaml-check.yml)

- **sanity-main.yml** : diag quotidien / dispatch / push (artefacts)
- **sanity-echo.yml** : smoke déclenchable manuellement
- **ci-yaml-check.yml** : lint/validité YAML

Voir `docs/CI.md`.
<!-- CI:END -->4\_scatter\_p95\_recalc\_vs\_orig.py, plot\_fig<!-- CI:BEGIN -->
### CI (Workflows canoniques)

[![sanity-main](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-main.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-main.yml)
[![sanity-echo](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-echo.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-echo.yml)
[![ci-yaml-check](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/ci-yaml-check.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/ci-yaml-check.yml)

- **sanity-main.yml** : diag quotidien / dispatch / push (artefacts)
- **sanity-echo.yml** : smoke déclenchable manuellement
- **ci-yaml-check.yml** : lint/validité YAML

Voir `docs/CI.md`.
<!-- CI:END -->5\_hist\_cdf\_metrics.py, plot\_fig<!-- CI:BEGIN -->
### CI (Workflows canoniques)

[![sanity-main](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-main.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-main.yml)
[![sanity-echo](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-echo.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-echo.yml)
[![ci-yaml-check](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/ci-yaml-check.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/ci-yaml-check.yml)

- **sanity-main.yml** : diag quotidien / dispatch / push (artefacts)
- **sanity-echo.yml** : smoke déclenchable manuellement
- **ci-yaml-check.yml** : lint/validité YAML

Voir `docs/CI.md`.
<!-- CI:END -->6\_residual\_map.py, plot\_fig<!-- CI:BEGIN -->
### CI (Workflows canoniques)

[![sanity-main](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-main.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-main.yml)
[![sanity-echo](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-echo.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-echo.yml)
[![ci-yaml-check](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/ci-yaml-check.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/ci-yaml-check.yml)

- **sanity-main.yml** : diag quotidien / dispatch / push (artefacts)
- **sanity-echo.yml** : smoke déclenchable manuellement
- **ci-yaml-check.yml** : lint/validité YAML

Voir `docs/CI.md`.
<!-- CI:END -->7\_synthesis.py
  * update\_manifest\_with\_hashes.py, requirements.txt
* zz-scripts/manifest\_tools/
  * populate\_manifest.py, verify\_manifest.py
---
## 6) Figures (zz-figures/)
Par chapitre : fig\_\*.png (noms explicites, FR).
* chap.<!-- CI:BEGIN -->
### CI (Workflows canoniques)

[![sanity-main](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-main.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-main.yml)
[![sanity-echo](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-echo.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-echo.yml)
[![ci-yaml-check](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/ci-yaml-check.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/ci-yaml-check.yml)

- **sanity-main.yml** : diag quotidien / dispatch / push (artefacts)
- **sanity-echo.yml** : smoke déclenchable manuellement
- **ci-yaml-check.yml** : lint/validité YAML

Voir `docs/CI.md`.
<!-- CI:END -->1 :
  * fig\_<!-- CI:BEGIN -->
### CI (Workflows canoniques)

[![sanity-main](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-main.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-main.yml)
[![sanity-echo](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-echo.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-echo.yml)
[![ci-yaml-check](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/ci-yaml-check.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/ci-yaml-check.yml)

- **sanity-main.yml** : diag quotidien / dispatch / push (artefacts)
- **sanity-echo.yml** : smoke déclenchable manuellement
- **ci-yaml-check.yml** : lint/validité YAML

Voir `docs/CI.md`.
<!-- CI:END -->1\_early\_plateau.png, fig\_<!-- CI:BEGIN -->
### CI (Workflows canoniques)

[![sanity-main](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-main.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-main.yml)
[![sanity-echo](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-echo.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-echo.yml)
[![ci-yaml-check](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/ci-yaml-check.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/ci-yaml-check.yml)

- **sanity-main.yml** : diag quotidien / dispatch / push (artefacts)
- **sanity-echo.yml** : smoke déclenchable manuellement
- **ci-yaml-check.yml** : lint/validité YAML

Voir `docs/CI.md`.
<!-- CI:END -->2\_logistic\_calibration.png, fig\_<!-- CI:BEGIN -->
### CI (Workflows canoniques)

[![sanity-main](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-main.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-main.yml)
[![sanity-echo](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-echo.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-echo.yml)
[![ci-yaml-check](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/ci-yaml-check.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/ci-yaml-check.yml)

- **sanity-main.yml** : diag quotidien / dispatch / push (artefacts)
- **sanity-echo.yml** : smoke déclenchable manuellement
- **ci-yaml-check.yml** : lint/validité YAML

Voir `docs/CI.md`.
<!-- CI:END -->3\_relative\_error\_timeline.png, fig\_<!-- CI:BEGIN -->
### CI (Workflows canoniques)

[![sanity-main](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-main.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-main.yml)
[![sanity-echo](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-echo.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-echo.yml)
[![ci-yaml-check](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/ci-yaml-check.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/ci-yaml-check.yml)

- **sanity-main.yml** : diag quotidien / dispatch / push (artefacts)
- **sanity-echo.yml** : smoke déclenchable manuellement
- **ci-yaml-check.yml** : lint/validité YAML

Voir `docs/CI.md`.
<!-- CI:END -->4\_P\_vs\_T\_evolution.png, fig\_<!-- CI:BEGIN -->
### CI (Workflows canoniques)

[![sanity-main](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-main.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-main.yml)
[![sanity-echo](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-echo.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-echo.yml)
[![ci-yaml-check](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/ci-yaml-check.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/ci-yaml-check.yml)

- **sanity-main.yml** : diag quotidien / dispatch / push (artefacts)
- **sanity-echo.yml** : smoke déclenchable manuellement
- **ci-yaml-check.yml** : lint/validité YAML

Voir `docs/CI.md`.
<!-- CI:END -->5\_I1\_vs\_T.png, fig\_<!-- CI:BEGIN -->
### CI (Workflows canoniques)

[![sanity-main](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-main.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-main.yml)
[![sanity-echo](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-echo.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-echo.yml)
[![ci-yaml-check](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/ci-yaml-check.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/ci-yaml-check.yml)

- **sanity-main.yml** : diag quotidien / dispatch / push (artefacts)
- **sanity-echo.yml** : smoke déclenchable manuellement
- **ci-yaml-check.yml** : lint/validité YAML

Voir `docs/CI.md`.
<!-- CI:END -->6\_P\_derivative\_comparison.png
* chap.<!-- CI:BEGIN -->
### CI (Workflows canoniques)

[![sanity-main](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-main.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-main.yml)
[![sanity-echo](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-echo.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-echo.yml)
[![ci-yaml-check](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/ci-yaml-check.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/ci-yaml-check.yml)

- **sanity-main.yml** : diag quotidien / dispatch / push (artefacts)
- **sanity-echo.yml** : smoke déclenchable manuellement
- **ci-yaml-check.yml** : lint/validité YAML

Voir `docs/CI.md`.
<!-- CI:END -->2 :
  * fig\_<!-- CI:BEGIN -->
### CI (Workflows canoniques)

[![sanity-main](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-main.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-main.yml)
[![sanity-echo](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-echo.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-echo.yml)
[![ci-yaml-check](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/ci-yaml-check.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/ci-yaml-check.yml)

- **sanity-main.yml** : diag quotidien / dispatch / push (artefacts)
- **sanity-echo.yml** : smoke déclenchable manuellement
- **ci-yaml-check.yml** : lint/validité YAML

Voir `docs/CI.md`.
<!-- CI:END --><!-- CI:BEGIN -->
### CI (Workflows canoniques)

[![sanity-main](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-main.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-main.yml)
[![sanity-echo](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-echo.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-echo.yml)
[![ci-yaml-check](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/ci-yaml-check.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/ci-yaml-check.yml)

- **sanity-main.yml** : diag quotidien / dispatch / push (artefacts)
- **sanity-echo.yml** : smoke déclenchable manuellement
- **ci-yaml-check.yml** : lint/validité YAML

Voir `docs/CI.md`.
<!-- CI:END -->\_spectrum.png, fig\_<!-- CI:BEGIN -->
### CI (Workflows canoniques)

[![sanity-main](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-main.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-main.yml)
[![sanity-echo](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-echo.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-echo.yml)
[![ci-yaml-check](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/ci-yaml-check.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/ci-yaml-check.yml)

- **sanity-main.yml** : diag quotidien / dispatch / push (artefacts)
- **sanity-echo.yml** : smoke déclenchable manuellement
- **ci-yaml-check.yml** : lint/validité YAML

Voir `docs/CI.md`.
<!-- CI:END -->1\_P\_vs\_T\_evolution.png, fig\_<!-- CI:BEGIN -->
### CI (Workflows canoniques)

[![sanity-main](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-main.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-main.yml)
[![sanity-echo](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-echo.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-echo.yml)
[![ci-yaml-check](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/ci-yaml-check.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/ci-yaml-check.yml)

- **sanity-main.yml** : diag quotidien / dispatch / push (artefacts)
- **sanity-echo.yml** : smoke déclenchable manuellement
- **ci-yaml-check.yml** : lint/validité YAML

Voir `docs/CI.md`.
<!-- CI:END -->2\_calibration.png, fig\_<!-- CI:BEGIN -->
### CI (Workflows canoniques)

[![sanity-main](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-main.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-main.yml)
[![sanity-echo](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-echo.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-echo.yml)
[![ci-yaml-check](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/ci-yaml-check.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/ci-yaml-check.yml)

- **sanity-main.yml** : diag quotidien / dispatch / push (artefacts)
- **sanity-echo.yml** : smoke déclenchable manuellement
- **ci-yaml-check.yml** : lint/validité YAML

Voir `docs/CI.md`.
<!-- CI:END -->3\_relative\_errors.png, fig\_<!-- CI:BEGIN -->
### CI (Workflows canoniques)

[![sanity-main](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-main.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-main.yml)
[![sanity-echo](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-echo.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-echo.yml)
[![ci-yaml-check](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/ci-yaml-check.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/ci-yaml-check.yml)

- **sanity-main.yml** : diag quotidien / dispatch / push (artefacts)
- **sanity-echo.yml** : smoke déclenchable manuellement
- **ci-yaml-check.yml** : lint/validité YAML

Voir `docs/CI.md`.
<!-- CI:END -->4\_pipeline\_diagram.png, fig\_<!-- CI:BEGIN -->
### CI (Workflows canoniques)

[![sanity-main](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-main.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-main.yml)
[![sanity-echo](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-echo.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-echo.yml)
[![ci-yaml-check](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/ci-yaml-check.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/ci-yaml-check.yml)

- **sanity-main.yml** : diag quotidien / dispatch / push (artefacts)
- **sanity-echo.yml** : smoke déclenchable manuellement
- **ci-yaml-check.yml** : lint/validité YAML

Voir `docs/CI.md`.
<!-- CI:END -->5\_FG\_series.png, fig\_<!-- CI:BEGIN -->
### CI (Workflows canoniques)

[![sanity-main](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-main.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-main.yml)
[![sanity-echo](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-echo.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-echo.yml)
[![ci-yaml-check](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/ci-yaml-check.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/ci-yaml-check.yml)

- **sanity-main.yml** : diag quotidien / dispatch / push (artefacts)
- **sanity-echo.yml** : smoke déclenchable manuellement
- **ci-yaml-check.yml** : lint/validité YAML

Voir `docs/CI.md`.
<!-- CI:END -->6\_fit\_alpha.png
* chap.<!-- CI:BEGIN -->
### CI (Workflows canoniques)

[![sanity-main](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-main.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-main.yml)
[![sanity-echo](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-echo.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-echo.yml)
[![ci-yaml-check](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/ci-yaml-check.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/ci-yaml-check.yml)

- **sanity-main.yml** : diag quotidien / dispatch / push (artefacts)
- **sanity-echo.yml** : smoke déclenchable manuellement
- **ci-yaml-check.yml** : lint/validité YAML

Voir `docs/CI.md`.
<!-- CI:END -->3 :
  * fig\_<!-- CI:BEGIN -->
### CI (Workflows canoniques)

[![sanity-main](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-main.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-main.yml)
[![sanity-echo](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-echo.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-echo.yml)
[![ci-yaml-check](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/ci-yaml-check.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/ci-yaml-check.yml)

- **sanity-main.yml** : diag quotidien / dispatch / push (artefacts)
- **sanity-echo.yml** : smoke déclenchable manuellement
- **ci-yaml-check.yml** : lint/validité YAML

Voir `docs/CI.md`.
<!-- CI:END -->1\_fR\_stability\_domain.png, fig\_<!-- CI:BEGIN -->
### CI (Workflows canoniques)

[![sanity-main](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-main.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-main.yml)
[![sanity-echo](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-echo.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-echo.yml)
[![ci-yaml-check](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/ci-yaml-check.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/ci-yaml-check.yml)

- **sanity-main.yml** : diag quotidien / dispatch / push (artefacts)
- **sanity-echo.yml** : smoke déclenchable manuellement
- **ci-yaml-check.yml** : lint/validité YAML

Voir `docs/CI.md`.
<!-- CI:END -->2\_fR\_fRR\_vs\_R.png, fig\_<!-- CI:BEGIN -->
### CI (Workflows canoniques)

[![sanity-main](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-main.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-main.yml)
[![sanity-echo](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-echo.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-echo.yml)
[![ci-yaml-check](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/ci-yaml-check.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/ci-yaml-check.yml)

- **sanity-main.yml** : diag quotidien / dispatch / push (artefacts)
- **sanity-echo.yml** : smoke déclenchable manuellement
- **ci-yaml-check.yml** : lint/validité YAML

Voir `docs/CI.md`.
<!-- CI:END -->3\_ms2\_R<!-- CI:BEGIN -->
### CI (Workflows canoniques)

[![sanity-main](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-main.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-main.yml)
[![sanity-echo](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-echo.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-echo.yml)
[![ci-yaml-check](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/ci-yaml-check.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/ci-yaml-check.yml)

- **sanity-main.yml** : diag quotidien / dispatch / push (artefacts)
- **sanity-echo.yml** : smoke déclenchable manuellement
- **ci-yaml-check.yml** : lint/validité YAML

Voir `docs/CI.md`.
<!-- CI:END -->\_vs\_R.png, fig\_<!-- CI:BEGIN -->
### CI (Workflows canoniques)

[![sanity-main](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-main.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-main.yml)
[![sanity-echo](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-echo.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-echo.yml)
[![ci-yaml-check](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/ci-yaml-check.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/ci-yaml-check.yml)

- **sanity-main.yml** : diag quotidien / dispatch / push (artefacts)
- **sanity-echo.yml** : smoke déclenchable manuellement
- **ci-yaml-check.yml** : lint/validité YAML

Voir `docs/CI.md`.
<!-- CI:END -->4\_fR\_fRR\_vs\_R.png, fig\_<!-- CI:BEGIN -->
### CI (Workflows canoniques)

[![sanity-main](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-main.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-main.yml)
[![sanity-echo](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-echo.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-echo.yml)
[![ci-yaml-check](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/ci-yaml-check.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/ci-yaml-check.yml)

- **sanity-main.yml** : diag quotidien / dispatch / push (artefacts)
- **sanity-echo.yml** : smoke déclenchable manuellement
- **ci-yaml-check.yml** : lint/validité YAML

Voir `docs/CI.md`.
<!-- CI:END -->5\_interpolated\_milestones.png, fig\_<!-- CI:BEGIN -->
### CI (Workflows canoniques)

[![sanity-main](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-main.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-main.yml)
[![sanity-echo](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-echo.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-echo.yml)
[![ci-yaml-check](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/ci-yaml-check.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/ci-yaml-check.yml)

- **sanity-main.yml** : diag quotidien / dispatch / push (artefacts)
- **sanity-echo.yml** : smoke déclenchable manuellement
- **ci-yaml-check.yml** : lint/validité YAML

Voir `docs/CI.md`.
<!-- CI:END -->6\_grid\_quality.png, fig\_<!-- CI:BEGIN -->
### CI (Workflows canoniques)

[![sanity-main](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-main.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-main.yml)
[![sanity-echo](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-echo.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-echo.yml)
[![ci-yaml-check](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/ci-yaml-check.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/ci-yaml-check.yml)

- **sanity-main.yml** : diag quotidien / dispatch / push (artefacts)
- **sanity-echo.yml** : smoke déclenchable manuellement
- **ci-yaml-check.yml** : lint/validité YAML

Voir `docs/CI.md`.
<!-- CI:END -->7\_ricci\_fR\_vs\_z.png, fig\_<!-- CI:BEGIN -->
### CI (Workflows canoniques)

[![sanity-main](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-main.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-main.yml)
[![sanity-echo](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-echo.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-echo.yml)
[![ci-yaml-check](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/ci-yaml-check.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/ci-yaml-check.yml)

- **sanity-main.yml** : diag quotidien / dispatch / push (artefacts)
- **sanity-echo.yml** : smoke déclenchable manuellement
- **ci-yaml-check.yml** : lint/validité YAML

Voir `docs/CI.md`.
<!-- CI:END -->8\_ricci\_fR\_vs\_T.png
* chap.<!-- CI:BEGIN -->
### CI (Workflows canoniques)

[![sanity-main](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-main.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-main.yml)
[![sanity-echo](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-echo.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-echo.yml)
[![ci-yaml-check](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/ci-yaml-check.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/ci-yaml-check.yml)

- **sanity-main.yml** : diag quotidien / dispatch / push (artefacts)
- **sanity-echo.yml** : smoke déclenchable manuellement
- **ci-yaml-check.yml** : lint/validité YAML

Voir `docs/CI.md`.
<!-- CI:END -->4 :
  * fig\_<!-- CI:BEGIN -->
### CI (Workflows canoniques)

[![sanity-main](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-main.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-main.yml)
[![sanity-echo](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-echo.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-echo.yml)
[![ci-yaml-check](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/ci-yaml-check.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/ci-yaml-check.yml)

- **sanity-main.yml** : diag quotidien / dispatch / push (artefacts)
- **sanity-echo.yml** : smoke déclenchable manuellement
- **ci-yaml-check.yml** : lint/validité YAML

Voir `docs/CI.md`.
<!-- CI:END -->1\_invariants\_schematic.png, fig\_<!-- CI:BEGIN -->
### CI (Workflows canoniques)

[![sanity-main](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-main.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-main.yml)
[![sanity-echo](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-echo.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-echo.yml)
[![ci-yaml-check](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/ci-yaml-check.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/ci-yaml-check.yml)

- **sanity-main.yml** : diag quotidien / dispatch / push (artefacts)
- **sanity-echo.yml** : smoke déclenchable manuellement
- **ci-yaml-check.yml** : lint/validité YAML

Voir `docs/CI.md`.
<!-- CI:END -->2\_invariants\_histogram.png, fig\_<!-- CI:BEGIN -->
### CI (Workflows canoniques)

[![sanity-main](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-main.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-main.yml)
[![sanity-echo](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-echo.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-echo.yml)
[![ci-yaml-check](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/ci-yaml-check.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/ci-yaml-check.yml)

- **sanity-main.yml** : diag quotidien / dispatch / push (artefacts)
- **sanity-echo.yml** : smoke déclenchable manuellement
- **ci-yaml-check.yml** : lint/validité YAML

Voir `docs/CI.md`.
<!-- CI:END -->3\_invariants\_vs\_T.png, fig\_<!-- CI:BEGIN -->
### CI (Workflows canoniques)

[![sanity-main](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-main.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-main.yml)
[![sanity-echo](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-echo.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-echo.yml)
[![ci-yaml-check](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/ci-yaml-check.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/ci-yaml-check.yml)

- **sanity-main.yml** : diag quotidien / dispatch / push (artefacts)
- **sanity-echo.yml** : smoke déclenchable manuellement
- **ci-yaml-check.yml** : lint/validité YAML

Voir `docs/CI.md`.
<!-- CI:END -->4\_relative\_deviations.png
* chap.<!-- CI:BEGIN -->
### CI (Workflows canoniques)

[![sanity-main](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-main.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-main.yml)
[![sanity-echo](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-echo.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-echo.yml)
[![ci-yaml-check](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/ci-yaml-check.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/ci-yaml-check.yml)

- **sanity-main.yml** : diag quotidien / dispatch / push (artefacts)
- **sanity-echo.yml** : smoke déclenchable manuellement
- **ci-yaml-check.yml** : lint/validité YAML

Voir `docs/CI.md`.
<!-- CI:END -->5 :
  * fig\_<!-- CI:BEGIN -->
### CI (Workflows canoniques)

[![sanity-main](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-main.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-main.yml)
[![sanity-echo](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-echo.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-echo.yml)
[![ci-yaml-check](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/ci-yaml-check.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/ci-yaml-check.yml)

- **sanity-main.yml** : diag quotidien / dispatch / push (artefacts)
- **sanity-echo.yml** : smoke déclenchable manuellement
- **ci-yaml-check.yml** : lint/validité YAML

Voir `docs/CI.md`.
<!-- CI:END -->1\_bbn\_reaction\_network.png, fig\_<!-- CI:BEGIN -->
### CI (Workflows canoniques)

[![sanity-main](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-main.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-main.yml)
[![sanity-echo](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-echo.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-echo.yml)
[![ci-yaml-check](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/ci-yaml-check.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/ci-yaml-check.yml)

- **sanity-main.yml** : diag quotidien / dispatch / push (artefacts)
- **sanity-echo.yml** : smoke déclenchable manuellement
- **ci-yaml-check.yml** : lint/validité YAML

Voir `docs/CI.md`.
<!-- CI:END -->2\_dh\_model\_vs\_obs.png, fig\_<!-- CI:BEGIN -->
### CI (Workflows canoniques)

[![sanity-main](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-main.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-main.yml)
[![sanity-echo](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-echo.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-echo.yml)
[![ci-yaml-check](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/ci-yaml-check.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/ci-yaml-check.yml)

- **sanity-main.yml** : diag quotidien / dispatch / push (artefacts)
- **sanity-echo.yml** : smoke déclenchable manuellement
- **ci-yaml-check.yml** : lint/validité YAML

Voir `docs/CI.md`.
<!-- CI:END -->3\_yp\_model\_vs\_obs.png, fig\_<!-- CI:BEGIN -->
### CI (Workflows canoniques)

[![sanity-main](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-main.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-main.yml)
[![sanity-echo](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-echo.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-echo.yml)
[![ci-yaml-check](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/ci-yaml-check.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/ci-yaml-check.yml)

- **sanity-main.yml** : diag quotidien / dispatch / push (artefacts)
- **sanity-echo.yml** : smoke déclenchable manuellement
- **ci-yaml-check.yml** : lint/validité YAML

Voir `docs/CI.md`.
<!-- CI:END -->4\_chi2\_vs\_T.png
* chap.<!-- CI:BEGIN -->
### CI (Workflows canoniques)

[![sanity-main](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-main.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-main.yml)
[![sanity-echo](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-echo.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-echo.yml)
[![ci-yaml-check](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/ci-yaml-check.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/ci-yaml-check.yml)

- **sanity-main.yml** : diag quotidien / dispatch / push (artefacts)
- **sanity-echo.yml** : smoke déclenchable manuellement
- **ci-yaml-check.yml** : lint/validité YAML

Voir `docs/CI.md`.
<!-- CI:END -->6 :
  * fig\_<!-- CI:BEGIN -->
### CI (Workflows canoniques)

[![sanity-main](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-main.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-main.yml)
[![sanity-echo](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-echo.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-echo.yml)
[![ci-yaml-check](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/ci-yaml-check.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/ci-yaml-check.yml)

- **sanity-main.yml** : diag quotidien / dispatch / push (artefacts)
- **sanity-echo.yml** : smoke déclenchable manuellement
- **ci-yaml-check.yml** : lint/validité YAML

Voir `docs/CI.md`.
<!-- CI:END -->1\_cmb\_dataflow\_diagram.png, fig\_<!-- CI:BEGIN -->
### CI (Workflows canoniques)

[![sanity-main](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-main.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-main.yml)
[![sanity-echo](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-echo.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-echo.yml)
[![ci-yaml-check](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/ci-yaml-check.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/ci-yaml-check.yml)

- **sanity-main.yml** : diag quotidien / dispatch / push (artefacts)
- **sanity-echo.yml** : smoke déclenchable manuellement
- **ci-yaml-check.yml** : lint/validité YAML

Voir `docs/CI.md`.
<!-- CI:END -->2\_cls\_lcdm\_vs\_mcgt.png, fig\_<!-- CI:BEGIN -->
### CI (Workflows canoniques)

[![sanity-main](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-main.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-main.yml)
[![sanity-echo](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-echo.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-echo.yml)
[![ci-yaml-check](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/ci-yaml-check.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/ci-yaml-check.yml)

- **sanity-main.yml** : diag quotidien / dispatch / push (artefacts)
- **sanity-echo.yml** : smoke déclenchable manuellement
- **ci-yaml-check.yml** : lint/validité YAML

Voir `docs/CI.md`.
<!-- CI:END -->3\_delta\_cls\_relative.png, fig\_<!-- CI:BEGIN -->
### CI (Workflows canoniques)

[![sanity-main](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-main.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-main.yml)
[![sanity-echo](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-echo.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-echo.yml)
[![ci-yaml-check](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/ci-yaml-check.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/ci-yaml-check.yml)

- **sanity-main.yml** : diag quotidien / dispatch / push (artefacts)
- **sanity-echo.yml** : smoke déclenchable manuellement
- **ci-yaml-check.yml** : lint/validité YAML

Voir `docs/CI.md`.
<!-- CI:END -->4\_delta\_rs\_vs\_params.png, fig\_<!-- CI:BEGIN -->
### CI (Workflows canoniques)

[![sanity-main](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-main.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-main.yml)
[![sanity-echo](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-echo.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-echo.yml)
[![ci-yaml-check](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/ci-yaml-check.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/ci-yaml-check.yml)

- **sanity-main.yml** : diag quotidien / dispatch / push (artefacts)
- **sanity-echo.yml** : smoke déclenchable manuellement
- **ci-yaml-check.yml** : lint/validité YAML

Voir `docs/CI.md`.
<!-- CI:END -->5\_delta\_chi2\_heatmap.png
* chap.<!-- CI:BEGIN -->
### CI (Workflows canoniques)

[![sanity-main](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-main.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-main.yml)
[![sanity-echo](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-echo.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-echo.yml)
[![ci-yaml-check](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/ci-yaml-check.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/ci-yaml-check.yml)

- **sanity-main.yml** : diag quotidien / dispatch / push (artefacts)
- **sanity-echo.yml** : smoke déclenchable manuellement
- **ci-yaml-check.yml** : lint/validité YAML

Voir `docs/CI.md`.
<!-- CI:END -->7 :
  * fig\_<!-- CI:BEGIN -->
### CI (Workflows canoniques)

[![sanity-main](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-main.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-main.yml)
[![sanity-echo](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-echo.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-echo.yml)
[![ci-yaml-check](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/ci-yaml-check.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/ci-yaml-check.yml)

- **sanity-main.yml** : diag quotidien / dispatch / push (artefacts)
- **sanity-echo.yml** : smoke déclenchable manuellement
- **ci-yaml-check.yml** : lint/validité YAML

Voir `docs/CI.md`.
<!-- CI:END --><!-- CI:BEGIN -->
### CI (Workflows canoniques)

[![sanity-main](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-main.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-main.yml)
[![sanity-echo](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-echo.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-echo.yml)
[![ci-yaml-check](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/ci-yaml-check.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/ci-yaml-check.yml)

- **sanity-main.yml** : diag quotidien / dispatch / push (artefacts)
- **sanity-echo.yml** : smoke déclenchable manuellement
- **ci-yaml-check.yml** : lint/validité YAML

Voir `docs/CI.md`.
<!-- CI:END -->\_loglog\_sampling\_test.png, fig\_<!-- CI:BEGIN -->
### CI (Workflows canoniques)

[![sanity-main](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-main.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-main.yml)
[![sanity-echo](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-echo.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-echo.yml)
[![ci-yaml-check](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/ci-yaml-check.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/ci-yaml-check.yml)

- **sanity-main.yml** : diag quotidien / dispatch / push (artefacts)
- **sanity-echo.yml** : smoke déclenchable manuellement
- **ci-yaml-check.yml** : lint/validité YAML

Voir `docs/CI.md`.
<!-- CI:END -->1\_cs2\_heatmap\_k\_a.png, fig\_<!-- CI:BEGIN -->
### CI (Workflows canoniques)

[![sanity-main](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-main.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-main.yml)
[![sanity-echo](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-echo.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-echo.yml)
[![ci-yaml-check](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/ci-yaml-check.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/ci-yaml-check.yml)

- **sanity-main.yml** : diag quotidien / dispatch / push (artefacts)
- **sanity-echo.yml** : smoke déclenchable manuellement
- **ci-yaml-check.yml** : lint/validité YAML

Voir `docs/CI.md`.
<!-- CI:END -->2\_delta\_phi\_heatmap\_k\_a.png, fig\_<!-- CI:BEGIN -->
### CI (Workflows canoniques)

[![sanity-main](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-main.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-main.yml)
[![sanity-echo](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-echo.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-echo.yml)
[![ci-yaml-check](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/ci-yaml-check.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/ci-yaml-check.yml)

- **sanity-main.yml** : diag quotidien / dispatch / push (artefacts)
- **sanity-echo.yml** : smoke déclenchable manuellement
- **ci-yaml-check.yml** : lint/validité YAML

Voir `docs/CI.md`.
<!-- CI:END -->3\_invariant\_I1.png, fig\_<!-- CI:BEGIN -->
### CI (Workflows canoniques)

[![sanity-main](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-main.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-main.yml)
[![sanity-echo](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-echo.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-echo.yml)
[![ci-yaml-check](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/ci-yaml-check.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/ci-yaml-check.yml)

- **sanity-main.yml** : diag quotidien / dispatch / push (artefacts)
- **sanity-echo.yml** : smoke déclenchable manuellement
- **ci-yaml-check.yml** : lint/validité YAML

Voir `docs/CI.md`.
<!-- CI:END -->4\_dcs2\_dk\_vs\_k.png, fig\_<!-- CI:BEGIN -->
### CI (Workflows canoniques)

[![sanity-main](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-main.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-main.yml)
[![sanity-echo](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-echo.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-echo.yml)
[![ci-yaml-check](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/ci-yaml-check.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/ci-yaml-check.yml)

- **sanity-main.yml** : diag quotidien / dispatch / push (artefacts)
- **sanity-echo.yml** : smoke déclenchable manuellement
- **ci-yaml-check.yml** : lint/validité YAML

Voir `docs/CI.md`.
<!-- CI:END -->5\_ddelta\_phi\_dk\_vs\_k.png, fig\_<!-- CI:BEGIN -->
### CI (Workflows canoniques)

[![sanity-main](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-main.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-main.yml)
[![sanity-echo](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-echo.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-echo.yml)
[![ci-yaml-check](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/ci-yaml-check.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/ci-yaml-check.yml)

- **sanity-main.yml** : diag quotidien / dispatch / push (artefacts)
- **sanity-echo.yml** : smoke déclenchable manuellement
- **ci-yaml-check.yml** : lint/validité YAML

Voir `docs/CI.md`.
<!-- CI:END -->6\_comparison.png, fig\_<!-- CI:BEGIN -->
### CI (Workflows canoniques)

[![sanity-main](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-main.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-main.yml)
[![sanity-echo](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-echo.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-echo.yml)
[![ci-yaml-check](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/ci-yaml-check.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/ci-yaml-check.yml)

- **sanity-main.yml** : diag quotidien / dispatch / push (artefacts)
- **sanity-echo.yml** : smoke déclenchable manuellement
- **ci-yaml-check.yml** : lint/validité YAML

Voir `docs/CI.md`.
<!-- CI:END -->7\_invariant\_I2.png
* chap.<!-- CI:BEGIN -->
### CI (Workflows canoniques)

[![sanity-main](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-main.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-main.yml)
[![sanity-echo](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-echo.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-echo.yml)
[![ci-yaml-check](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/ci-yaml-check.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/ci-yaml-check.yml)

- **sanity-main.yml** : diag quotidien / dispatch / push (artefacts)
- **sanity-echo.yml** : smoke déclenchable manuellement
- **ci-yaml-check.yml** : lint/validité YAML

Voir `docs/CI.md`.
<!-- CI:END -->8 :
  * fig\_<!-- CI:BEGIN -->
### CI (Workflows canoniques)

[![sanity-main](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-main.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-main.yml)
[![sanity-echo](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-echo.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-echo.yml)
[![ci-yaml-check](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/ci-yaml-check.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/ci-yaml-check.yml)

- **sanity-main.yml** : diag quotidien / dispatch / push (artefacts)
- **sanity-echo.yml** : smoke déclenchable manuellement
- **ci-yaml-check.yml** : lint/validité YAML

Voir `docs/CI.md`.
<!-- CI:END -->1\_chi2\_total\_vs\_q<!-- CI:BEGIN -->
### CI (Workflows canoniques)

[![sanity-main](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-main.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-main.yml)
[![sanity-echo](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-echo.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-echo.yml)
[![ci-yaml-check](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/ci-yaml-check.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/ci-yaml-check.yml)

- **sanity-main.yml** : diag quotidien / dispatch / push (artefacts)
- **sanity-echo.yml** : smoke déclenchable manuellement
- **ci-yaml-check.yml** : lint/validité YAML

Voir `docs/CI.md`.
<!-- CI:END -->.png, fig\_<!-- CI:BEGIN -->
### CI (Workflows canoniques)

[![sanity-main](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-main.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-main.yml)
[![sanity-echo](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-echo.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-echo.yml)
[![ci-yaml-check](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/ci-yaml-check.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/ci-yaml-check.yml)

- **sanity-main.yml** : diag quotidien / dispatch / push (artefacts)
- **sanity-echo.yml** : smoke déclenchable manuellement
- **ci-yaml-check.yml** : lint/validité YAML

Voir `docs/CI.md`.
<!-- CI:END -->2\_dv\_vs\_z.png, fig\_<!-- CI:BEGIN -->
### CI (Workflows canoniques)

[![sanity-main](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-main.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-main.yml)
[![sanity-echo](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-echo.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-echo.yml)
[![ci-yaml-check](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/ci-yaml-check.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/ci-yaml-check.yml)

- **sanity-main.yml** : diag quotidien / dispatch / push (artefacts)
- **sanity-echo.yml** : smoke déclenchable manuellement
- **ci-yaml-check.yml** : lint/validité YAML

Voir `docs/CI.md`.
<!-- CI:END -->3\_mu\_vs\_z.png, fig\_<!-- CI:BEGIN -->
### CI (Workflows canoniques)

[![sanity-main](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-main.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-main.yml)
[![sanity-echo](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-echo.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-echo.yml)
[![ci-yaml-check](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/ci-yaml-check.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/ci-yaml-check.yml)

- **sanity-main.yml** : diag quotidien / dispatch / push (artefacts)
- **sanity-echo.yml** : smoke déclenchable manuellement
- **ci-yaml-check.yml** : lint/validité YAML

Voir `docs/CI.md`.
<!-- CI:END -->4\_chi2\_heatmap.png, fig\_<!-- CI:BEGIN -->
### CI (Workflows canoniques)

[![sanity-main](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-main.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-main.yml)
[![sanity-echo](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-echo.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-echo.yml)
[![ci-yaml-check](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/ci-yaml-check.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/ci-yaml-check.yml)

- **sanity-main.yml** : diag quotidien / dispatch / push (artefacts)
- **sanity-echo.yml** : smoke déclenchable manuellement
- **ci-yaml-check.yml** : lint/validité YAML

Voir `docs/CI.md`.
<!-- CI:END -->5\_residuals.png, fig\_<!-- CI:BEGIN -->
### CI (Workflows canoniques)

[![sanity-main](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-main.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-main.yml)
[![sanity-echo](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-echo.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-echo.yml)
[![ci-yaml-check](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/ci-yaml-check.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/ci-yaml-check.yml)

- **sanity-main.yml** : diag quotidien / dispatch / push (artefacts)
- **sanity-echo.yml** : smoke déclenchable manuellement
- **ci-yaml-check.yml** : lint/validité YAML

Voir `docs/CI.md`.
<!-- CI:END -->6\_pulls.png, fig\_<!-- CI:BEGIN -->
### CI (Workflows canoniques)

[![sanity-main](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-main.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-main.yml)
[![sanity-echo](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-echo.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-echo.yml)
[![ci-yaml-check](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/ci-yaml-check.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/ci-yaml-check.yml)

- **sanity-main.yml** : diag quotidien / dispatch / push (artefacts)
- **sanity-echo.yml** : smoke déclenchable manuellement
- **ci-yaml-check.yml** : lint/validité YAML

Voir `docs/CI.md`.
<!-- CI:END -->7\_chi2\_profile.png
* chap.<!-- CI:BEGIN -->
### CI (Workflows canoniques)

[![sanity-main](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-main.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-main.yml)
[![sanity-echo](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-echo.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-echo.yml)
[![ci-yaml-check](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/ci-yaml-check.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/ci-yaml-check.yml)

- **sanity-main.yml** : diag quotidien / dispatch / push (artefacts)
- **sanity-echo.yml** : smoke déclenchable manuellement
- **ci-yaml-check.yml** : lint/validité YAML

Voir `docs/CI.md`.
<!-- CI:END -->9 :
  * fig\_<!-- CI:BEGIN -->
### CI (Workflows canoniques)

[![sanity-main](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-main.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-main.yml)
[![sanity-echo](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-echo.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-echo.yml)
[![ci-yaml-check](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/ci-yaml-check.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/ci-yaml-check.yml)

- **sanity-main.yml** : diag quotidien / dispatch / push (artefacts)
- **sanity-echo.yml** : smoke déclenchable manuellement
- **ci-yaml-check.yml** : lint/validité YAML

Voir `docs/CI.md`.
<!-- CI:END -->1\_phase\_overlay.png, fig\_<!-- CI:BEGIN -->
### CI (Workflows canoniques)

[![sanity-main](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-main.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-main.yml)
[![sanity-echo](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-echo.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-echo.yml)
[![ci-yaml-check](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/ci-yaml-check.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/ci-yaml-check.yml)

- **sanity-main.yml** : diag quotidien / dispatch / push (artefacts)
- **sanity-echo.yml** : smoke déclenchable manuellement
- **ci-yaml-check.yml** : lint/validité YAML

Voir `docs/CI.md`.
<!-- CI:END -->2\_residual\_phase.png, fig\_<!-- CI:BEGIN -->
### CI (Workflows canoniques)

[![sanity-main](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-main.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-main.yml)
[![sanity-echo](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-echo.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-echo.yml)
[![ci-yaml-check](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/ci-yaml-check.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/ci-yaml-check.yml)

- **sanity-main.yml** : diag quotidien / dispatch / push (artefacts)
- **sanity-echo.yml** : smoke déclenchable manuellement
- **ci-yaml-check.yml** : lint/validité YAML

Voir `docs/CI.md`.
<!-- CI:END -->3\_hist\_absdphi\_2<!-- CI:BEGIN -->
### CI (Workflows canoniques)

[![sanity-main](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-main.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-main.yml)
[![sanity-echo](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-echo.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-echo.yml)
[![ci-yaml-check](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/ci-yaml-check.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/ci-yaml-check.yml)

- **sanity-main.yml** : diag quotidien / dispatch / push (artefacts)
- **sanity-echo.yml** : smoke déclenchable manuellement
- **ci-yaml-check.yml** : lint/validité YAML

Voir `docs/CI.md`.
<!-- CI:END -->\_3<!-- CI:BEGIN -->
### CI (Workflows canoniques)

[![sanity-main](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-main.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-main.yml)
[![sanity-echo](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-echo.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-echo.yml)
[![ci-yaml-check](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/ci-yaml-check.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/ci-yaml-check.yml)

- **sanity-main.yml** : diag quotidien / dispatch / push (artefacts)
- **sanity-echo.yml** : smoke déclenchable manuellement
- **ci-yaml-check.yml** : lint/validité YAML

Voir `docs/CI.md`.
<!-- CI:END --><!-- CI:BEGIN -->
### CI (Workflows canoniques)

[![sanity-main](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-main.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-main.yml)
[![sanity-echo](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-echo.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-echo.yml)
[![ci-yaml-check](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/ci-yaml-check.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/ci-yaml-check.yml)

- **sanity-main.yml** : diag quotidien / dispatch / push (artefacts)
- **sanity-echo.yml** : smoke déclenchable manuellement
- **ci-yaml-check.yml** : lint/validité YAML

Voir `docs/CI.md`.
<!-- CI:END -->.png, fig\_<!-- CI:BEGIN -->
### CI (Workflows canoniques)

[![sanity-main](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-main.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-main.yml)
[![sanity-echo](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-echo.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-echo.yml)
[![ci-yaml-check](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/ci-yaml-check.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/ci-yaml-check.yml)

- **sanity-main.yml** : diag quotidien / dispatch / push (artefacts)
- **sanity-echo.yml** : smoke déclenchable manuellement
- **ci-yaml-check.yml** : lint/validité YAML

Voir `docs/CI.md`.
<!-- CI:END -->4\_absdphi\_milestones\_vs\_f.png, fig\_<!-- CI:BEGIN -->
### CI (Workflows canoniques)

[![sanity-main](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-main.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-main.yml)
[![sanity-echo](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-echo.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-echo.yml)
[![ci-yaml-check](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/ci-yaml-check.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/ci-yaml-check.yml)

- **sanity-main.yml** : diag quotidien / dispatch / push (artefacts)
- **sanity-echo.yml** : smoke déclenchable manuellement
- **ci-yaml-check.yml** : lint/validité YAML

Voir `docs/CI.md`.
<!-- CI:END -->5\_scatter\_phi\_at\_fpeak.png, p95\_methods/ (fig<!-- CI:BEGIN -->
### CI (Workflows canoniques)

[![sanity-main](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-main.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-main.yml)
[![sanity-echo](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-echo.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-echo.yml)
[![ci-yaml-check](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/ci-yaml-check.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/ci-yaml-check.yml)

- **sanity-main.yml** : diag quotidien / dispatch / push (artefacts)
- **sanity-echo.yml** : smoke déclenchable manuellement
- **ci-yaml-check.yml** : lint/validité YAML

Voir `docs/CI.md`.
<!-- CI:END -->3\_raw\_bins3<!-- CI:BEGIN -->
### CI (Workflows canoniques)

[![sanity-main](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-main.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-main.yml)
[![sanity-echo](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-echo.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-echo.yml)
[![ci-yaml-check](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/ci-yaml-check.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/ci-yaml-check.yml)

- **sanity-main.yml** : diag quotidien / dispatch / push (artefacts)
- **sanity-echo.yml** : smoke déclenchable manuellement
- **ci-yaml-check.yml** : lint/validité YAML

Voir `docs/CI.md`.
<!-- CI:END -->.png, fig<!-- CI:BEGIN -->
### CI (Workflows canoniques)

[![sanity-main](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-main.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-main.yml)
[![sanity-echo](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-echo.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-echo.yml)
[![ci-yaml-check](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/ci-yaml-check.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/ci-yaml-check.yml)

- **sanity-main.yml** : diag quotidien / dispatch / push (artefacts)
- **sanity-echo.yml** : smoke déclenchable manuellement
- **ci-yaml-check.yml** : lint/validité YAML

Voir `docs/CI.md`.
<!-- CI:END -->3\_raw\_bins5<!-- CI:BEGIN -->
### CI (Workflows canoniques)

[![sanity-main](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-main.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-main.yml)
[![sanity-echo](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-echo.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-echo.yml)
[![ci-yaml-check](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/ci-yaml-check.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/ci-yaml-check.yml)

- **sanity-main.yml** : diag quotidien / dispatch / push (artefacts)
- **sanity-echo.yml** : smoke déclenchable manuellement
- **ci-yaml-check.yml** : lint/validité YAML

Voir `docs/CI.md`.
<!-- CI:END -->.png, fig<!-- CI:BEGIN -->
### CI (Workflows canoniques)

[![sanity-main](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-main.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-main.yml)
[![sanity-echo](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-echo.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-echo.yml)
[![ci-yaml-check](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/ci-yaml-check.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/ci-yaml-check.yml)

- **sanity-main.yml** : diag quotidien / dispatch / push (artefacts)
- **sanity-echo.yml** : smoke déclenchable manuellement
- **ci-yaml-check.yml** : lint/validité YAML

Voir `docs/CI.md`.
<!-- CI:END -->3\_raw\_bins8<!-- CI:BEGIN -->
### CI (Workflows canoniques)

[![sanity-main](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-main.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-main.yml)
[![sanity-echo](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-echo.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-echo.yml)
[![ci-yaml-check](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/ci-yaml-check.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/ci-yaml-check.yml)

- **sanity-main.yml** : diag quotidien / dispatch / push (artefacts)
- **sanity-echo.yml** : smoke déclenchable manuellement
- **ci-yaml-check.yml** : lint/validité YAML

Voir `docs/CI.md`.
<!-- CI:END -->.png, fig<!-- CI:BEGIN -->
### CI (Workflows canoniques)

[![sanity-main](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-main.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-main.yml)
[![sanity-echo](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-echo.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-echo.yml)
[![ci-yaml-check](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/ci-yaml-check.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/ci-yaml-check.yml)

- **sanity-main.yml** : diag quotidien / dispatch / push (artefacts)
- **sanity-echo.yml** : smoke déclenchable manuellement
- **ci-yaml-check.yml** : lint/validité YAML

Voir `docs/CI.md`.
<!-- CI:END -->3\_rebranch\_k\_bins3<!-- CI:BEGIN -->
### CI (Workflows canoniques)

[![sanity-main](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-main.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-main.yml)
[![sanity-echo](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-echo.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-echo.yml)
[![ci-yaml-check](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/ci-yaml-check.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/ci-yaml-check.yml)

- **sanity-main.yml** : diag quotidien / dispatch / push (artefacts)
- **sanity-echo.yml** : smoke déclenchable manuellement
- **ci-yaml-check.yml** : lint/validité YAML

Voir `docs/CI.md`.
<!-- CI:END -->.png, fig<!-- CI:BEGIN -->
### CI (Workflows canoniques)

[![sanity-main](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-main.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-main.yml)
[![sanity-echo](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-echo.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-echo.yml)
[![ci-yaml-check](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/ci-yaml-check.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/ci-yaml-check.yml)

- **sanity-main.yml** : diag quotidien / dispatch / push (artefacts)
- **sanity-echo.yml** : smoke déclenchable manuellement
- **ci-yaml-check.yml** : lint/validité YAML

Voir `docs/CI.md`.
<!-- CI:END -->3\_rebranch\_k\_bins5<!-- CI:BEGIN -->
### CI (Workflows canoniques)

[![sanity-main](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-main.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-main.yml)
[![sanity-echo](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-echo.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-echo.yml)
[![ci-yaml-check](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/ci-yaml-check.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/ci-yaml-check.yml)

- **sanity-main.yml** : diag quotidien / dispatch / push (artefacts)
- **sanity-echo.yml** : smoke déclenchable manuellement
- **ci-yaml-check.yml** : lint/validité YAML

Voir `docs/CI.md`.
<!-- CI:END -->.png, fig<!-- CI:BEGIN -->
### CI (Workflows canoniques)

[![sanity-main](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-main.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-main.yml)
[![sanity-echo](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-echo.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-echo.yml)
[![ci-yaml-check](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/ci-yaml-check.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/ci-yaml-check.yml)

- **sanity-main.yml** : diag quotidien / dispatch / push (artefacts)
- **sanity-echo.yml** : smoke déclenchable manuellement
- **ci-yaml-check.yml** : lint/validité YAML

Voir `docs/CI.md`.
<!-- CI:END -->3\_rebranch\_k\_bins8<!-- CI:BEGIN -->
### CI (Workflows canoniques)

[![sanity-main](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-main.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-main.yml)
[![sanity-echo](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-echo.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-echo.yml)
[![ci-yaml-check](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/ci-yaml-check.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/ci-yaml-check.yml)

- **sanity-main.yml** : diag quotidien / dispatch / push (artefacts)
- **sanity-echo.yml** : smoke déclenchable manuellement
- **ci-yaml-check.yml** : lint/validité YAML

Voir `docs/CI.md`.
<!-- CI:END -->.png, fig<!-- CI:BEGIN -->
### CI (Workflows canoniques)

[![sanity-main](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-main.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-main.yml)
[![sanity-echo](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-echo.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-echo.yml)
[![ci-yaml-check](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/ci-yaml-check.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/ci-yaml-check.yml)

- **sanity-main.yml** : diag quotidien / dispatch / push (artefacts)
- **sanity-echo.yml** : smoke déclenchable manuellement
- **ci-yaml-check.yml** : lint/validité YAML

Voir `docs/CI.md`.
<!-- CI:END -->3\_unwrap\_bins3<!-- CI:BEGIN -->
### CI (Workflows canoniques)

[![sanity-main](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-main.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-main.yml)
[![sanity-echo](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-echo.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-echo.yml)
[![ci-yaml-check](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/ci-yaml-check.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/ci-yaml-check.yml)

- **sanity-main.yml** : diag quotidien / dispatch / push (artefacts)
- **sanity-echo.yml** : smoke déclenchable manuellement
- **ci-yaml-check.yml** : lint/validité YAML

Voir `docs/CI.md`.
<!-- CI:END -->.png, fig<!-- CI:BEGIN -->
### CI (Workflows canoniques)

[![sanity-main](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-main.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-main.yml)
[![sanity-echo](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-echo.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-echo.yml)
[![ci-yaml-check](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/ci-yaml-check.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/ci-yaml-check.yml)

- **sanity-main.yml** : diag quotidien / dispatch / push (artefacts)
- **sanity-echo.yml** : smoke déclenchable manuellement
- **ci-yaml-check.yml** : lint/validité YAML

Voir `docs/CI.md`.
<!-- CI:END -->3\_unwrap\_bins5<!-- CI:BEGIN -->
### CI (Workflows canoniques)

[![sanity-main](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-main.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-main.yml)
[![sanity-echo](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-echo.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-echo.yml)
[![ci-yaml-check](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/ci-yaml-check.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/ci-yaml-check.yml)

- **sanity-main.yml** : diag quotidien / dispatch / push (artefacts)
- **sanity-echo.yml** : smoke déclenchable manuellement
- **ci-yaml-check.yml** : lint/validité YAML

Voir `docs/CI.md`.
<!-- CI:END -->.png, fig<!-- CI:BEGIN -->
### CI (Workflows canoniques)

[![sanity-main](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-main.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-main.yml)
[![sanity-echo](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-echo.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-echo.yml)
[![ci-yaml-check](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/ci-yaml-check.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/ci-yaml-check.yml)

- **sanity-main.yml** : diag quotidien / dispatch / push (artefacts)
- **sanity-echo.yml** : smoke déclenchable manuellement
- **ci-yaml-check.yml** : lint/validité YAML

Voir `docs/CI.md`.
<!-- CI:END -->3\_unwrap\_bins8<!-- CI:BEGIN -->
### CI (Workflows canoniques)

[![sanity-main](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-main.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-main.yml)
[![sanity-echo](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-echo.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-echo.yml)
[![ci-yaml-check](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/ci-yaml-check.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/ci-yaml-check.yml)

- **sanity-main.yml** : diag quotidien / dispatch / push (artefacts)
- **sanity-echo.yml** : smoke déclenchable manuellement
- **ci-yaml-check.yml** : lint/validité YAML

Voir `docs/CI.md`.
<!-- CI:END -->.png), p95\_check\_control.png
* chap.1<!-- CI:BEGIN -->
### CI (Workflows canoniques)

[![sanity-main](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-main.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-main.yml)
[![sanity-echo](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-echo.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-echo.yml)
[![ci-yaml-check](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/ci-yaml-check.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/ci-yaml-check.yml)

- **sanity-main.yml** : diag quotidien / dispatch / push (artefacts)
- **sanity-echo.yml** : smoke déclenchable manuellement
- **ci-yaml-check.yml** : lint/validité YAML

Voir `docs/CI.md`.
<!-- CI:END --> :
  * fig\_<!-- CI:BEGIN -->
### CI (Workflows canoniques)

[![sanity-main](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-main.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-main.yml)
[![sanity-echo](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-echo.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-echo.yml)
[![ci-yaml-check](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/ci-yaml-check.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/ci-yaml-check.yml)

- **sanity-main.yml** : diag quotidien / dispatch / push (artefacts)
- **sanity-echo.yml** : smoke déclenchable manuellement
- **ci-yaml-check.yml** : lint/validité YAML

Voir `docs/CI.md`.
<!-- CI:END -->1\_iso\_p95\_maps.png, fig\_<!-- CI:BEGIN -->
### CI (Workflows canoniques)

[![sanity-main](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-main.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-main.yml)
[![sanity-echo](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-echo.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-echo.yml)
[![ci-yaml-check](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/ci-yaml-check.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/ci-yaml-check.yml)

- **sanity-main.yml** : diag quotidien / dispatch / push (artefacts)
- **sanity-echo.yml** : smoke déclenchable manuellement
- **ci-yaml-check.yml** : lint/validité YAML

Voir `docs/CI.md`.
<!-- CI:END -->2\_scatter\_phi\_at\_fpeak.png, fig\_<!-- CI:BEGIN -->
### CI (Workflows canoniques)

[![sanity-main](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-main.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-main.yml)
[![sanity-echo](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-echo.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-echo.yml)
[![ci-yaml-check](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/ci-yaml-check.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/ci-yaml-check.yml)

- **sanity-main.yml** : diag quotidien / dispatch / push (artefacts)
- **sanity-echo.yml** : smoke déclenchable manuellement
- **ci-yaml-check.yml** : lint/validité YAML

Voir `docs/CI.md`.
<!-- CI:END -->3b\_coverage\_bootstrap\_vs\_n\_hires.png, fig\_<!-- CI:BEGIN -->
### CI (Workflows canoniques)

[![sanity-main](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-main.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-main.yml)
[![sanity-echo](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-echo.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-echo.yml)
[![ci-yaml-check](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/ci-yaml-check.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/ci-yaml-check.yml)

- **sanity-main.yml** : diag quotidien / dispatch / push (artefacts)
- **sanity-echo.yml** : smoke déclenchable manuellement
- **ci-yaml-check.yml** : lint/validité YAML

Voir `docs/CI.md`.
<!-- CI:END -->3\_convergence\_p95\_vs\_n.png, fig\_<!-- CI:BEGIN -->
### CI (Workflows canoniques)

[![sanity-main](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-main.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-main.yml)
[![sanity-echo](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-echo.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-echo.yml)
[![ci-yaml-check](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/ci-yaml-check.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/ci-yaml-check.yml)

- **sanity-main.yml** : diag quotidien / dispatch / push (artefacts)
- **sanity-echo.yml** : smoke déclenchable manuellement
- **ci-yaml-check.yml** : lint/validité YAML

Voir `docs/CI.md`.
<!-- CI:END -->4\_scatter\_p95\_recalc\_vs\_orig.png, fig\_<!-- CI:BEGIN -->
### CI (Workflows canoniques)

[![sanity-main](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-main.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-main.yml)
[![sanity-echo](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-echo.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-echo.yml)
[![ci-yaml-check](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/ci-yaml-check.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/ci-yaml-check.yml)

- **sanity-main.yml** : diag quotidien / dispatch / push (artefacts)
- **sanity-echo.yml** : smoke déclenchable manuellement
- **ci-yaml-check.yml** : lint/validité YAML

Voir `docs/CI.md`.
<!-- CI:END -->5\_hist\_cdf\_metrics.png, fig\_<!-- CI:BEGIN -->
### CI (Workflows canoniques)

[![sanity-main](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-main.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-main.yml)
[![sanity-echo](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-echo.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-echo.yml)
[![ci-yaml-check](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/ci-yaml-check.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/ci-yaml-check.yml)

- **sanity-main.yml** : diag quotidien / dispatch / push (artefacts)
- **sanity-echo.yml** : smoke déclenchable manuellement
- **ci-yaml-check.yml** : lint/validité YAML

Voir `docs/CI.md`.
<!-- CI:END -->6\_heatmap\_absdp95\_m1m2.png, fig\_<!-- CI:BEGIN -->
### CI (Workflows canoniques)

[![sanity-main](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-main.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-main.yml)
[![sanity-echo](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-echo.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-echo.yml)
[![ci-yaml-check](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/ci-yaml-check.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/ci-yaml-check.yml)

- **sanity-main.yml** : diag quotidien / dispatch / push (artefacts)
- **sanity-echo.yml** : smoke déclenchable manuellement
- **ci-yaml-check.yml** : lint/validité YAML

Voir `docs/CI.md`.
<!-- CI:END -->7\_summary\_comparison.png
---
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
* zz-manifests/chapters/chapter\_manifest\_{<!-- CI:BEGIN -->
### CI (Workflows canoniques)

[![sanity-main](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-main.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-main.yml)
[![sanity-echo](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-echo.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-echo.yml)
[![ci-yaml-check](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/ci-yaml-check.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/ci-yaml-check.yml)

- **sanity-main.yml** : diag quotidien / dispatch / push (artefacts)
- **sanity-echo.yml** : smoke déclenchable manuellement
- **ci-yaml-check.yml** : lint/validité YAML

Voir `docs/CI.md`.
<!-- CI:END -->1..1<!-- CI:BEGIN -->
### CI (Workflows canoniques)

[![sanity-main](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-main.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-main.yml)
[![sanity-echo](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-echo.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-echo.yml)
[![ci-yaml-check](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/ci-yaml-check.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/ci-yaml-check.yml)

- **sanity-main.yml** : diag quotidien / dispatch / push (artefacts)
- **sanity-echo.yml** : smoke déclenchable manuellement
- **ci-yaml-check.yml** : lint/validité YAML

Voir `docs/CI.md`.
<!-- CI:END -->}.json — manifests par chapitre.
* zz-manifests/reports/ — exports/rapports additionnels.
* README-REPRO.md — procédure reproductible détaillée.
* RUNBOOK.md — séquences d’exécution standard (pipeline).
Note : un meta\_template.json existe aussi sous zz-configuration/ (référence croisée). La version maître est celle de zz-manifests/.
---
## 8) Conventions & styles
* conventions.md : normes de nommage (FR), unités (SI), précision numérique, format CSV/DAT/JSON, styles de figures, seuils de QA, sémantique des colonnes, règles pour jalons et classes (primaire/ordre2), etc.
* Cohérence inter-chapitres : les paramètres transverses (p. ex. alpha, q<!-- CI:BEGIN -->
### CI (Workflows canoniques)

[![sanity-main](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-main.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-main.yml)
[![sanity-echo](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-echo.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-echo.yml)
[![ci-yaml-check](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/ci-yaml-check.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/ci-yaml-check.yml)

- **sanity-main.yml** : diag quotidien / dispatch / push (artefacts)
- **sanity-echo.yml** : smoke déclenchable manuellement
- **ci-yaml-check.yml** : lint/validité YAML

Voir `docs/CI.md`.
<!-- CI:END -->star, fenêtres de fréquences, ell\_min/max, etc.) doivent être harmonisés via mcgt-global-config.ini et les JSON de paramètres par chapitre.
---
## 9) Environnements & dépendances
* Python ≥ 3.1<!-- CI:BEGIN -->
### CI (Workflows canoniques)

[![sanity-main](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-main.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-main.yml)
[![sanity-echo](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-echo.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-echo.yml)
[![ci-yaml-check](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/ci-yaml-check.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/ci-yaml-check.yml)

- **sanity-main.yml** : diag quotidien / dispatch / push (artefacts)
- **sanity-echo.yml** : smoke déclenchable manuellement
- **ci-yaml-check.yml** : lint/validité YAML

Voir `docs/CI.md`.
<!-- CI:END --> recommandé.
  Installation (pip) :
  pip install -r requirements.txt
  Environnement Conda :
  conda env create -f environment.yml
  conda activate mcgt
  Chap. 9/1<!-- CI:BEGIN -->
### CI (Workflows canoniques)

[![sanity-main](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-main.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-main.yml)
[![sanity-echo](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-echo.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-echo.yml)
[![ci-yaml-check](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/ci-yaml-check.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/ci-yaml-check.yml)

- **sanity-main.yml** : diag quotidien / dispatch / push (artefacts)
- **sanity-echo.yml** : smoke déclenchable manuellement
- **ci-yaml-check.yml** : lint/validité YAML

Voir `docs/CI.md`.
<!-- CI:END --> : références d’onde (IMRPhenom) indiquées dans les métadonnées ; LALSuite peut être requis côté référence si régénération complète (voir RUNBOOK.md).
* Fichiers requirements par chapitre :
  * zz-scripts/chapter<!-- CI:BEGIN -->
### CI (Workflows canoniques)

[![sanity-main](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-main.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-main.yml)
[![sanity-echo](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-echo.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-echo.yml)
[![ci-yaml-check](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/ci-yaml-check.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/ci-yaml-check.yml)

- **sanity-main.yml** : diag quotidien / dispatch / push (artefacts)
- **sanity-echo.yml** : smoke déclenchable manuellement
- **ci-yaml-check.yml** : lint/validité YAML

Voir `docs/CI.md`.
<!-- CI:END -->1/requirements.txt
  * zz-scripts/chapter<!-- CI:BEGIN -->
### CI (Workflows canoniques)

[![sanity-main](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-main.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-main.yml)
[![sanity-echo](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-echo.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-echo.yml)
[![ci-yaml-check](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/ci-yaml-check.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/ci-yaml-check.yml)

- **sanity-main.yml** : diag quotidien / dispatch / push (artefacts)
- **sanity-echo.yml** : smoke déclenchable manuellement
- **ci-yaml-check.yml** : lint/validité YAML

Voir `docs/CI.md`.
<!-- CI:END -->2/requirements.txt
  * zz-scripts/chapter<!-- CI:BEGIN -->
### CI (Workflows canoniques)

[![sanity-main](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-main.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-main.yml)
[![sanity-echo](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-echo.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-echo.yml)
[![ci-yaml-check](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/ci-yaml-check.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/ci-yaml-check.yml)

- **sanity-main.yml** : diag quotidien / dispatch / push (artefacts)
- **sanity-echo.yml** : smoke déclenchable manuellement
- **ci-yaml-check.yml** : lint/validité YAML

Voir `docs/CI.md`.
<!-- CI:END -->3/requirements.txt
  * zz-scripts/chapter<!-- CI:BEGIN -->
### CI (Workflows canoniques)

[![sanity-main](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-main.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-main.yml)
[![sanity-echo](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-echo.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-echo.yml)
[![ci-yaml-check](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/ci-yaml-check.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/ci-yaml-check.yml)

- **sanity-main.yml** : diag quotidien / dispatch / push (artefacts)
- **sanity-echo.yml** : smoke déclenchable manuellement
- **ci-yaml-check.yml** : lint/validité YAML

Voir `docs/CI.md`.
<!-- CI:END -->4/requirements.txt
  * zz-scripts/chapter<!-- CI:BEGIN -->
### CI (Workflows canoniques)

[![sanity-main](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-main.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-main.yml)
[![sanity-echo](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-echo.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-echo.yml)
[![ci-yaml-check](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/ci-yaml-check.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/ci-yaml-check.yml)

- **sanity-main.yml** : diag quotidien / dispatch / push (artefacts)
- **sanity-echo.yml** : smoke déclenchable manuellement
- **ci-yaml-check.yml** : lint/validité YAML

Voir `docs/CI.md`.
<!-- CI:END -->5/requirements.txt
  * zz-scripts/chapter<!-- CI:BEGIN -->
### CI (Workflows canoniques)

[![sanity-main](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-main.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-main.yml)
[![sanity-echo](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-echo.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-echo.yml)
[![ci-yaml-check](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/ci-yaml-check.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/ci-yaml-check.yml)

- **sanity-main.yml** : diag quotidien / dispatch / push (artefacts)
- **sanity-echo.yml** : smoke déclenchable manuellement
- **ci-yaml-check.yml** : lint/validité YAML

Voir `docs/CI.md`.
<!-- CI:END -->6/requirements.txt
  * zz-scripts/chapter<!-- CI:BEGIN -->
### CI (Workflows canoniques)

[![sanity-main](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-main.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-main.yml)
[![sanity-echo](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-echo.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-echo.yml)
[![ci-yaml-check](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/ci-yaml-check.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/ci-yaml-check.yml)

- **sanity-main.yml** : diag quotidien / dispatch / push (artefacts)
- **sanity-echo.yml** : smoke déclenchable manuellement
- **ci-yaml-check.yml** : lint/validité YAML

Voir `docs/CI.md`.
<!-- CI:END -->7/requirements.txt
  * zz-scripts/chapter<!-- CI:BEGIN -->
### CI (Workflows canoniques)

[![sanity-main](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-main.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-main.yml)
[![sanity-echo](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-echo.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-echo.yml)
[![ci-yaml-check](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/ci-yaml-check.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/ci-yaml-check.yml)

- **sanity-main.yml** : diag quotidien / dispatch / push (artefacts)
- **sanity-echo.yml** : smoke déclenchable manuellement
- **ci-yaml-check.yml** : lint/validité YAML

Voir `docs/CI.md`.
<!-- CI:END -->8/requirements.txt
  * zz-scripts/chapter<!-- CI:BEGIN -->
### CI (Workflows canoniques)

[![sanity-main](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-main.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-main.yml)
[![sanity-echo](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-echo.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-echo.yml)
[![ci-yaml-check](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/ci-yaml-check.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/ci-yaml-check.yml)

- **sanity-main.yml** : diag quotidien / dispatch / push (artefacts)
- **sanity-echo.yml** : smoke déclenchable manuellement
- **ci-yaml-check.yml** : lint/validité YAML

Voir `docs/CI.md`.
<!-- CI:END -->9/requirements.txt
  * zz-scripts/chapter1<!-- CI:BEGIN -->
### CI (Workflows canoniques)

[![sanity-main](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-main.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-main.yml)
[![sanity-echo](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-echo.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-echo.yml)
[![ci-yaml-check](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/ci-yaml-check.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/ci-yaml-check.yml)

- **sanity-main.yml** : diag quotidien / dispatch / push (artefacts)
- **sanity-echo.yml** : smoke déclenchable manuellement
- **ci-yaml-check.yml** : lint/validité YAML

Voir `docs/CI.md`.
<!-- CI:END -->/requirements.txt
---
## 1<!-- CI:BEGIN -->
### CI (Workflows canoniques)

[![sanity-main](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-main.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-main.yml)
[![sanity-echo](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-echo.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/sanity-echo.yml)
[![ci-yaml-check](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/ci-yaml-check.yml/badge.svg?branch=main)](https://github.com/JeanPhilipLalumiere/MCGT/actions/workflows/ci-yaml-check.yml)

- **sanity-main.yml** : diag quotidien / dispatch / push (artefacts)
- **sanity-echo.yml** : smoke déclenchable manuellement
- **ci-yaml-check.yml** : lint/validité YAML

Voir `docs/CI.md`.
<!-- CI:END -->) Commandes utiles & QA
Aide :
make help
Générer données d’un chapitre (ex. chap. 4) :
make data-chapter N=4
Générer figures d’un chapitre :
make figures-chapter N=4
Pipeline complet (données + figures) :
make all
Contrôle de cohérence manifest :
python zz-manifests/diag\_consistency.py --manifest zz-manifests/manifest\_master.json --report zz-manifests/manifest\_report.json
Pour des validations supplémentaires :
* JSON : python zz-schemas/validate\_json.py \<schema.json> \<fichier.json>
* CSV (tables) : python zz-schemas/validate\_csv\_table.py \<table\_schema.json> \<fichier.csv>
* Schéma CSV (structure) : python zz-schemas/validate\_csv\_schema.py \<schema.json>
* Globals de validation : zz-schemas/validation\_globals.json
---
## 11) Licence / Contact
* Licence : à préciser (interne / publique) — voir fichier LICENSE.
* Contact scientifique : responsable MCGT.
* Contact technique : mainteneur des scripts / CI.
<!-- CI:BEGIN -->
CI (Workflows canoniques)
sanity-main.yml
sanity-echo.yml
ci-yaml-check.yml
Voir docs/CI.md.
<!-- CI:END -->
<!-- CI:BEGIN -->
CI (Workflows canoniques)
sanity-main.yml
sanity-echo.yml
ci-yaml-check.yml
Voir docs/CI.md.
<!-- CI:END -->
<!-- CI:BEGIN -->
CI (Workflows canoniques)
sanity-main.yml
sanity-echo.yml
ci-yaml-check.yml
Voir docs/CI.md.
<!-- CI:END -->
<!-- CI:BEGIN -->
CI (Workflows canoniques)
sanity-main.yml
sanity-echo.yml
ci-yaml-check.yml
Voir docs/CI.md.
<!-- CI:END -->

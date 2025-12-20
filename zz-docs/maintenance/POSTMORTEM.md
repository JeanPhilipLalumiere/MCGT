# Post-mortem publication mcgt-core

## Contexte
- Publication via GitHub Actions (tag v*), OIDC Trusted Publishing vers PyPI.

## Incidents résolus
- YAML de workflow tronqué ⇒ aucun run sur tag.
- Tags pointant sur des commits sans workflow complet.
- Dépendances runtime manquantes (`numpy`, `scipy`) ⇒ déclarées.

## Correctifs
- Workflow stable: build → vérif tag==version → publish.
- Script Phase 4 robuste (fenêtre maintenue ouverte).
- Procédure release automatisée (`scripts/release.sh`).

## Prévention
- Toujours bumper **pyproject** + **mcgt/__init__.py** ensemble.
- Commit puis tag sur **ce même commit**.
- Linter YAML en pré-commit.

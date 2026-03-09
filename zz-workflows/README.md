# Workflows CI/CD

Ce dossier contient l'automatisation GitHub Actions utilisée pour la release v4.0.0.

- `ci.yml` : installe les dépendances, met en cache `pip`, exécute `pytest`,
  les validateurs de schémas et les vérifications de cohérence.
- `release.yml` : à chaque tag `vX.Y.Z`, construit `sdist` + `wheel`
  et attache les artefacts à la release GitHub.

## Variables et secrets

Aucun secret n'est requis par défaut pour la build locale des artefacts.
Pour une publication externe (PyPI/Zenodo), ajouter les secrets nécessaires
dans les paramètres GitHub du dépôt.

## Conseils

- Garder `requirements.txt` et `pyproject.toml` synchronisés.
- Utiliser des jeux de données réduits pour les tests CI afin de limiter le temps d'exécution.

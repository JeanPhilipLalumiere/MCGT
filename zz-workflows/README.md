\# Workflows CI/CD



Ce dossier contient l’automatisation GitHub Actions :



\- \*\*ci.yml\*\* : installe les dépendances, met en cache `pip`, exécute `pytest`,

&nbsp; lance les validateurs de schémas (`zz-schemas/validate\_\*`) et le diagnostic manifest

&nbsp; (`zz-manifests/diag\_consistency.py` en `--dry-run`).

\- \*\*release.yml\*\* : à chaque tag `vX.Y.Z`, construit `sdist` + `wheel` et publie

&nbsp; les artefacts dans la \_release\_ GitHub.



\## Variables \& secrets



Aucun secret requis par défaut. Pour publier ailleurs (PyPI, Zenodo), ajouter

les credentials correspondants dans les \_secrets\_ du dépôt et étendre `release.yml`.



\## Conseils



\- Garder `requirements.txt` et `mcgt/pyproject.toml` synchronisés.

\- Préparer des jeux de données \*\*réduits\*\* pour les tests (fixtures) afin d’éviter

&nbsp; des temps de CI trop longs.

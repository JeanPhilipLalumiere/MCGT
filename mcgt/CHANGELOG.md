\# Changelog — MCGT



Toutes les modifications notables de ce projet seront documentées ici.



\## \[0.2.0] — 2025-09-10

\### Ajouté

\- \*\*CI GitHub Actions\*\* : workflow `ci.yml` (cache pip, tests, validateurs, diagnostic de manifests).

\- \*\*Release\*\* : workflow `release.yml` (build sdist/wheel et ajout aux releases GitHub).

\- \*\*Qualité\*\* : `.pre-commit-config.yaml` (black, isort, flake8, validateurs JSON/CSV, diag manifests).

\- \*\*Packaging\*\* : `pyproject.toml` (métadonnées alignées avec `setup.py`), fichier de licence, changelog.

\- \*\*Config\*\* : `mcgt-global-config.ini.template` + `README` explicatif dans `configuration`.

\- \*\*Docs schémas\*\* : `assets/zz-schemas/README.md`.



\### Modifié

\- Harmonisation des conventions de noms (FR → EN pour chemins), et préparation de la future migration via `assets/zz-manifests/migration\_map.json`.



\### Corrigé

\- Petites incohérences de normalisation de classes (`primaire`/`ordre2`) désormais cartographiées via le fichier de migration.

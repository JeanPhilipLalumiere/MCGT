# Intégration Continue (CI)

Workflows canoniques gardés :
- `sanity-main.yml` — diag quotidien / `workflow_dispatch` / `push` (artefacts `sanity-diag`)
- `sanity-echo.yml` — smoke/echo déclenchable
- `ci-yaml-check.yml` — lint/validité YAML (pré-commit)

Bonnes pratiques en place :
- **concurrency** séparée par event (`${{ github.event_name }}`) pour éviter les annulations intempestives,
- **paths-ignore** sur docs/markdown/logs pour les push,
- **timeout** raisonnable sur les jobs,
- artefacts **uploadés** et **récupérés** via `tools/ci_run_sanity_and_fetch.sh`,
- vérification **sans relancer** : `tools/ci_show_last_sanity.sh`.

Scripts utilitaires :
- `tools/ci_run_sanity_and_fetch.sh` — déclenche, watch, télécharge, affiche `diag.json`
- `tools/ci_show_last_sanity.sh` — affiche le dernier diag sans relancer
- `tools/ci_update_readme_ci_section.sh` — met à jour l’encart CI du README (badges)
- `tools/ci_purge_old_ci_logs.sh` — ménage `.ci-logs` (>7j) et `.ci-archive` (>30j)

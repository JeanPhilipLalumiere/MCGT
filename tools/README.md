# tools (normalized)

Ce dossier a ete nettoye pour la release v4.0.0.

## Conserve (actif)

- `__init__.py` : API minimale du package `tools`.
- `common_io.py` : utilitaires utilises par des scripts actifs (`p95`, normalisation de colonnes).
- `check_integrity.py` : verification des manifests d'integrite.
- `gen_integrity_manifest.py` : regeneration de `assets/zz-manifests/integrity.json`.
- `scan_assets_budget.py` : stub budget (retour neutre pour CI locale).
- `audit_workflows.sh`, `no_plusx_nonscripts.sh`, `forbid_bom_crlf_tabs.sh` :
  scripts utilises par l'action GitHub `workflow-hygiene`.

## Archive

Le reste de l'ancien outillage a ete archive sous:

- `archives/tools_legacy_20260309/tools/`

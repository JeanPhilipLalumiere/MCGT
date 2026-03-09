# Archive `tools` legacy (2026-03-09)

Ce dossier contient l'ancien contenu historique de `tools/` archive lors du menage profond.

## Objectif

- conserver une trace complete des scripts legacy non requis pour l'execution v4.0.0 ;
- reduire `tools/` a un noyau minimal maintenable et compatible CI/Makefile.

## Emplacement source

- `tools/*` (avant normalisation)

## Noyau conserve dans `tools/`

- `__init__.py`
- `common_io.py`
- `check_integrity.py`
- `gen_integrity_manifest.py`
- `scan_assets_budget.py`
- `audit_workflows.sh`
- `no_plusx_nonscripts.sh`
- `forbid_bom_crlf_tabs.sh`
- `README.md`

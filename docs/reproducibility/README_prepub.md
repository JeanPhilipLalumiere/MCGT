# MCGT — Prépublication (scripts + données + figures)

Cette prépublication **n'inclut pas** encore les fichiers `.tex` finalisés.
Sont inclus : `assets/zz-figures/` (noms canoniques; `_legacy_conflicts/` ignoré), `assets/zz-data/`, `scripts/`, `tools/`, `assets/zz-manifests/` (manifest/indices).

## Reproduire et vérifier
```bash
make guard-local
bash tools/check_figures_index.sh
bash tools/build_prepub_bundle.sh
sha256sum -c assets/zz-manifests/prepub_sha256.txt
```

## Environnement Python
Générer/mettre à jour le lock minimal :
```bash
MCGT_NO_SHELL_DROP=1 bash tools/lock_environment.sh
```

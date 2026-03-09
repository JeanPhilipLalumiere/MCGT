# config (normalized)

Ce repertoire contient les configurations partagees pour la release v4.0.0.

## Fichiers canoniques

- `mcgt-global-config.ini`
- `mcgt-global-config.ini.template`
- `camb_exact_plateau.ini`
- `gw_phase.ini`
- `scalar_perturbations.ini`
- `python_constants_registry.json`
- `defaults.yml`
- `GWTC-3-confident-events.json`

## Donnees auxiliaires

- `pdot_plateau_z.dat` : fichier actif utilise par les scripts chapter06.
- `pdot_plateau_vs_z.dat` : conserve pour compatibilite legacy et documentation historique.

## Bonnes pratiques

- Conserver des chemins relatifs.
- Ne pas stocker de secrets dans ce dossier.

# MCGT v2.4.0 - Unified Cosmology

## Changements majeurs
- Centralisation de la cosmologie : toutes les constantes sont désormais lues depuis `mcgt-global-config.ini`.
- Intégration de la Likelihood BAO et Pantheon+ dans le moteur MCMC.
- Résolution de la tension de 3σ via l'extension du modèle à l'énergie noire dynamique (CPL).

## Performances du modele (Best-Fit)
- Ωm = 0.3010
- w0 = -0.2433
- wa = -2.9981
- χ²_total (SN+BAO+CMB) = 1170.423
- χ²_total (SN+BAO, sans CMB) = 1163.068
- H0 = 67.36

## Parametres de reconciliation (Best-Fit)
- H0 = 67.36
- Ωm = 0.3010
- w0 = -0.2433
- wa = -2.9981

## Audit de coherence
- `check_coherence.py` : succes (COHERENCE OK : parametres cosmologiques alignes.)

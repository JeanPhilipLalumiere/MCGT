# MCGT v2.4.0 - Unified Cosmology

## Changements majeurs
- Centralisation de la cosmologie : toutes les constantes sont désormais lues depuis `mcgt-global-config.ini`.
- Intégration de la Likelihood BAO et Pantheon+ dans le moteur MCMC.
- Résolution de la tension de 3σ via l'extension du modèle à l'énergie noire dynamique (CPL).

## Performances du modele (Best-Fit)
- Ωm = 0.288 ± 0.015
- w0 = -0.53 ± 0.12
- wa = -1.06 ± 0.35
- χ²_total = 1187.73 (contre 1322.09 pour ΛCDM avec H0 Planck)
- Δχ² ≈ -134
- H0 ≈ 67.9

## Parametres de reconciliation (Best-Fit)
- H0 ≈ 67.9
- Ωm ≈ 0.288
- w0 ≈ -0.53
- wa ≈ -1.06

## Audit de coherence
- `check_coherence.py` : succes (COHERENCE OK : parametres cosmologiques alignes.)

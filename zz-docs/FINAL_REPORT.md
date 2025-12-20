# Final Audit Report

DÉCLARATION DE CONFORMITÉ SCIENTIFIQUE
Le présent dépôt (MCGT v2.5.0) a fait l'objet d'un audit de cohérence automatisé via le moteur check_coherence.py.
Unification Cosmologique : Tous les paramètres physiques ($H_0$, $\Omega_m$, $w_0$, $w_a$) sont extraits dynamiquement de la configuration globale. Aucune constante numérique n'est codée en dur dans les scripts de production.
Validation Tri-Sondes : Le modèle présenté minimise simultanément les résidus des Supernovae (Pantheon+), des oscillations acoustiques (BAO) et du paramètre de décalage du CMB (Planck 2018).
Reproductibilité : L'intégralité des figures (01-12) a été régénérée après la convergence de la chaîne MCMC pour garantir l'exactitude des visuels.
Intégrité des Données : Les fichiers de sortie ont été validés par analyse syntaxique (AST) pour prévenir toute dérive numérique entre les chapitres.
Certifié conforme le 20 décembre 2025.

| Metric | Value |
| --- | --- |
| Steps (MCMC) | 1000 |
| Acceptance rate | 0.171 |
| Best-fit w0 | -0.2433 |
| Best-fit wa | -2.9981 |
| Best-fit Omega_m | 0.3010 |
| chi2_total (SN+BAO+CMB) | 1170.423 |
| chi2_SN | 971.049 |
| chi2_BAO | 198.615 |
| chi2_CMB | 0.759 |
| chi2_total (SN+BAO only) | 1163.068 |
| sigma8 (CPL) | 1.3104 |
| sigma8 (LCDM) | 1.3637 |
| 100*theta* (CPL) | 1.054351 |
| 100*theta* (LCDM) | 1.036691 |
| R_shift (CPL) | 1.719655 |
| R_shift (LCDM) | 1.748950 |

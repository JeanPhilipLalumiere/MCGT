# Conclusion Technique — Validation Externe TIDE v3.3

Cette archive conserve la campagne de validation expérimentale TIDE v3.3 avec relaxation dynamique dependante de la densite (`tau(z)`).

## Resultat MCMC global (SN + BAO + CMB prior)

- Convergence vers une solution proche LambdaCDM.
- Meilleur ajustement: `H0 ~= 68.28 km/s/Mpc`.
- Selection de modele: `DeltaBIC ~= +7.13` (penalisation de TIDE v3.3 face a LambdaCDM sur ce vecteur de donnees).

## Interpretation

Le schema `tau` dynamique permet au modele de survivre aux contraintes CMB (decouplage haute densite valide), mais ne reproduit pas la solution a `H0` eleve necessaire pour resoudre la tension de Hubble.

Dans ce benchmark, la metrique `PsiTMG` conserve un avantage phenomenologique sur TIDE v3.3.

## Statut d'integrite

Ce contenu est archive en coffre-fort documentaire et n'altere ni le coeur `PsiTMG`, ni les artefacts de la release `v4.0.0-GOLD.1`.

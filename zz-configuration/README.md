\# Configuration globale — MCGT



Ce répertoire contient les fichiers de configuration partagés entre chapitres.



\## Fichiers clés



\- `mcgt-global-config.ini` : \*\*copie\*\* de `mcgt-global-config.ini.template` adaptée

&nbsp; à votre environnement (chemins locaux, options strictes, etc.).

\- `camb\_exact\_plateau.ini` : options CAMB pour le chapitre CMB.

\- `gw\_phase.ini` : paramètres par défaut pour l’analyse de phase GW.

\- `scalar\_perturbations.ini` : grilles et options du solveur de perturbations.

\- `GWTC-3-confident-events.json` : catalogue des événements de référence.

\- `pdot\_plateau\_vs\_z.dat` : donnée auxiliaire utilisée dans les scripts CMB.



\## Bonnes pratiques



\- Garder des \*\*chemins relatifs\*\* (stabilité des manifests).

\- Éviter d’ajouter des secrets ici. Si nécessaire, introduire des variables d’environnement

&nbsp; et un fichier `\*.template` (comme celui fourni) à la place.

\- Documenter toute variable non triviale directement dans le `.ini` avec un commentaire.




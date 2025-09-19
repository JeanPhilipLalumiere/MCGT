\# Schémas \& Validation — MCGT



Ce dossier regroupe les \*\*schémas JSON\*\* et les \*\*outils de validation\*\* pour

les fichiers de résultats, manifests et métadonnées.



\## Où sont les schémas ?



\- Schémas \*.schema.json (ex. `mc\_config\_schema.json`, `mc\_results\_table\_schema.json`, etc.)

\- Exemples : `results\_schema\_examples.json`



\## Valider rapidement



\### Tous les JSON du projet

```bash

python zz-schemas/validate\_json.py --all




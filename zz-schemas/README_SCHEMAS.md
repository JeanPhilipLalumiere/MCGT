Purpose : Ce document décrit l’ensemble des schémas, les validateurs et les règles de validation globales qui assurent la cohérence de bout en bout sur les dix chapitres MCGT. Il explique quels fichiers existent dans zz-schemas/, comment les utiliser, ce qu’ils valident et comment ils s’intègrent aux tâches QA du Makefile.



Directory : Sauf mention contraire, tous les fichiers cités se trouvent dans zz-schemas/.



A. CONTENU

1\) Schémas JSON (agnostiques au chapitre)

• mc\_config\_schema.json — valide les fichiers de configuration Monte-Carlo tels que zz-data/chapter10/10\_mc\_config.json.

• mc\_best\_schema.json — valide les fichiers de sélection Monte-Carlo top-k tels que zz-data/chapter10/10\_mc\_best.json et \*\_best\_bootstrap.json.

• metrics\_phase\_schema.json — valide zz-data/chapter09/09\_metrics\_phase.json.

• mc\_results\_table\_schema.json — valide la structure des colonnes CSV pour zz-data/chapter10/10\_mc\_results.csv et 10\_mc\_results.circ.csv (via validate\_csv\_table.py).

• comparison\_milestones\_table\_schema.json — valide la structure CSV pour zz-data/chapter09/09\_comparison\_milestones.csv.



2\) Schémas JSON (spécifiques à un chapitre, noms de fichiers en anglais)

• chapter02\_optimal\_parameters.schema.json — valide zz-data/chapter02/02\_parametres\_optimaux.json (“optimal parameters”).

• chapter02\_primordial\_spectrum.schema.json — valide zz-data/chapter02/02\_spec\_spectre.json (loi spectrale, constantes, coefficients).

• chapter03\_stability\_meta.schema.json — valide zz-data/chapter03/03\_meta\_stabilite\_fR.json.

• chapter05\_nucleosynthesis\_parameters.schema.json — valide zz-data/chapter05/05\_parametres\_nucleosynthese.json.

• chapter06\_cmb\_params.schema.json — valide zz-data/chapter06/06\_params\_cmb.json.

• chapter07\_perturbations\_params.schema.json — valide zz-data/chapter07/07\_params\_perturbations.json.

• chapter07\_perturbations\_meta.schema.json — valide zz-data/chapter07/07\_meta\_perturbations.json.

• chapter08\_coupling\_params.schema.json — valide zz-data/chapter08/08\_params\_couplage.json.

• (optionnel) chapter09\_best\_params.schema.json — valide zz-data/chapter09/09\_best\_params.json si produit par la chaîne d’optimisation.

• chapter09\_phases\_imrphenom.meta.schema.json — valide zz-data/chapter09/09\_phases\_imrphenom.meta.json.



3\) Règles globales et validateurs

• validation\_globals.json — constantes canoniques trans-chapitres, seuils, réglages de dérivées, fenêtres de métriques, alias de chemins (zz-donnees→zz-data, chapitre→chapter), normalisation des étiquettes de classes (primaire/ordre2→primary/order2) et localisations d’instances utilisées par les diagnostics.

• validate\_json.py — CLI pour valider un fichier JSON contre un JSON Schema.

• validate\_csv\_table.py — CLI pour valider l’en-tête et les valeurs d’un CSV contre un schéma de type csv-table (définitions de colonnes + contraintes).

• (hors de ce dossier) diag\_consistency.py — utilise zz-schemas/validation\_globals.json pour exécuter des contrôles transverses (valeurs canoniques, plages, fenêtres, classes, identifiants) et produire un rapport structuré.



B. FICHIERS DE DONNÉES CIBLES (EXEMPLES)

• zz-data/chapter10/10\_mc\_config.json → mc\_config\_schema.json

• zz-data/chapter10/10\_mc\_best.json → mc\_best\_schema.json

• zz-data/chapter10/10\_mc\_results.csv, 10\_mc\_results.circ.csv → mc\_results\_table\_schema.json (via validate\_csv\_table.py)

• zz-data/chapter09/09\_metrics\_phase.json → metrics\_phase\_schema.json

• zz-data/chapter09/09\_comparison\_milestones.csv → comparison\_milestones\_table\_schema.json (via validate\_csv\_table.py)

• zz-data/chapter02/02\_parametres\_optimaux.json → chapter02\_optimal\_parameters.schema.json

• zz-data/chapter02/02\_spec\_spectre.json → chapter02\_primordial\_spectrum.schema.json

• zz-data/chapter03/03\_meta\_stabilite\_fR.json → chapter03\_stability\_meta.schema.json

• zz-data/chapter05/05\_parametres\_nucleosynthese.json → chapter05\_nucleosynthesis\_parameters.schema.json

• zz-data/chapter06/06\_params\_cmb.json → chapter06\_cmb\_params.schema.json

• zz-data/chapter07/07\_params\_perturbations.json → chapter07\_perturbations\_params.schema.json

• zz-data/chapter07/07\_meta\_perturbations.json → chapter07\_perturbations\_meta.schema.json

• zz-data/chapter08/08\_params\_couplage.json → chapter08\_coupling\_params.schema.json

• zz-data/chapter09/09\_best\_params.json (si présent) → chapter09\_best\_params.schema.json

• zz-data/chapter09/09\_phases\_imrphenom.meta.json → chapter09\_phases\_imrphenom.meta.schema.json



C. COMMENT VALIDER

À lancer depuis la racine du projet (MCGT/). Utilisez votre venv Python.



1\) Valider des fichiers JSON

python zz-schemas/validate\_json.py zz-schemas/mc\_config\_schema.json zz-data/chapter10/10\_mc\_config.json

python zz-schemas/validate\_json.py zz-schemas/mc\_best\_schema.json zz-data/chapter10/10\_mc\_best.json

python zz-schemas/validate\_json.py zz-schemas/metrics\_phase\_schema.json zz-data/chapter09/09\_metrics\_phase.json

python zz-schemas/validate\_json.py zz-schemas/chapter06\_cmb\_params.schema.json zz-data/chapter06/06\_params\_cmb.json

(répéter pour les autres schémas de chapitre)



2\) Valider des fichiers CSV

python zz-schemas/validate\_csv\_table.py zz-schemas/mc\_results\_table\_schema.json zz-data/chapter10/10\_mc\_results.csv

python zz-schemas/validate\_csv\_table.py zz-schemas/mc\_results\_table\_schema.json zz-data/chapter10/10\_mc\_results.circ.csv

python zz-schemas/validate\_csv\_table.py zz-schemas/comparison\_milestones\_table\_schema.json zz-data/chapter09/09\_comparison\_milestones.csv



3\) Lancer les diagnostics de cohérence

python diag\_consistency.py --rules zz-schemas/validation\_globals.json --out-json zz-manifests/diag\_consistency\_report.json

Ajouter --strict pour traiter les avertissements comme des échecs.



D. CONTRATS DE COLONNES CSV (RÉFÉRENCE)

mc\_results\_table\_schema.json attend a minima :

id,m1,m2,q0star,alpha,phi0,tc,dist,incl,k,mean\_20\_300,p95\_20\_300,max\_20\_300,n\_20\_300,status,error\_code,wall\_time\_s,model,score

Notes : les champs numériques doivent être parsés comme nombres ; status est un court jeton (ex. « ok ») ; error\_code peut être vide ; model est un court jeton ; score reflète p95\_20\_300 dans la chaîne actuelle.



comparison\_milestones\_table\_schema.json attend a minima :

event,f\_Hz,phi\_ref\_at\_fpeak,phi\_mcgt\_at\_fpeak,phi\_mcgt\_at\_fpeak\_raw,phi\_mcgt\_at\_fpeak\_cal,obs\_phase,sigma\_phase,epsilon\_rel,classe,variant

Notes : event doit correspondre aux identifiants style GWTC ; f\_Hz en Hz ; phases en radians ; sigma\_phase ≥ 0 ; classe normalisée vers primary/order2.



E. POLITIQUE DE NOMMAGE ET DE CHEMINS

• Les fichiers de schéma portent des noms en anglais sous zz-schemas/ ; les dossiers de données par chapitre utilisent l’anglais (« chapterXX »). validation\_globals.json fournit des alias afin que les arborescences historiques en français (zz-donnees/chapitreX) soient également valides.

• Les numéros de préfixe par chapitre sont autorisés et recommandés dans les fichiers de données (ex. 06\_params\_cmb.json) ; les fichiers de schéma utilisent des noms explicites en anglais (ex. chapter06\_cmb\_params.schema.json).



F. VERSIONNEMENT ET COMPATIBILITÉ

• Les schémas ciblent JSON Schema 2020-12 ; suffisamment stricts pour la QA tout en autorisant des champs optionnels lorsque pertinent.

• Maintenir validation\_globals.json aligné avec les constantes canoniques (H0, As0, ns0), les seuils (primary, order2), les paramètres de dérivation et les fenêtres de métriques. Les changements doivent commencer là, puis relancer la validation.



G. INTÉGRATION AU MAKEFILE (RÉSUMÉ)

• make jsoncheck : exécute validate\_json.py sur les instances JSON connues.

• make csvcheck : exécute validate\_csv\_table.py sur les tables CSV.

• make consistency : exécute diag\_consistency.py et écrit zz-manifests/diag\_consistency\_report.json.

• make qa : jsoncheck + csvcheck + consistency.

• make ci : affichage environnement + qa.

• make clean-schemas : supprime les journaux et caches de validation générés.



H. DÉPANNAGE

• JSONDecodeError : fichier vide ou mal formé ; ré-exporter le script producteur ou corriger les virgules finales.

• FileNotFoundError : vérifier le chemin ; standard sur zz-data/chapterXX avec alias autorisés. Lancer depuis la racine du projet.

• Échec de validation CSV : s’assurer que les noms d’en-tête correspondent exactement ; enregistrer en UTF-8 (sans BOM).

• Erreurs de cohérence (H0, As0, ns0) : soit l’écart est intentionnel (mettre à jour les plages dans validation\_globals.json avec justification), soit aligner les entrées du chapitre.

• Identifiant d’événement ou classe non conforme : corriger les libellés dans votre CSV ; les identifiants invalides doivent être corrigés à la source.



I. LISTE MINIMALE AVANT RELECTURE DU CHAPITRE

• Toutes les instances JSON passent validate\_json.py contre leurs schémas.

• Toutes les tables CSV passent validate\_csv\_table.py contre leurs schémas.

• diag\_consistency.py ne rapporte aucune erreur (ERROR) ; seulement des avertissements (WARN) justifiés ; utiliser --strict pour échouer sur WARN en CI.

• La cible Makefile « qa » s’exécute sans erreurs.



J. CONTACT ET JOURNAL DES MODIFICATIONS

• Producteur : projet MCGT (suite de schémas préparée pour la validation trans-chapitres).

• Politique de mise à jour : incrémenter « schema\_version » dans validation\_globals.json lors de changements de règles canoniques ; en cas de modification de structure d’une instance JSON, incrémenter le « $id » du schéma correspondant et consigner le changement dans zz-manifests/manifest\_report.md.

End of README\_SCHEMAS.md




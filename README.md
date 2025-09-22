# Modèle de Courbure Gravitationnelle Temporelle (MCGT)

## Résumé

MCGT est un corpus de 10 chapitres (conceptuel + détails) accompagné d’un ensemble de scripts, données, figures et manifestes pour assurer la reproductibilité complète (génération des données, tracés, contrôles de cohérence). Ce README dresse l’index des ressources, précise les points d’entrée (runbook, Makefile, configs) et documente les conventions.

## Sommaire

1. Arborescence du projet
2. Contenu des chapitres (LaTeX)
3. Configurations & package Python
4. Données (zz-data/)
5. Scripts (zz-scripts/)
6. Figures (zz-figures/)
7. Manifests & repro (zz-manifests/, README-REPRO.md, RUNBOOK.md)
8. Conventions & styles (conventions.md)
9. Environnements & dépendances (requirements.txt, environment.yml)
10. Commandes utiles (Makefile) & contrôle de cohérence
11. Licence / Contact
12. Historique / Notes

---

## 1) Arborescence du projet

Racine :

* main.tex — Document LaTeX principal (compile les 10 chapitres).
* references.bib — Bibliographie BibTeX.
* README.md — Présent fichier d’accueil.
* README-REPRO.md — Guide de reproductibilité pas-à-pas.
* RUNBOOK.md — Procédures opératoires (exécution standard / QA).
* Makefile — Cibles de génération (données, figures, PDF, QA).
* setup.py — (si packaging local du module mcgt).
* requirements.txt — Dépendances Python (pip).
* environment.yml — Environnement Conda (optionnel).
* conventions.md — Convention de nommage / unités / style (référence).
* LICENSE — Licence du projet.
* .pre-commit-config.yaml — Hooks de qualité (format/linters).

  Chapitres (dossiers LaTeX) :
* 01-introduction-applications/
* 02-validation-chronologique/
* 03-stabilite-fR/
* 04-invariants-adimensionnels/
* 05-nucleosynthese-primordiale/
* 06-rayonnement-cmb/
* 07-perturbations-scalaires/
* 08-couplage-sombre/
* 09-phase-ondes-gravitationnelles/
* 10-monte-carlo-global-8d/

  Code source (package) :
* mcgt/ — Module Python (API interne).

  * scalar\_perturbations.py
  * phase.py
  * **init**.py
  * backends/ref\_phase.py
  * CHANGELOG.md
  * pyproject.toml

  Configurations :
* zz-configuration/

  * mcgt-global-config.ini — Configuration globale (référence).
  * mcgt-global-config.ini.template
  * camb\_exact\_plateau.ini
  * gw\_phase.ini
  * scalar\_perturbations.ini
  * GWTC-3-confident-events.json
  * pdot\_plateau\_vs\_z.dat
  * meta\_template.json — (référence croisée avec zz-manifests/)
  * README.md

  Données :
* zz-data/chapter{01..10}/ — Données structurées par chapitre (CSV/DAT/JSON).

  Figures :
* zz-figures/chapter{01..10}/ — Figures générées (PNG).

  Scripts & outils :
* zz-scripts/chapter{01..10}/ — Scripts de génération & tracé.
* zz-scripts/chapter03/utils/ — Utilitaires (ex. conversion jalons).
* zz-scripts/chapter07/tests/ — Tests dédiés chapitre 7.
* zz-scripts/chapter07/utils/ — Utilitaires (k-grid, toy\_model).
* zz-scripts/chapter08/utils/ — Utilitaires (extractions BAO/SN).
* zz-scripts/manifest\_tools/ — Outils manifeste.

  * populate\_manifest.py, verify\_manifest.py

  Manifests & diagnostics :
* zz-manifests/

  * manifest\_master.json
  * manifest\_publication.json (et éventuellement .bak)
  * manifest\_report.json
  * manifest\_report.md
  * figure\_manifest.csv
  * add\_to\_manifest.py
  * migration\_map.json
  * meta\_template.json
  * README\_manifest.md
  * diag\_consistency.py
  * chapters/

    * chapter\_manifest\_01.json
    * chapter\_manifest\_02.json
    * chapter\_manifest\_03.json
    * chapter\_manifest\_04.json
    * chapter\_manifest\_05.json
    * chapter\_manifest\_06.json
    * chapter\_manifest\_07.json
    * chapter\_manifest\_08.json
    * chapter\_manifest\_09.json
    * chapter\_manifest\_10.json
  * reports/

  Schémas :
* zz-schemas/

  * 02\_optimal\_parameters.schema.json
  * 02\_spec\_spectrum.schema.json
  * 03\_meta\_stability\_fR.schema.json
  * 05\_nucleosynthesis\_parameters.schema.json
  * 06\_cmb\_params.schema.json
  * 07\_meta\_perturbations.schema.json
  * 07\_params\_perturbations.schema.json
  * 09\_best\_params.schema.json
  * 09\_phases\_imrphenom.meta.schema.json
  * comparison\_milestones\_table\_schema.json
  * jalons\_comparaison\_table\_schema.json
  * mc\_best\_schema.json
  * mc\_config\_schema.json
  * mc\_results\_table\_schema.json
  * meta\_schema.json
  * metrics\_phase\_schema.json
  * README.md
  * README\_SCHEMAS.md
  * results\_schema\_examples.json
  * validate\_csv\_schema.py
  * validate\_csv\_table.py
  * validate\_json.py
  * validation\_globals.json

  Checklists :
* zz-checklists/

  * CHAPTER01\_CHECKLIST.txt
  * CHAPTER02\_CHECKLIST.txt
  * CHAPTER03\_CHECKLIST.txt
  * CHAPTER04\_CHECKLIST.txt
  * CHAPTER05\_CHECKLIST.txt
  * CHAPTER06\_CHECKLIST.txt
  * CHAPTER07\_CHECKLIST.txt
  * CHAPTER08\_CHECKLIST.txt
  * CHAPTER09\_CHECKLIST.txt
  * CHAPTER10\_CHECKLIST.txt

  Tests :
* zz-tests/

  * pytest.ini
  * test\_manifest.py
  * test\_schemas.py

  Workflows CI :
* zz-workflows/

  * ci.yml
  * release.yml
  * README.md

---

## 2) Contenu des chapitres (LaTeX)

Chaque dossier de chapitre contient :

* <prefix>\_conceptuel.tex
* <prefix>\_details.tex (ou \_calibration\_conceptuel.tex pour le chap. 1)
* CHAPTERXX\_GUIDE.txt (notes, exigences, jalons spécifiques)

Liste :

* Chapitre 1 – Introduction conceptuelle (01-introduction-applications/)

  * 01\_introduction\_conceptuel.tex
  * 01\_applications\_calibration\_conceptuel.tex
  * CHAPTER01\_GUIDE.txt
* Chapitre 2 – Validation chronologique (02-validation-chronologique/)

  * 02\_validation\_chronologique\_conceptuel.tex
  * 02\_validation\_chronologique\_details.tex
  * CHAPTER02\_GUIDE.txt
* Chapitre 3 – Stabilité f(R) (03-stabilite-fR/)

  * 03\_stabilite\_fR\_conceptuel.tex
  * 03\_stabilite\_fR\_details.tex
  * CHAPTER03\_GUIDE.txt
* Chapitre 4 – Invariants adimensionnels (04-invariants-adimensionnels/)

  * 04\_invariants\_adimensionnels\_conceptuel.tex
  * 04\_invariants\_adimensionnels\_details.tex
  * CHAPTER04\_GUIDE.txt
* Chapitre 5 – Nucléosynthèse primordiale (05-nucleosynthese-primordiale/)

  * 05\_nucleosynthese\_primordiale\_conceptuel.tex
  * 05\_nucleosynthese\_primordiale\_details.tex
  * CHAPTER05\_GUIDE.txt
* Chapitre 6 – Rayonnement CMB (06-rayonnement-cmb/)

  * 06\_cmb\_conceptuel.tex
  * 06\_cmb\_details.tex
  * CHAPTER06\_GUIDE.txt
* Chapitre 7 – Perturbations scalaires (07-perturbations-scalaires/)

  * 07\_perturbations\_scalaires\_conceptuel.tex
  * 07\_perturbations\_scalaires\_details.tex
  * CHAPTER07\_GUIDE.txt
* Chapitre 8 – Couplage sombre (08-couplage-sombre/)

  * 08\_couplage\_sombre\_conceptuel.tex
  * 08\_couplage\_sombre\_details.tex
  * CHAPTER08\_GUIDE.txt
* Chapitre 9 – Phase ondes gravitationnelles (09-phase-ondes-gravitationnelles/)

  * 09\_phase\_ondes\_grav\_conceptuel.tex
  * 09\_phase\_ondes\_grav\_details.tex
  * CHAPTER09\_GUIDE.txt
* Chapitre 10 – Monte Carlo global 8D (10-monte-carlo-global-8d/)

  * 10\_monte\_carlo\_global\_conceptuel.tex
  * 10\_monte\_carlo\_global\_details.tex
  * CHAPTER10\_GUIDE.txt

---

## 3) Configurations & package Python

* zz-configuration/mcgt-global-config.ini : paramètres transverses (chemins de données/figures, tolérances, seeds, options graphiques, etc.).
* zz-configuration/\*.ini spécifiques (ex. camb\_exact\_plateau.ini, scalar\_perturbations.ini, gw\_phase.ini).
* zz-configuration/GWTC-3-confident-events.json ; zz-configuration/pdot\_plateau\_vs\_z.dat ; zz-configuration/meta\_template.json ; zz-configuration/mcgt-global-config.ini.template ; zz-configuration/README.md.
* mcgt/ : API Python interne (ex. calculs de phase, solveurs de perturbations, backends de référence). mcgt/backends/ref\_phase.py fournit la phase de ref.
* mcgt/CHANGELOG.md ; mcgt/pyproject.toml.

---

## 4) Données (zz-data/)

Organisation par chapitre, exemples (liste non exhaustive) :

* zz-data/chapter01/

  * 01\_optimized\_data.csv
  * 01\_optimized\_data\_and\_derivatives.csv
  * 01\_optimized\_grid\_data.dat
  * 01\_P\_vs\_T.dat
  * 01\_initial\_grid\_data.dat
  * 01\_P\_derivative\_initial.csv
  * 01\_P\_derivative\_optimized.csv
  * 01\_relative\_error\_timeline.csv
  * 01\_timeline\_milestones.csv
  * 01\_dimensionless\_invariants.csv
* zz-data/chapter02/

  * 02\_optimal\_parameters.json, 02\_primordial\_spectrum\_spec.json
  * 02\_P\_vs\_T\_grid\_data.dat, 02\_P\_derivative\_data.dat
  * 02\_As\_ns\_vs\_alpha.csv, 02\_P\_R\_sampling.csv
  * 02\_FG\_series.csv
  * 02\_timeline\_milestones.csv, 02\_relative\_error\_timeline.csv, 02\_milestones\_meta.csv
* zz-data/chapter03/

  * 03\_fR\_stability\_meta.json
  * 03\_fR\_stability\_data.csv, 03\_fR\_stability\_domain.csv, 03\_fR\_stability\_boundary.csv
  * 03\_ricci\_fR\_vs\_T.csv, 03\_ricci\_fR\_vs\_z.csv, 03\_ricci\_fR\_milestones.csv
* zz-data/chapter04/

  * 04\_dimensionless\_invariants.csv
  * 04\_P\_vs\_T.dat
* zz-data/chapter05/

  * 05\_bbn\_params.json, 05\_bbn\_grid.csv
  * 05\_bbn\_data.csv, 05\_bbn\_invariants.csv
  * 05\_chi2\_bbn\_vs\_T.csv, 05\_dchi2\_vs\_T.csv
  * 05\_bbn\_milestones.csv
* zz-data/chapter06/

  * 06\_params\_cmb.json
  * 06\_alpha\_evolution.csv
  * 06\_cls\_spectrum.dat, 06\_cls\_spectrum\_lcdm.dat
  * 06\_cmb\_full\_results.csv, 06\_cmb\_chi2\_scan2D.csv
  * 06\_delta\_cls.csv, 06\_delta\_cls\_relative.csv
  * 06\_delta\_rs\_scan.csv, 06\_delta\_rs\_scan2D.csv, 06\_delta\_rs\_scan\_full.csv
  * 06\_delta\_Tm\_scan.csv, 06\_hubble\_mcgt.dat
  * 01\_P\_vs\_T.dat
* zz-data/chapter07/

  * 07\_perturbations\_params.json, 07\_perturbations\_meta.json
  * 07\_cs2\_matrix.csv, 07\_delta\_phi\_matrix.csv
  * 07\_dcs2\_vs\_k.csv, 07\_ddelta\_phi\_vs\_k.csv
  * 07\_perturbations\_domain.csv, 07\_perturbations\_boundary.csv
  * 07\_scalar\_invariants.csv, 07\_phase\_run.csv
  * 07\_perturbations\_main\_data.csv, 07\_scalar\_perturbations\_results.csv
* zz-data/chapter08/

  * 08\_coupling\_params.json, 08\_chi2\_scan2D.csv, 08\_chi2\_total\_vs\_q0.csv
  * 08\_bao\_data.csv, 08\_pantheon\_data.csv
  * 08\_dv\_theory\_z.csv, 08\_dv\_theory\_q0star.csv
  * 08\_mu\_theory\_z.csv, 08\_mu\_theory\_q0star.csv
  * 08\_coupling\_milestones.csv, 08\_chi2\_derivative.csv
* zz-data/chapter09/

  * 09\_best\_params.json
  * 09\_metrics\_phase.json, 09\_comparison\_milestones.csv (+ .meta.json, .flagged.csv)
  * 09\_phases\_imrphenom.csv (+ .meta.json)
  * 09\_phases\_mcgt.csv, 09\_phases\_mcgt\_prepoly.csv
  * 09\_phase\_diff.csv, gwtc3\_confident\_parameters.json
* zz-data/chapter10/

  * 10\_mc\_config.json
  * 10\_mc\_results.csv (+ variantes .circ.csv, .agg.csv, .circ.with\_fpeak.csv)
  * 10\_mc\_samples.csv, 10\_mc\_milestones\_eval.csv
  * 10\_mc\_best.json, 10\_mc\_best\_bootstrap.json

---

## 5) Scripts (zz-scripts/)

Chaque chapitre dispose de générateurs de données generate\_data\_chapterXX.py et de traceurs plot\_fig\*.py. Exemples :

* zz-scripts/chapter01/

  * generate\_data\_chapter01.py, plot\_fig01\_early\_plateau.py, plot\_fig02\_logistic\_calibration.py, plot\_fig03\_relative\_error\_timeline.py, plot\_fig04\_P\_vs\_T\_evolution.py, plot\_fig05\_I1\_vs\_T.py, plot\_fig06\_P\_derivative\_comparison.py, requirements.txt
* zz-scripts/chapter02/

  * extract\_sympy\_FG.ipynb
  * generate\_data\_chapter02.py, primordial\_spectrum.py, plot\_fig00\_spectrum.py, plot\_fig01\_P\_vs\_T\_evolution.py, plot\_fig02\_calibration.py, plot\_fig03\_relative\_errors.py, plot\_fig04\_pipeline\_diagram.py, plot\_fig05\_FG\_series.py, plot\_fig06\_alpha\_fit.py, requirements.txt
* zz-scripts/chapter03/

  * generate\_data\_chapter03.py, plot\_fig01\_fR\_stability\_domain.py, plot\_fig02\_fR\_fRR\_vs\_f.py, plot\_fig03\_ms2\_R0\_vs\_f.py, plot\_fig04\_fR\_fRR\_vs\_f.py, plot\_fig05\_interpolated\_milestones.py, plot\_fig06\_grid\_quality.py, plot\_fig07\_ricci\_fR\_vs\_z.py, plot\_fig08\_ricci\_fR\_vs\_T.py, requirements.txt
  * utils/03\_ricci\_fR\_milestones\_enhanced.csv, utils/convert\_milestones.py
* zz-scripts/chapter04/

  * generate\_data\_chapter04.py, plot\_fig01\_invariants\_schematic.py, plot\_fig02\_invariants\_histogram.py, plot\_fig03\_invariants\_vs\_T.py, plot\_fig04\_relative\_deviations.py, requirements.txt
* zz-scripts/chapter05/

  * generate\_data\_chapter05.py, plot\_fig01\_bbn\_reaction\_network.py, plot\_fig02\_dh\_model\_vs\_obs.py, plot\_fig03\_yp\_model\_vs\_obs.py, plot\_fig04\_chi2\_vs\_T.py, requirements.txt
* zz-scripts/chapter06/

  * generate\_data\_chapter06.py, generate\_pdot\_plateau\_vs\_z.py, plot\_fig01\_cmb\_dataflow\_diagram.py, plot\_fig02\_cls\_lcdm\_vs\_mcgt.py, plot\_fig03\_delta\_cls\_relative.py, plot\_fig04\_delta\_rs\_vs\_params.py, plot\_fig05\_delta\_chi2\_heatmap.py, run\_camb\_chapter06.bat, requirements.txt
* zz-scripts/chapter07/

  * generate\_data\_chapter07.py, launch\_scalar\_perturbations\_solver.py, launch\_solver\_chapter07.sh, plot\_fig01\_cs2\_heatmap.py, plot\_fig02\_delta\_phi\_heatmap.py, plot\_fig06\_comparison.py, plot\_fig03\_invariant\_I1.py, plot\_fig04\_dcs2\_vs\_k.py, plot\_fig05\_ddelta\_phi\_vs\_k.py, plot\_fig07\_invariant\_I2.py, requirements.txt
  * tests/test\_chapter07.py
  * utils/test\_kgrid.py, utils/toy\_model.py
* zz-scripts/chapter08/

  * generate\_coupling\_milestones.py, generate\_data\_chapter08.py, plot\_fig01\_chi2\_total\_vs\_q0.py, plot\_fig02\_dv\_vs\_z.py, plot\_fig03\_mu\_vs\_z.py, plot\_fig04\_chi2\_heatmap.py, plot\_fig05\_residuals.py, plot\_fig06\_normalized\_residuals\_distribution.py, plot\_fig07\_chi2\_profile.py, requirements.txt
  * utils/cosmo.py, utils/coupling\_example\_model.py, utils/extract\_bao\_data.py, utils/extract\_pantheon\_plus\_data.py, utils/generate\_coupling\_milestones.py, utils/verify\_z\_grid.py
* zz-scripts/chapter09/

  * apply\_poly\_unwrap\_rebranch.py, check\_p95\_methods.py, extract\_phenom\_phase.py, fetch\_gwtc3\_confident.py, flag\_jalons.py, generate\_data\_chapter09.py, generate\_mcgt\_raw\_phase.py, opt\_poly\_rebranch.py
  * plot\_fig01\_phase\_overlay.py, plot\_fig02\_residual\_phase.py, plot\_fig03\_hist\_absdphi\_20\_300.py, plot\_fig04\_absdphi\_milestones\_vs\_f.py, plot\_fig05\_scatter\_phi\_at\_fpeak.py, requirements.txt
* zz-scripts/chapter10/

  * add\_phi\_at\_fpeak.py, bootstrap\_topk\_p95.py, check\_metrics\_consistency.py, diag\_phi\_fpeak.py, eval\_primary\_metrics\_20\_300.py, generate\_data\_chapter10.py, inspect\_topk\_residuals.py, qc\_wrapped\_vs\_unwrapped.py, recompute\_p95\_circular.py, regen\_fig05\_using\_circp95.py
  * plot\_fig01\_iso\_p95\_maps.py, plot\_fig02\_scatter\_phi\_at\_fpeak.py, plot\_fig03\_convergence\_p95\_vs\_n.py, plot\_fig03b\_bootstrap\_coverage\_vs\_n.py, plot\_fig04\_scatter\_p95\_recalc\_vs\_orig.py, plot\_fig05\_hist\_cdf\_metrics.py, plot\_fig06\_residual\_map.py, plot\_fig07\_synthesis.py
  * update\_manifest\_with\_hashes.py, requirements.txt
* zz-scripts/manifest\_tools/

  * populate\_manifest.py, verify\_manifest.py

---

## 6) Figures (zz-figures/)

Par chapitre : fig\_\*.png (noms explicites, FR).

* chap.01 :

  * fig\_01\_early\_plateau.png, fig\_02\_logistic\_calibration.png, fig\_03\_relative\_error\_timeline.png, fig\_04\_P\_vs\_T\_evolution.png, fig\_05\_I1\_vs\_T.png, fig\_06\_P\_derivative\_comparison.png
* chap.02 :

  * fig\_00\_spectrum.png, fig\_01\_P\_vs\_T\_evolution.png, fig\_02\_calibration.png, fig\_03\_relative\_errors.png, fig\_04\_pipeline\_diagram.png, fig\_05\_FG\_series.png, fig\_06\_fit\_alpha.png
* chap.03 :

  * fig\_01\_fR\_stability\_domain.png, fig\_02\_fR\_fRR\_vs\_R.png, fig\_03\_ms2\_R0\_vs\_R.png, fig\_04\_fR\_fRR\_vs\_R.png, fig\_05\_interpolated\_milestones.png, fig\_06\_grid\_quality.png, fig\_07\_ricci\_fR\_vs\_z.png, fig\_08\_ricci\_fR\_vs\_T.png
* chap.04 :

  * fig\_01\_invariants\_schematic.png, fig\_02\_invariants\_histogram.png, fig\_03\_invariants\_vs\_T.png, fig\_04\_relative\_deviations.png
* chap.05 :

  * fig\_01\_bbn\_reaction\_network.png, fig\_02\_dh\_model\_vs\_obs.png, fig\_03\_yp\_model\_vs\_obs.png, fig\_04\_chi2\_vs\_T.png
* chap.06 :

  * fig\_01\_cmb\_dataflow\_diagram.png, fig\_02\_cls\_lcdm\_vs\_mcgt.png, fig\_03\_delta\_cls\_relative.png, fig\_04\_delta\_rs\_vs\_params.png, fig\_05\_delta\_chi2\_heatmap.png
* chap.07 :

  * fig\_00\_loglog\_sampling\_test.png, fig\_01\_cs2\_heatmap\_k\_a.png, fig\_02\_delta\_phi\_heatmap\_k\_a.png, fig\_03\_invariant\_I1.png, fig\_04\_dcs2\_dk\_vs\_k.png, fig\_05\_ddelta\_phi\_dk\_vs\_k.png, fig\_06\_comparison.png, fig\_07\_invariant\_I2.png
* chap.08 :

  * fig\_01\_chi2\_total\_vs\_q0.png, fig\_02\_dv\_vs\_z.png, fig\_03\_mu\_vs\_z.png, fig\_04\_chi2\_heatmap.png, fig\_05\_residuals.png, fig\_06\_pulls.png, fig\_07\_chi2\_profile.png
* chap.09 :

  * fig\_01\_phase\_overlay.png, fig\_02\_residual\_phase.png, fig\_03\_hist\_absdphi\_20\_300.png, fig\_04\_absdphi\_milestones\_vs\_f.png, fig\_05\_scatter\_phi\_at\_fpeak.png, p95\_methods/ (fig03\_raw\_bins30.png, fig03\_raw\_bins50.png, fig03\_raw\_bins80.png, fig03\_rebranch\_k\_bins30.png, fig03\_rebranch\_k\_bins50.png, fig03\_rebranch\_k\_bins80.png, fig03\_unwrap\_bins30.png, fig03\_unwrap\_bins50.png, fig03\_unwrap\_bins80.png), p95\_check\_control.png
* chap.10 :

  * fig\_01\_iso\_p95\_maps.png, fig\_02\_scatter\_phi\_at\_fpeak.png, fig\_03b\_coverage\_bootstrap\_vs\_n\_hires.png, fig\_03\_convergence\_p95\_vs\_n.png, fig\_04\_scatter\_p95\_recalc\_vs\_orig.png, fig\_05\_hist\_cdf\_metrics.png, fig\_06\_heatmap\_absdp95\_m1m2.png, fig\_07\_summary\_comparison.png

---

## 7) Manifests & repro

* zz-manifests/manifest\_master.json — inventaire complet (source maître).
* zz-manifests/manifest\_publication.json — sous-ensemble pour remise publique.
* zz-manifests/manifest\_report.json — rapport généré par diag\_consistency.py.
* zz-manifests/manifest\_report.md — rapport lisible.
* zz-manifests/figure\_manifest.csv — index des figures.
* zz-manifests/add\_to\_manifest.py ; zz-manifests/migration\_map.json.
* zz-manifests/meta\_template.json — gabarit de métadonnées (source maître).
* zz-manifests/README\_manifest.md — documentation manifeste.
* zz-manifests/diag\_consistency.py — diagnostic (présence/format/empreintes).
* zz-manifests/chapters/chapter\_manifest\_{01..10}.json — manifests par chapitre.
* zz-manifests/reports/ — exports/rapports additionnels.
* README-REPRO.md — procédure reproductible détaillée.
* RUNBOOK.md — séquences d’exécution standard (pipeline).

Note : un meta\_template.json existe aussi sous zz-configuration/ (référence croisée). La version maître est celle de zz-manifests/.

---

## 8) Conventions & styles

* conventions.md : normes de nommage (FR), unités (SI), précision numérique, format CSV/DAT/JSON, styles de figures, seuils de QA, sémantique des colonnes, règles pour jalons et classes (primaire/ordre2), etc.
* Cohérence inter-chapitres : les paramètres transverses (p. ex. alpha, q0star, fenêtres de fréquences, ell\_min/max, etc.) doivent être harmonisés via mcgt-global-config.ini et les JSON de paramètres par chapitre.

---

## 9) Environnements & dépendances

* Python ≥ 3.10 recommandé.
  Installation (pip) :
  pip install -r requirements.txt
  Environnement Conda :
  conda env create -f environment.yml
  conda activate mcgt
  Chap. 9/10 : références d’onde (IMRPhenom) indiquées dans les métadonnées ; LALSuite peut être requis côté référence si régénération complète (voir RUNBOOK.md).
* Fichiers requirements par chapitre :

  * zz-scripts/chapter01/requirements.txt
  * zz-scripts/chapter02/requirements.txt
  * zz-scripts/chapter03/requirements.txt
  * zz-scripts/chapter04/requirements.txt
  * zz-scripts/chapter05/requirements.txt
  * zz-scripts/chapter06/requirements.txt
  * zz-scripts/chapter07/requirements.txt
  * zz-scripts/chapter08/requirements.txt
  * zz-scripts/chapter09/requirements.txt
  * zz-scripts/chapter10/requirements.txt

---

## 10) Commandes utiles & QA

Aide :
make help

Générer données d’un chapitre (ex. chap. 4) :
make data-chapter N=4

Générer figures d’un chapitre :
make figures-chapter N=4

Pipeline complet (données + figures) :
make all

Contrôle de cohérence manifest :
python zz-manifests/diag\_consistency.py --manifest zz-manifests/manifest\_master.json --report zz-manifests/manifest\_report.json

Pour des validations supplémentaires :

* JSON : python zz-schemas/validate\_json.py \<schema.json> \<fichier.json>
* CSV (tables) : python zz-schemas/validate\_csv\_table.py \<table\_schema.json> \<fichier.csv>
* Schéma CSV (structure) : python zz-schemas/validate\_csv\_schema.py \<schema.json>
* Globals de validation : zz-schemas/validation\_globals.json

---

## 11) Licence / Contact

* Licence : à préciser (interne / publique) — voir fichier LICENSE.
* Contact scientifique : responsable MCGT.
* Contact technique : mainteneur des scripts / CI.

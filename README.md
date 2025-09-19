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
    Configurations :
* zz-configuration/

  * mcgt-global-config.ini — Configuration globale (référence).
  * camb\_exact\_plateau.ini
  * gw\_phase.ini
  * scalar\_perturbations.ini
  * pdot\_plateau\_vs\_z.dat
  * meta\_template.json — (référence croisée avec zz-manifests/)
    Données :
* zz-data/chapter{01..10}/ — Données structurées par chapitre (CSV/DAT/JSON).
  Figures :
* zz-figures/chapter{01..10}/ — Figures générées (PNG).
  Scripts & outils :
* zz-scripts/chapter{01..10}/ — Scripts de génération & tracé.
* zz-scripts/chapter07/tests/ — Tests dédiés chapitre 7.
* zz-scripts/chapter03/utils/ — Utilitaires (ex. conversion jalons).
* zz-scripts/chapter07/utils/ — Utilitaires (k-grid, toy\_model).
* zz-scripts/chapter08/utils/ — Utilitaires (extractions BAO/SN).
* zz-scripts/manifest\_tools/ — Outils manifeste.

  * populate\_manifest.py, verify\_manifest.py
    Manifests & diagnostics :
* zz-manifests/

  * manifest\_master.json
  * manifest\_publication.json (et éventuellement .bak)
  * manifest\_report.json
  * meta\_template.json
  * README\_manifest.md
  * diag\_consistency.py

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
* mcgt/ : API Python interne (ex. calculs de phase, solveurs de perturbations, backends de référence). mcgt/backends/ref\_phase.py fournit la phase de ref.

---

## 4) Données (zz-data/)

Organisation par chapitre, exemples (liste non exhaustive) :

* zz-data/chapter01/

  * 01\_optimized\_data.csv
  * 01\_optimized\_data\_and\_derivatives.csv
  * 01\_P\_vs\_T.dat
  * 01\_initial\_grid\_data.dat
  * 01\_P\_derivative\_initial.csv
  * 01\_P\_derivative\_optimized.csv
  * 01\_relative\_error\_timeline.csv
  * 01\_timeline\_milestones.csv
* zz-data/chapter02/

  * 02\_optimal\_parameters.json, 02\_primordial\_spectrum\_spec.json
  * 02\_P\_vs\_T\_grid\_data.dat, 02\_P\_derivative\_data.dat
  * 02\_As\_ns\_vs\_alpha.csv, 02\_P\_R\_sampling.csv
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
  * 06\_cls\_spectrum.dat, 06\_cls\_spectrum\_lcdm.dat
  * 06\_cmb\_full\_results.csv, 06\_cmb\_chi2\_scan2D.csv
  * 06\_delta\_cls.csv, 06\_delta\_cls\_relative.csv
  * 06\_delta\_rs\_scan.csv, 06\_delta\_rs\_scan2D.csv, 06\_delta\_rs\_scan\_full.csv
  * 06\_delta\_Tm\_scan.csv, 06\_hubble\_mcgt.dat
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

  * generate\_data\_chapter07.py, launch\_scalar\_perturbations\_solver.py, launch\_solver\_chapter07.sh, plot\_fig01\_cs2\_heatmap.py, plot\_fig02\_delta\_phi\_heatmap.py, plot\_fig06\_comparison.py, plot\_fig03\_invariant\_I1.py, plot\_fig04\_dcs2\_vs\_k.py, plot\_fig05\_ddelta\_phi\_vs\_k.py, plot\_fig07\_invariant\_I2.py, requirements.txt, tests/, utils/
* zz-scripts/chapter08/

  * generate\_data\_chapter08.py, plot\_fig01\_chi2\_total\_vs\_q0.py, plot\_fig02\_dv\_vs\_z.py, plot\_fig03\_mu\_vs\_z.py, plot\_fig04\_chi2\_heatmap.py, plot\_fig05\_residuals.py, plot\_fig06\_normalized\_residuals\_distribution.py, plot\_fig07\_chi2\_profile.py, requirements.txt, utils/cosmo.py, utils/coupling\_example\_model.py, utils/extract\_bao\_data.py, utils/extract\_pantheon\_plus\_data.py, utils/generate\_coupling\_milestones.py, utils/verify\_z\_grid.py
* zz-scripts/chapter09/

  * generate\_data\_chapter09.py, extract\_phenom\_phase.py, generate\_mcgt\_raw\_phase.py, opt\_poly\_rebranch.py, apply\_poly\_unwrap\_rebranch.py, check\_p95\_methods.py, plot\_fig01\_phase\_overlay.py, plot\_fig02\_residual\_phase.py, plot\_fig03\_hist\_absdphi\_20\_300.py, plot\_fig04\_absdphi\_milestones\_vs\_f.py, plot\_fig05\_scatter\_phi\_at\_fpeak.py, fetch\_gwtc3\_confident.py, flag\_jalons.py, requirements.txt
* zz-scripts/chapter10/

  * generate\_data\_chapter10.py, eval\_primary\_metrics\_20\_300.py, diag\_phi\_fpeak.py, add\_phi\_at\_fpeak.py, inspect\_topk\_residuals.py, bootstrap\_topk\_p95.py, qc\_wrapped\_vs\_unwrapped.py, recompute\_p95\_circular.py, regen\_fig05\_using\_circp95.py, plot\_fig01\_iso\_p95\_maps.py, plot\_fig02\_scatter\_phi\_at\_fpeak.py, plot\_fig03\_convergence\_p95\_vs\_n.py, plot\_fig03b\_bootstrap\_coverage\_vs\_n.py, plot\_fig04\_scatter\_p95\_recalc\_vs\_orig.py, plot\_fig05\_hist\_cdf\_metrics.py, plot\_fig06\_residual\_map.py, plot\_fig07\_synthesis.py, check\_metrics\_consistency.py, update\_manifest\_with\_hashes.py, requirements.txt
* zz-scripts/manifest\_tools/

  * populate\_manifest.py, verify\_manifest.py

---

## 6) Figures (zz-figures/)

Par chapitre : fig\_*.png (noms explicites, FR).
Ex. chap.01 : fig\_01\_early\_plateau.png, fig\_02\_logistic\_calibration.png, fig\_03\_relative\_error\_timeline.png, fig\_04\_P\_vs\_T\_evolution.png, fig\_05\_I1\_vs\_T.png, fig\_06\_P\_derivative\_comparison.png
Ex. chap.06 : fig\_01\_cmb\_dataflow\_diagram.png, fig\_02\_cls\_lcdm\_vs\_mcgt.png, fig\_03\_delta\_cls\_relative.png, fig\_04\_delta\_rs\_vs\_params.png, fig\_05\_delta\_chi2\_heatmap.png
Ex. chap.09 : fig\_01\_phase\_overlay.png, fig\_02\_residual\_phase.png, fig\_03\_hist\_absdphi\_20\_300.png, fig\_04\_absdphi\_milestones\_vs\_f.png, fig\_05\_scatter\_phi\_at\_fpeak.png, p95\_methods/*.png
---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

## 7) Manifests & repro

* zz-manifests/manifest\_master.json — inventaire complet (source maître).
* zz-manifests/manifest\_publication.json — sous-ensemble pour remise publique.
* zz-manifests/manifest\_report.json — rapport généré par diag\_consistency.py.
* zz-manifests/meta\_template.json — gabarit de métadonnées (source maître).
* zz-manifests/README\_manifest.md — documentation manifeste.
* zz-manifests/diag\_consistency.py — diagnostic (présence/format/empreintes).
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

---

## 11) Licence / Contact

* Licence : à préciser (interne / publique).
* Contact scientifique : responsable MCGT.
* Contact technique : mainteneur des scripts / CI.

---

## 12) Historique / Notes

* Harmonisation linguistique FR des noms de fichiers : les chemins et fichiers sont en anglais (conformément à l’arborescence), le texte de la documentation reste en français.
* Les seuils QA (primaire/ordre2) sont documentés par chapitre (JSON/ini).
* Les métriques et fenêtres (ex. \[20,300] Hz pour chap. 9/10) sont consignées dans les JSON de paramètres et rappelées dans le runbook.

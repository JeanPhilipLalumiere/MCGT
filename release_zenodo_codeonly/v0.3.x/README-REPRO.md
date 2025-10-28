MCGT — REPRODUCTIBILITÉ (README-REPRO)

Ce document explique comment (re)générer les données, figures et diagnostics du projet MCGT à partir du dépôt local. Il complète « convention.md », « zz-configuration/mcgt-global-config.ini », les schémas sous « zz-schemas/ », et les manifestes sous « zz-manifests/ ».

1. PRÉREQUIS

* OS : Linux/macOS (Windows via WSL recommandé)
* Python : 3.12 (testé) — 3.11+ acceptable
* Outils : git, make (facultatif), tar/zip
* Dépendances (au choix) :
  • Conda/Mamba : « environment.yml »
  • Pip/venv : « requirements.txt »
* Fichiers de config présents :
  • « zz-configuration/mcgt-global-config.ini »
  • « zz-schemas/consistency\_rules.json »
  • « zz-manifests/manifest\_master.json » (si inventaire existant)
  • « zz-manifests/meta\_template.json »

2. INSTALLATION DE L’ENVIRONNEMENT
   Option A — Conda/Mamba
   mamba env create -f environment.yml  # ou conda env create -f environment.yml
   conda activate mcgt
   Option B — Environnement virtuel Python (venv + pip)
   python3 -m venv .venv
   . .venv/bin/activate
   pip install -U pip
   pip install -r requirements.txt
   Vérification rapide
   python -V
   python -c "import numpy,pandas,matplotlib,scipy,jsonschema; print('OK')"
3. VARIABLES \& RÈGLES TRANSVERSES

* Config globale (obligatoire) : MCGT\_CONFIG
  export MCGT\_CONFIG=zz-configuration/mcgt-global-config.ini
* Règles de cohérence (aliases de chemins, valeurs canoniques, fenêtres métriques, renommages FR→EN) : MCGT\_RULES (optionnel, recommandé)
  export MCGT\_RULES=zz-schemas/consistency\_rules.json
* Conventions d’unités (rappel) : fréquence « f\_Hz » (Hz), angles en radians (suffixe « \_rad »), multipôles « ell », distances « dist » (Mpc), etc. Voir « convention.md ».

4. CONTROLES RAPIDES (SANITY CHECKS)
   Afficher versions/chemins (Makefile)
   make env
   make paths
   Audit des schémas JSON (chargement brut)
   make audit-schemas
   Audit de présence des fichiers clés
   make audit-data
5. VALIDATION (SCHEMAS \& TABLES)
   Validation JSON (schémas ↔ instances)
   make validate-json           # tout le dépôt (saute les manquants)
   make ch09                    # filtre chapitre 09 (GW phase)
   make ch10                    # filtre chapitre 10 (MC 8D)
   Validation CSV (tables)
   make validate-csv
   Audit strict JSON (vide/HTML/broken)
   make jsoncheck-strict
   Pipeline QA (regroupe checks utiles)
   make qa
6. GÉNÉRATION — LIGNE DIRECTE (SANS MAKE)
   Remarque : le Makefile fourni est centré QA/validation. La (re)génération des artefacts se fait par scripts Python sous « zz-scripts/chapterXX/ ». Exemples ci-dessous (à adapter si vos chemins diffèrent).

6.1 Chapitre 09 — Phase d’ondes gravitationnelles
Étape 0 — (si besoin) extraire/régénérer la référence
python zz-scripts/chapter09/extract\_phenom\_phase.py
--out zz-data/chapter09/09\_phases\_imrphenom.csv
Étape 1 — Générer prétraitement + résidus
python zz-scripts/chapter09/generate\_data\_chapter09.py
--ref zz-data/chapter09/09\_phases\_imrphenom.csv
--out-prepoly zz-data/chapter09/09\_phases\_mcgt\_prepoly.csv
--out-diff    zz-data/chapter09/09\_phase\_diff.csv
--log-level INFO
Étape 2 — Optimiser (base, degré) + rebranch k, écrire la série finale
python zz-scripts/chapter09/opt\_poly\_rebranch.py
--csv zz-data/chapter09/09\_phases\_mcgt\_prepoly.csv
--meta zz-data/chapter09/09\_metrics\_phase.json
--fit-window 30 250 --metrics-window 20 300
--degrees 3 4 5 --bases log10 hz --k-range -10 10
--out-csv  zz-data/chapter09/09\_phases\_mcgt.csv
--out-best zz-data/chapter09/09\_best\_params.json
--backup --log-level INFO
Étape 3 — Figures
python zz-scripts/chapter09/plot\_fig01\_phase\_overlay.py
--csv  zz-data/chapter09/09\_phases\_mcgt.csv
--meta zz-data/chapter09/09\_metrics\_phase.json
--out  zz-figures/chapter09/fig\_01\_phase\_overlay.png
--shade 20 300 --show-residual --dpi 300
python zz-scripts/chapter09/plot\_fig02\_residual\_phase.py
--csv  zz-data/chapter09/09\_phases\_mcgt.csv
--meta zz-data/chapter09/09\_metrics\_phase.json
--out  zz-figures/chapter09/fig\_02\_residual\_phase.png
--bands 20 300 300 1000 1000 2000 --dpi 300
python zz-scripts/chapter09/plot\_fig03\_hist\_absdphi\_20\_300.py
--csv  zz-data/chapter09/09\_phases\_mcgt.csv
--meta zz-data/chapter09/09\_metrics\_phase.json
--out  zz-figures/chapter09/fig\_03\_hist\_absdphi\_20\_300.png
--mode principal --bins 50 --window 20 300 --xscale log --dpi 300
Étape 4 — Jalons (catalogue GWTC-3 confident)

Préparez « zz-data/chapter09/09\_comparison\_milestones.csv »

puis flaguez selon sigma/classe :

python zz-scripts/chapter09/flag\_jalons.py
--csv  zz-data/chapter09/09\_comparison\_milestones.csv
--meta zz-data/chapter09/09\_comparison\_milestones.meta.json
--out-csv zz-data/chapter09/09\_comparison\_milestones.flagged.csv
--write-meta

Figures jalons :

python zz-scripts/chapter09/plot\_fig04\_absdphi\_milestones\_vs\_f.py
--diff   zz-data/chapter09/09\_phase\_diff.csv
--csv    zz-data/chapter09/09\_phases\_mcgt.csv
--meta   zz-data/chapter09/09\_metrics\_phase.json
--jalons zz-data/chapter09/09\_comparison\_milestones.csv
--out    zz-figures/chapter09/fig\_04\_absdphi\_milestones\_vs\_f.png
--window 20 300 --with\_errorbar --dpi 300
python zz-scripts/chapter09/plot\_fig05\_scatter\_phi\_at\_fpeak.py
--jalons zz-data/chapter09/09\_comparison\_milestones.csv
--out    zz-figures/chapter09/fig\_05\_scatter\_phi\_at\_fpeak.png

6.2 Chapitre 10 — Monte Carlo global 8D
Étape 1 — Config (paramètres/prior/nuisances)
cat zz-data/chapter10/10\_mc\_config.json   # vérifiez les bornes, seed, n
Étape 2 — Génération/évaluation principale
python zz-scripts/chapter10/generate\_data\_chapter10.py
--config zz-data/chapter10/10\_mc\_config.json
--out-results zz-data/chapter10/10\_mc\_results.csv
--out-results-circ zz-data/chapter10/10\_mc\_results.circ.csv
--out-samples zz-data/chapter10/10\_mc\_samples.csv
--log-level INFO
Étape 3 — Diagnostics complémentaires

Ajout de φ(f\_peak) et QA circulaire

python zz-scripts/chapter10/add\_phi\_at\_fpeak.py
--results zz-data/chapter10/10\_mc\_results.circ.csv
--out     zz-data/chapter10/10\_mc\_results.circ.with\_fpeak.csv
python zz-scripts/chapter10/inspect\_topk\_residuals.py
--results zz-data/chapter10/10\_mc\_results.csv
--jalons  zz-data/chapter10/10\_mc\_milestones\_eval.csv
--out-dir zz-data/chapter10/topk\_residuals
python zz-scripts/chapter10/bootstrap\_topk\_p95.py
--results zz-data/chapter10/10\_mc\_results.csv
--topk-json zz-data/chapter10/10\_mc\_best.json
--out-json  zz-data/chapter10/10\_mc\_best\_bootstrap.json
--B 1000 --seed 12345
Étape 4 — Figures de synthèse
python zz-scripts/chapter10/plot\_fig01\_iso\_p95\_maps.py        --out zz-figures/chapter10/fig\_01\_iso\_p95\_maps.png
python zz-scripts/chapter10/plot\_fig02\_scatter\_phi\_at\_fpeak.py --out zz-figures/chapter10/fig\_02\_scatter\_phi\_at\_fpeak.png
python zz-scripts/chapter10/plot\_fig03\_convergence\_p95\_vs\_n.py --out zz-figures/chapter10/fig\_03\_convergence\_p95\_vs\_n.png
python zz-scripts/chapter10/plot\_fig03b\_bootstrap\_coverage\_vs\_n.py --out zz-figures/chapter10/fig\_03b\_coverage\_bootstrap\_vs\_n\_hires.png
python zz-scripts/chapter10/plot\_fig04\_scatter\_p95\_recalc\_vs\_orig.py --out zz-figures/chapter10/fig\_04\_scatter\_p95\_recalc\_vs\_orig.png
python zz-scripts/chapter10/plot\_fig05\_hist\_cdf\_metrics.py     --out zz-figures/chapter10/fig\_05\_hist\_cdf\_metrics.png
python zz-scripts/chapter10/plot\_fig06\_residual\_map.py         --out zz-figures/chapter10/fig\_06\_heatmap\_absdp95\_m1m2.png
python zz-scripts/chapter10/plot\_fig07\_synthesis.py            --out zz-figures/chapter10/fig\_07\_summary\_comparison.png

7. VALIDATION APRÈS GÉNÉRATION
   JSON (exemples)
   python zz-schemas/validate\_json.py zz-schemas/mc\_config\_schema.json      zz-data/chapter10/10\_mc\_config.json
   python zz-schemas/validate\_json.py zz-schemas/mc\_best\_schema.json        zz-data/chapter10/10\_mc\_best.json
   python zz-schemas/validate\_json.py zz-schemas/metrics\_phase\_schema.json  zz-data/chapter09/09\_metrics\_phase.json
   CSV (exemples)
   python zz-schemas/validate\_csv\_table.py zz-schemas/mc\_results\_table\_schema.json          zz-data/chapter10/10\_mc\_results.csv
   python zz-schemas/validate\_csv\_table.py zz-schemas/mc\_results\_table\_schema.json          zz-data/chapter10/10\_mc\_results.circ.csv
   python zz-schemas/validate\_csv\_table.py zz-schemas/jalons\_comparaison\_table\_schema.json  zz-data/chapter09/09\_comparison\_milestones.csv
   Vérifs ciblées (Makefile)
   make ch09
   make ch10
   Audit strict JSON (repo entier)
   make jsoncheck-strict
8. MANIFESTES \& PUBLICATION
   Vérifier et rapporter l’inventaire
   python zz-manifests/diag\_consistency.py
   zz-manifests/manifest\_publication.json
   --report md > zz-manifests/manifest\_report.md
   Corriger/compléter (optionnel, prudence)
   python zz-manifests/diag\_consistency.py
   zz-manifests/manifest\_master.json
   --fix --normalize-paths --strip-internal --sha256-out
   Préparer une archive livrable (exemple)
   tar czf MCGT\_artifacts\_$(date +%Y%m%d).tar.gz
   zz-data/ zz-figures/ zz-manifests/ zz-schemas/
   convention.md README-REPRO.md RUNBOOK.md
9. ARBORESCENCE MINIMALE ATTENDUE
   MCGT/
   ├─ main.tex
   ├─ convention.md
   ├─ README-REPRO.md
   ├─ RUNBOOK.md
   ├─ zz-configuration/
   │  ├─ mcgt-global-config.ini
   │  ├─ camb\_exact\_plateau.ini
   │  └─ gw\_phase.ini (etc.)
   ├─ zz-schemas/
   │  ├─ *.schema.json (dont mc\_config\_schema.json, metrics\_phase\_schema.json, mc\_results\_table\_schema.json, jalons\_comparaison\_table\_schema.json)
   │  ├─ consistency\_rules.json
   │  └─ validate\_*.py
   ├─ zz-data/
   │  ├─ chapter09/ (09\_phases\_imrphenom.csv, 09\_phases\_mcgt.csv, 09\_phase\_diff.csv, 09\_metrics\_phase.json, 09\_comparison\_milestones\*.csv/.json)
   │  └─ chapter10/ (10\_mc\_config.json, 10\_mc\_results\*.csv, 10\_mc\_best\*.json, 10\_mc\_milestones\_eval.csv)
   ├─ zz-figures/
   │  ├─ chapter09/ (fig\_01\_phase\_overlay.png, …)
   │  └─ chapter10/ (fig\_01\_iso\_p95\_maps.png, …)
   └─ zz-manifests/
   ├─ manifest\_master.json
   ├─ manifest\_publication.json
   ├─ manifest\_report.md
   └─ diag\_consistency.py
10. BONNES PRATIQUES \& CONTRÔLES SPÉCIFIQUES

* Fixer la graine et l’échantillonnage Sobol (chap. 10) dans « 10\_mc\_config.json » : « scramble », « seed », « n ». Conserver ces valeurs dans les métadonnées.
* Fenêtre métrique standard (chap. 9/10) : \[20,300] Hz. Toujours documenter la fenêtre utilisée dans les JSON.
* Radians partout pour les phases. Les statistiques « \_circ » (circulaires) doivent être explicitées (suffixe « \_circ ») et cohérentes avec les versions linéaires.
* Harmonisation des chemins : préférer « zz-data/chapter09 » (et non « chapter9 »). Les alias FR historiques sont résolus via « zz-schemas/consistency\_rules.json ».
* Toujours exécuter « make qa » avant la préparation de publication.

11. TROUBLESHOOTING (APERÇU)

* « FileNotFoundError » lors d’une validation : vérifier le chemin exact (« chapter09 » vs « chapter9 » ; « zz-data » vs « zz-donnees »). Utiliser « make ch09 » pour repérer les manquants.
* « JSONDecodeError » : ouvrir le fichier et vérifier qu’il n’est ni vide ni tronqué ; passer « make jsoncheck-strict ».
* Écarts p95 entre CSV et JSON (chap. 10) : vérifier l’usage de la version circulaire (« \*\_circ ») et la fenêtre de recalcul ; re-régénérer « 10\_mc\_best\_bootstrap.json » si besoin.

12. SUPPORT / QUESTIONS

* Conventions d’unités, formats et classes : « convention.md »
* Règles transverses et alias : « zz-schemas/consistency\_rules.json »
* Manifests \& audit : « zz-manifests/README\_manifest.md » et « zz-manifests/diag\_consistency.py »
* Guides par chapitre : « CHAPTERXX\_GUIDE.txt » dans chaque dossier LaTeX.

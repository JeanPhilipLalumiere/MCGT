# MCGT — Inventaire de nettoyage (lecture seule)
*Run:* 20251028T180203Z
*Racine détectée:* /home/jplal/MCGT

## Résumé quantifié
- Logs & traces candidates : 483
- Caches & artefacts build : 4
- Temp/Sauvegardes         : 66
- Dossiers non obligatoires : 2
- Gros fichiers (≥30 MiB)   : 0
- Archives/Bundles suspects : 41
- Figures multi-format      : 0

## Propositions (à valider, **aucune suppression automatique**)
1) Construire une **IGNORE LIST** des familles ci-dessus (après revue).
2) Consolider une **ADD LIST** pour tout fichier d’autorité (manifests, LICENSE, CITATION, README-REPRO).
3) Définir la règle **REVIEW = INVENTAIRE – IGNORE + ADD** (priorité **ADD** > **IGNORE**).
4) Spécifier repo-wide les **valeurs par défaut CLI** (--format, --dpi, --outdir, --transparent, --style, --verbose).

## Pistes d'attentions
- Vérifier les *gros fichiers* : si données sources/publication, documenter; sinon planifier purge ou externalisation.
- Vérifier *figures multi-format* : choisir le set canonique (e.g., PNG+SVG) et ignorer le reste.

## Step 2 — Listes Round2 (20251028T180433Z)
- **IGNORE** : 92 motifs/chemins
- **ADD**    : 47 chemins d'autorité
- **REVIEW** : 11 éléments à inspection manuelle

### Règle rappel
`REVIEW = (INVENTAIRE – IGNORE) ∪ ADD` avec priorité **ADD > IGNORE**.

### Prochaines actions
1) Parcourir *review_list_round2.txt* et soit déplacer vers **IGNORE**, soit vers **ADD**.
2) Après tri, geler les patterns IGNORE dans *.gitignore* et documenter les exceptions.
3) Lancer Step 3 (dé-dup Makefiles + profil QUIET) — je te fournirai le script.

## Step 3 — Assistant de tri (20251028T181143Z)
- REVIEW total: 11
- IGNORE motifs: 92
- ADD chemins: 47
- Propositions: `gitignore_proposition_round2.txt`, plan sec: `purge_plan_dryrun.txt`
- Histogramme par racine: `_tmp/review_hist_20251028T181143Z.txt`

## Step 3 — Assistant de tri (20251028T181549Z)
- REVIEW total: 11
- IGNORE motifs: 99
- ADD chemins: 47
- Propositions: `gitignore_proposition_round2.txt`, plan sec: `purge_plan_dryrun.txt`
- Histogramme par racine: `_tmp/review_hist_20251028T181549Z.txt`

## Step 3 — Assistant de tri (20251028T182855Z)
- REVIEW total: 11
- IGNORE motifs: 99
- ADD chemins: 47
- Propositions: `gitignore_proposition_round2.txt`, plan sec: `purge_plan_dryrun.txt`
- Histogramme par racine: `_tmp/review_hist_20251028T182855Z.txt`

## Step 3 — Assistant de tri (20251028T182953Z)
- REVIEW total: 11
- IGNORE motifs: 99
- ADD chemins: 47
- Propositions: `gitignore_proposition_round2.txt`, plan sec: `purge_plan_dryrun.txt`
- Histogramme par racine: `_tmp/review_hist_20251028T182953Z.txt`

## Step 3 — Assistant de tri (20251028T183602Z)
- REVIEW total: 11
- IGNORE motifs: 99
- ADD chemins: 47
- Propositions: `gitignore_proposition_round2.txt`, plan sec: `purge_plan_dryrun.txt`
- Histogramme par racine: `_tmp/review_hist_20251028T183602Z.txt`

## Focus Round2 — 20251028T194855Z

- **tools/** : 389 fichier(s) à classifier `keep/migrate→zz_tools/attic`
- **zz-scripts/** : 236 script(s) à normaliser (CLI `--help`, args communs, reproductibilité)

### Checklist (à cocher manuellement)
- [ ] Parcourir `./_tmp/inventaires/focus_tools.txt` et marquer *attic* vs *migrate→zz_tools* vs *keep*
- [ ] Parcourir `./_tmp/inventaires/focus_zzscripts.txt` et vérifier `-h/--help` + conventions (fmt/dpi/outdir/transparent/style/verbose)
- [ ] Déplacer les utilitaires génériques vers le package `zz_tools` (points d’entrée CLI)
- [ ] Mettre à jour `ignore_list_round2.txt` pour les outils obsolètes/attic
- [ ] Rejouer `step3_regen_strict.sh` pour mesurer l’effet sur la REVIEW

## Focus Round2 — 20251028T194951Z

- **tools/** : 389 fichier(s) à classifier `keep/migrate→zz_tools/attic`
- **zz-scripts/** : 236 script(s) à normaliser (CLI `--help`, args communs, reproductibilité)

### Checklist (à cocher manuellement)
- [ ] Parcourir `./_tmp/inventaires/focus_tools.txt` et marquer *attic* vs *migrate→zz_tools* vs *keep*
- [ ] Parcourir `./_tmp/inventaires/focus_zzscripts.txt` et vérifier `-h/--help` + conventions (fmt/dpi/outdir/transparent/style/verbose)
- [ ] Déplacer les utilitaires génériques vers le package `zz_tools` (points d’entrée CLI)
- [ ] Mettre à jour `ignore_list_round2.txt` pour les outils obsolètes/attic
- [ ] Rejouer `step3_regen_strict.sh` pour mesurer l’effet sur la REVIEW

## Preclass Round2 — 20251028T201214Z

- Total préclassés (tools + zz-scripts): 625
  - keep: 80
  - migrate→zz_tools/env: 34
  - attic-suggest: 120
  - review: 391

### Actions proposées (non destructives)
- [ ] Valider **preclass_keep.txt** (conserver tels quels)
- [ ] Valider **preclass_migrate.txt** (migrer vers `zz_tools` ou env centralisé)
- [ ] Valider **preclass_attic_suggest.txt** (rétrograder dans IGN ou attic après confirmation)
- [ ] Parcourir **preclass_review.txt** (doute/edge-cases)
- [ ] Rejouer `step3_regen_strict.sh` pour mesurer la baisse de REVIEW après décisions

## Simulation d'impact (attic-suggest → IGN virtuel) — 20251028T201401Z

- REVIEW actuelle : 1171
- REVIEW simulée  : 1051
- Réduction simulée : 120
- Rapport: ./_tmp/inventaires/review_sim_report_20251028T201401Z.txt

## Simulation d'impact (attic-suggest → IGN virtuel) — 20251028T202554Z

- REVIEW actuelle : 1051
- REVIEW simulée  : 1051
- Réduction simulée : 0
- Rapport: ./_tmp/inventaires/review_sim_report_20251028T202554Z.txt

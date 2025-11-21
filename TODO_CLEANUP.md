# TODO_CLEANUP – 20251114T002816Z

## Fichiers volumineux (>10MB) suivis par Git
- 569931294 B  e9b7969883f3e64a45b884afed0ba9d7232336ce
- 32831251 B  c6124aa95a14f0e666eba4fa44735a460f5107ac
- 25050385 B  d6449096b01ecc38d4693856e30c8351d96bd559
- 24817849 B  d10bfcb5b4a299191883022d75b8a52a2041aa74
- 10808937 B  4507334689552ad74f65683cca24554e047ce654

## Artefacts temporaires & bruits à retirer du dépôt (si présents)
- __pycache__/, .pytest_cache/, .mypy_cache/, .ipynb_checkpoints/
- *.pyc, *.pyo, *~, *.bak, *.tmp, .DS_Store
- .env, .venv/, .vscode/, .idea/
- _tmp/, .ci-out/ (déplacer en artefacts CI)
- *.lock.json (si non requis pour traçabilité publique)

## Dossiers potentiellement non canoniques (naming)

## Fichiers non indexés utiles à .gitignore
- diff_tags_conflicts_guard.sh
- diff_tags_conflicts_guard_v3.sh
- post_merge_verify.sh
- push_only_new_tags_guard.sh
- push_only_new_tags_guard_v2.sh
- push_only_new_tags_guard_v3.sh
- resolve_tag_conflicts_v1.sh
- smoke_admin_merge_guard.sh
- smoke_admin_merge_guard_v2.sh
- smoke_admin_merge_guard_v3.sh
- smoke_admin_merge_guard_v4.sh

## Actions proposées
- Déplacer archives/anciens assets sous attic/ ou en Release assets.
- Harmoniser zero-padding (chapterNN) et slugs (a-z0-9_).
- Purger les gros fichiers non requis par la publication (après copie sécurisée).

## Diag manif — Probe 20251114T004257Z
- Script : `zz-manifests/diag_consistency.py`
- Meilleur essai : `help_dash_h` (rc=0)
- Dossier logs : `_tmp/manifest_diag_probe_20251114T004257Z`
- Tips : si l’aide mentionne des flags spécifiques (ex. --manifest, --config), relance en conséquence.

## Diag publication — 20251114T004912Z
- Entrée : zz-manifests/manifest_publication.json
- Sortie : _tmp/diag_publication_20251114T004912Z/diag.txt
- Artifacts : _tmp/diag_publication_20251114T004912Z/errors.csv · _tmp/diag_publication_20251114T004912Z/errors_sizesha.csv · _tmp/diag_publication_20251114T004912Z/plan_remediation.md
- Prochain choix par type :
  - FILE_MISSING → regénérer/ajouter OU retirer du manifeste
  - SIZE/SHA_MISMATCH → mettre à jour le manifeste OU regénérer l’artefact
  - Warnings (MTIME/GIT_HASH_MISSING) → tolérés si documentés

## Fast-fix — 20251114T005639Z
- Mode: dry-run
- Triage: _tmp/diag_publication_20251114T004912Z
- Sorties: _tmp/fastfix_20251114T005639Z/plan.json, _tmp/fastfix_20251114T005639Z/post_diag.txt

## Fast-fix — 20251114T005712Z
- Mode: apply
- Triage: _tmp/diag_publication_20251114T004912Z
- Sorties: _tmp/fastfix_20251114T005712Z/plan.json, _tmp/fastfix_20251114T005712Z/post_diag.txt

## Dedupe — 20251114T010153Z
- Mode: dry-run
- Sorties: _tmp/dedupe_20251114T010153Z/dedupe_report.json, _tmp/dedupe_20251114T010153Z/post_diag.txt

## Dedupe — 20251114T010157Z
- Mode: apply
- Sorties: _tmp/dedupe_20251114T010157Z/dedupe_report.json, _tmp/dedupe_20251114T010157Z/post_diag.txt

## Warnfix — 20251114T010616Z
- Mode: dry-run
- Sorties: _tmp/warnfix_20251114T010616Z/warnfix_stats.json, _tmp/warnfix_20251114T010616Z/post_errors.txt, _tmp/warnfix_20251114T010616Z/post_full.txt

## Warnfix — 20251114T010626Z
- Mode: apply
- Sorties: _tmp/warnfix_20251114T010626Z/warnfix_stats.json, _tmp/warnfix_20251114T010626Z/post_errors.txt, _tmp/warnfix_20251114T010626Z/post_full.txt

## Gitmark — 20251114T011845Z
- Mode: dry-run
- Sorties: _tmp/gitmark_20251114T011845Z/gitmark_stats.txt, _tmp/gitmark_20251114T011845Z/post_diag.txt

## Gitmark — 20251114T011854Z
- Mode: apply
- Sorties: _tmp/gitmark_20251114T011854Z/gitmark_stats.txt, _tmp/gitmark_20251114T011854Z/post_diag.txt

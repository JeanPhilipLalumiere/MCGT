#!/usr/bin/env bash
set -Eeuo pipefail
echo "[INFO] Préparation homogénéisation"

# A) jalon git
git tag -f mcgt_homog_baseline || true
git checkout -B feat/homog || true

# B) module commun déjà créé; on commit le setup
git add zz-tools/common_io.py zz-tools/codemod_meta_guard.py zz-tools/codemod_tightlayout.py zz-tools/chapter_migrate_pilot.sh
git commit -m "tools: common_io + codemods + pilote homogénéisation" || true

# C) pilote DRY-RUN (CH08 par défaut)
bash zz-tools/chapter_migrate_pilot.sh chapter08
echo "[OK] Préparation terminée (dry-run)."

#!/usr/bin/env bash
# apply_title_patch_minimal.sh — garantit le nouveau titre dans README.md & CITATION.cff (docs only)
set -euo pipefail
ROOT="$(git rev-parse --show-toplevel)"; cd "$ROOT"

TITLE="Le Modèle de la Courbure Gravitationnelle du Temps"

# se placer sur la branche de PR #30
BR="$(gh pr view 30 --json headRefName -q .headRefName)"
git fetch origin "$BR" >/dev/null 2>&1 || true
git switch "$BR" >/dev/null 2>&1 || git checkout "$BR"

# README.md : remplacer un titre de page trop court (ex. "# MCGT") par le titre officiel
if [[ -f README.md ]]; then
  awk -v T="$TITLE" '
    NR==1 && $0 ~ /^#\s*MCGT\s*$/ { print "# " T " (MCGT)"; next }
    { print }
  ' README.md > _tmp.README.md && mv _tmp.README.md README.md
fi

# CITATION.cff : fixer title: …
if [[ -f CITATION.cff ]]; then
  awk -v T="$TITLE" '
    BEGIN{done=0}
    /^title:/ && done==0 { print "title: " T; done=1; next }
    { print }
    END{ if(done==0) print "title: " T }
  ' CITATION.cff > _tmp.CITATION.cff && mv _tmp.CITATION.cff CITATION.cff
fi

# Remplacement de la formulation longue « … temporelle » par le titre officiel dans docs/meta
perl -0777 -pe "use utf8; s/mod[èe]le\\s+de\\s+la\\s+courbure\\s+gravitationnelle\\s+temporelle/$TITLE/ig;" \
  -i $(git ls-files '*.'{md,rst,tex,yml,yaml,toml,cff,json} | tr '\n' ' ') || true

# Commit/push si diff
if ! git diff --quiet; then
  git add -A
  git commit -m "docs: harmonise le titre dans README/CITATION et docs (sans toucher le package/code)"
  git push
fi

# relance checks PR + rappel de merge conseillé
gh workflow run pypi-build.yml  --ref "$BR" >/dev/null 2>&1 || true
gh workflow run secret-scan.yml --ref "$BR" >/dev/null 2>&1 || true
echo "[NEXT] Lance: bash finish_pr30_with_guard.sh"

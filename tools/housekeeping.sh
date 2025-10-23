#!/usr/bin/env bash
set -euo pipefail

echo "== [1] .gitignore enrichi =="
{
  echo ""
  echo "# housekeeping (auto)"
  echo "_tmp/"
  echo "_tmp-figs/"
  echo "nano.*.save"
  echo "*.swp"
  echo "*~"
  echo "._*"
  echo "zz-manifests/manifest_master.backfilled*.json"
  echo "_archives_preclean/"
  echo "_attic_untracked/"
} >> .gitignore || true
awk '!a[$0]++' .gitignore > .gitignore.tmp && mv .gitignore.tmp .gitignore

echo "== [2] Déplacement non-suivis =="
tools/_safe_move_untracked.sh

echo "== [3] Audit TSV =="
tools/audit_manifest_files.sh --all || true
sed -n '1,5p' _tmp/manifest_audit.tsv || true
wc -l _tmp/manifest_audit.tsv || true

echo "== [4] Diag strict =="
python3 zz-manifests/diag_consistency.py zz-manifests/manifest_master.json \
  --report json --normalize-paths --apply-aliases --strip-internal --content-check --fail-on warnings || {
    echo "::error::diag_consistency a détecté un écart"; exit 1; }

echo "== [5] Tests =="
pytest -q || { echo "::error::tests en échec"; exit 1; }

echo "== [6] Commit =="
git add -A
git commit -m "housekeeping: move untracked, audit+diag strict, tests OK" || echo "rien à committer"

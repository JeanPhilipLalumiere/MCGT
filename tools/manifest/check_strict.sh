#!/usr/bin/env bash
set -euo pipefail
python zz-manifests/diag_consistency.py zz-manifests/manifest_master.json \
  --report json --normalize-paths --apply-aliases --strip-internal \
  --content-check --fail-on errors

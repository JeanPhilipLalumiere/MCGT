#!/usr/bin/env bash
set -euo pipefail

# Racine du dépôt
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

# Localiser diag_consistency.py
if [ -f "$ROOT/zz-manifests/diag_consistency.py" ]; then
  DIAG="$ROOT/zz-manifests/diag_consistency.py"
elif [ -f "$ROOT/zz_tools/diag_consistency.py" ]; then
  DIAG="$ROOT/zz_tools/diag_consistency.py"
elif [ -f "$ROOT/tools/diag_consistency.py" ]; then
  DIAG="$ROOT/tools/diag_consistency.py"
else
  echo "diag_consistency.py introuvable, vérifie dans zz-manifests/, zz_tools/ ou tools/" >&2
  exit 1
fi

run_one () {
  local manifest="$1"
  echo
  echo "[CHECK] diag_consistency sur ${manifest}"
  python "$DIAG" \
    --repo-root "$ROOT" \
    --report text \
    --fail-on errors \
    "$ROOT/${manifest}"
}

run_one "zz-manifests/manifest_publication.json"
run_one "zz-manifests/manifest_master.json"

echo
echo "[DONE] diag_consistency terminé pour manifest_publication et manifest_master."

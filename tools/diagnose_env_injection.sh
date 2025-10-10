#!/usr/bin/env bash
set -euo pipefail
echo "[DIAG] Recherche d'injections 'environment'…"
grep -RIn --exclude-dir=.git -E '(^|[[:space:]])(\.|source)[[:space:]]+("?'\''?)\.?/??environment("?'\''?)([[:space:]]|$)' . || true
echo
echo "[DIAG] Références à BASH_ENV/ENV dans pass14…"
grep -RIn --exclude-dir=.git -E '\b(BASH_ENV|(^|[^A-Z_])ENV=)' tools/pass14_smoke_with_mapping.sh || true

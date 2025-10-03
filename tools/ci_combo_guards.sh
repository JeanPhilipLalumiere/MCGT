#!/usr/bin/env bash
set -euo pipefail
ROOT="$(git rev-parse --show-toplevel)"
cd "$ROOT"

echo "==> [combo] Naming guard"
bash tools/ci_step4_guard_naming.sh

echo "==> [combo] Figures guard (STRICT_ORPHANS=1)"
STRICT_ORPHANS=1 bash tools/ci_step2_validate_and_guard.sh

echo "==> [combo] Manifest SHA256 guard"
bash tools/ci_step3_validate_manifests.sh

echo "✅ combo guards: OK"

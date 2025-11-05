#!/usr/bin/env bash
# shellcheck source=/dev/null
. .ci-helpers/guard.sh
set -euo pipefail
LOG=".ci-logs/ci_add_yaml_check-$(date +%Y%m%dT%H%M%S).log"
exec > >(stdbuf -oL -eL tee -a "$LOG") 2>&1
say() {
  date +"[%F %T] - "
  printf "%s\n" "$*"
}

say "Checking YAML syntax for .github/workflows/*.yml"
python - <<'PY'
import sys, glob, yaml
ok=True
for p in glob.glob(".github/workflows/*.yml"):
    try:
        with open(p,'r') as f:
            yaml.safe_load(f)
        print("OK:",p)
    except Exception as e:
        ok=False
        print("ERROR:",p, e)
if not ok:
    sys.exit(2)
PY
say "Done. Log: $LOG"

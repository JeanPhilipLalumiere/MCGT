#!/usr/bin/env bash
# shellcheck source=/dev/null
. .ci-helpers/guard.sh
set -e
python - <<'PY'
import glob, sys
try:
    import yaml  # type: ignore
except Exception:
    print("PyYAML absent; essaye: pip install pyyaml", file=sys.stderr); sys.exit(1)

files = glob.glob(".github/workflows/*.yml")
if not files:
    print("Aucun workflow YAML trouvé.")
    sys.exit(0)

err = 0
for f in files:
    try:
        with open(f, "r", encoding="utf-8") as fh:
            yaml.safe_load(fh)
        print(f"[OK] {f}")
    except Exception as e:
        err = 1
        print(f"[FAIL] {f}: {e}", file=sys.stderr)
sys.exit(err)
PY

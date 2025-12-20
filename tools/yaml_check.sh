#!/bin/bash
set -e
echo "Checking YAML workflows..."
for f in .github/workflows/*.yml; do
  python3 -c "import yaml; yaml.safe_load(open('$f'))"
  echo "OK: $f"
done

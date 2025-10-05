#!/usr/bin/env bash
set -euo pipefail
# échoue si un "cp -n" est trouvé dans tools/*.sh
if grep -R --line-number -E '^[[:space:]]*cp[[:space:]]+-n\b' tools/*.sh >/dev/null 2>&1; then
  echo "ERROR: 'cp -n' détecté dans tools/*.sh — utilise un backup POSIX idempotent."
  exit 1
fi

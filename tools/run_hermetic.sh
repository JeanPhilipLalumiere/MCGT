#!/usr/bin/env bash
set -euo pipefail
if [[ $# -lt 1 ]]; then
  echo "Usage: $0 <commande ...>" >&2
  exit 2
fi
exec tools/hermetic_pause_runner.sh "$@"

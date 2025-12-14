#!/usr/bin/env bash
set -Eeuo pipefail
cd "$(git rev-parse --show-toplevel)"

# 0 = rien trouvé, 1 = junk trouvé
find . -maxdepth 1 -type f \
  \( -name "*.bak*" -o -name "*.tmp" -o -name "*.save" -o -name "nano.*.save" \
     -o -name ".ci-out_*" -o -name "_diag_*.json" -o -name "_tmp_*" \
     -o -name "*.tar.gz" -o -name "*LOG" -o -name "*.psx_bak*" \) \
  -printf "%P\n" \
| sort -u \
| awk 'BEGIN{n=0} {print; n++} END{exit(n>0)}'

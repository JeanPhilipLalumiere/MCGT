#!/usr/bin/env bash
set -Eeuo pipefail
cd "$(git rev-parse --show-toplevel)"

# 0 = rien trouvé (untracked), 1 = junk untracked trouvé
matches=$(
  find . -maxdepth 1 -type f \
    \( -name "*.bak*" -o -name "*.tmp" -o -name "*.save" -o -name "nano.*.save" \
       -o -name ".ci-out_*" -o -name "_diag_*.json" -o -name "_tmp_*" \
       -o -name "*.tar.gz" -o -name "*LOG" -o -name "*.psx_bak*" \) \
    -printf "%P\n" | sort -u
)

n=0
while IFS= read -r f; do
  [[ -z "$f" ]] && continue
  # Ignore legacy tracked files (on ne veut alerter que sur les nouveaux untracked)
  if git ls-files --error-unmatch -- "$f" >/dev/null 2>&1; then
    continue
  fi
  echo "$f"
  n=$((n+1))
done <<<"$matches"

if [[ $n -gt 0 ]]; then
  exit 1
fi
exit 0

#!/usr/bin/env bash
set -Eeuo pipefail
cd "$(git rev-parse --show-toplevel)"

ts="$(date -u +%Y%m%dT%H%M%SZ)"
dest="_attic_untracked/quarantine_root_junk_${ts}"
mkdir -p "$dest"

mapfile -t files < <(
  find . -maxdepth 1 -type f \
    \( -name "*.bak*" -o -name "*.tmp" -o -name "*.save" -o -name "nano.*.save" \
       -o -name ".ci-out_*" -o -name "_diag_*.json" -o -name "_tmp_*" \
       -o -name "*.tar.gz" -o -name "*LOG" -o -name "*.psx_bak*" \) \
    -printf "%P\n" | sort -u
)

if [[ ${#files[@]} -eq 0 ]]; then
  echo "[OK] Aucun junk détecté."
  exit 0
fi

echo "[INFO] Quarantaine vers: $dest"
for f in "${files[@]}"; do
  if git ls-files --error-unmatch -- "$f" >/dev/null 2>&1; then
    echo "[SKIP tracked] $f"
  else
    echo "[MOVE] $f -> $dest/"
    mv -v -- "$f" "$dest/"
  fi
done

echo "[OK] Quarantaine terminée: $dest"

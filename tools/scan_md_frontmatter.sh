#!/usr/bin/env bash
set -Eeuo pipefail
OUT=".ci-out/frontmatter_samples.txt"
: >"$OUT"
found=0

while IFS= read -r -d '' f; do
  if head -n1 "$f" | grep -qE '^---[[:space:]]*$'; then
    found=1
    {
      echo "========================================================================"
      echo ">>> FILE: $f"
      echo "========================================================================"
      awk '
        NR==1 && /^---[[:space:]]*$/ {infm=1; print; next}
        infm { print; if (/^---[[:space:]]*$/){ print ""; exit } }
      ' "$f"
    } | tee -a "$OUT"
  fi
done < <(find . -type f -name '*.md' -print0 | sort -z)

if [ "$found" -eq 0 ]; then
  echo "(aucun front-matter trouvé)" | tee -a "$OUT"
fi
echo "[frontmatter] échantillons → $OUT"

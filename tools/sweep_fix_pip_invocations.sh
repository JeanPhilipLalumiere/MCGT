#!/usr/bin/env bash
set -Eeuo pipefail
echo "[INFO] Sweep: insertion PIP_CONSTRAINT si manquant"
changed=0
while IFS= read -r -d '' f; do
  case "$f" in
    _tmp/*|venv/*|.venv/*|.git/*) continue ;;
  esac
  tmp="$(mktemp)"
  perl -0777 -pe 's/(\bpip\s+install\b(?![^\n]*PIP_CONSTRAINT=))/PIP_CONSTRAINT=constraints\/security-pins.txt \1/g' "$f" > "$tmp" || true
  if ! cmp -s "$f" "$tmp"; then
    mkdir -p _tmp/sweep_before && cp "$f" "_tmp/sweep_before/${f//\//__}"
    mv "$tmp" "$f"
    echo "[FIX] $f"; changed=1
  else
    rm -f "$tmp"
  fi
done < <(git ls-files -z | grep -zE '\.sh$|\.py$|\.md$|(^|/)Makefile(\.|$)|\.ya?ml$')
[ $changed -eq 0 ] && echo "[OK] Aucun changement nécessaire." || echo "[DONE] Modifications appliquées."

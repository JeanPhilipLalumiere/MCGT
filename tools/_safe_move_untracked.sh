#!/usr/bin/env bash
set -uo pipefail
# Déplace proprement les fichiers non suivis (sans toucher aux caches, ni au wrapper).
git ls-files --others --exclude-standard -z | while IFS= read -r -d '' f; do
  # ignorer caches/dossiers bruyants et éléments à préserver
  [[ "$f" == _tmp/* || "$f" == _tmp-figs/* || "$f" == .git/* ]] && continue
  [[ "$f" == "run_housekeeping_capture.sh" ]] && { echo "skip (wrapper root): $f"; continue; }
  [[ "$f" == tools/* ]] && { echo "skip (already in tools/): $f"; continue; }
  [[ "$f" == *.txt ]] && { echo "skip (.txt): $f"; continue; }

  case "$f" in
    *.sh)
      mkdir -p tools
      dest="tools/$(basename "$f")"
      ;;
    *)
      mkdir -p _attic_untracked
      dest="_attic_untracked/$(basename "$f")"
      ;;
  esac

  if mv -f -- "$f" "$dest" 2>/dev/null; then
    echo "moved: $f -> $dest"
  else
    echo "WARN: unable to move $f" >&2
  fi
done

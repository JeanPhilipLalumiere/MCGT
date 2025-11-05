#!/usr/bin/env bash
set -Eeuo pipefail
root="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
cd "$root"

echo ">>> VERIFY py (byte-compile) & sh (bash -n)"
tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT

# 1) liste des fichiers modifiés vs index
git diff --name-only > "$tmp/changed.txt" || true

py_ok=0 py_bad=0
sh_ok=0 sh_bad=0

while IFS= read -r f; do
  [[ -z "$f" || ! -f "$f" ]] && continue
  case "$f" in
    *.py)
      if python3 -m py_compile "$f" 2>>"$tmp/py.err"; then
        ((py_ok++))
      else
        echo "[PY-ERR] $f"
        ((py_bad++))
      fi
      ;;
    *.sh)
      if bash -n "$f" 2>>"$tmp/sh.err"; then
        ((sh_ok++))
      else
        echo "[SH-ERR] $f"
        ((sh_bad++))
      fi
      ;;
  esac
done < "$tmp/changed.txt"

echo
echo "PY OK=$py_ok  BAD=$py_bad"
[[ -s "$tmp/py.err" ]] && { echo "--- py.err ---"; cat "$tmp/py.err"; }
echo "SH OK=$sh_ok  BAD=$sh_bad"
[[ -s "$tmp/sh.err" ]] && { echo "--- sh.err ---"; cat "$tmp/sh.err"; }

[[ $py_bad -eq 0 && $sh_bad -eq 0 ]] && echo "✅ VERIFY PASS" || { echo "❌ VERIFY FAILED"; exit 1; }

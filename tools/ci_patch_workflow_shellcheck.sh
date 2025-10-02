#!/usr/bin/env bash
set -euo pipefail

WF=".github/workflows/sanity-main.yml"
[ -f "$WF" ] || { echo "Fichier introuvable: $WF" >&2; exit 1; }

tmp="$(mktemp)"
awk -v OFS="" '
function flush_seq() {
  if (in_seq) {
    print summary_indent "} >> \"$GITHUB_STEP_SUMMARY\""
    in_seq=0
  }
}
{
  line=$0

  # ---- SC2129: group consecutive appends to $GITHUB_STEP_SUMMARY
  if (match(line, /^([[:space:]]*)echo .*>>[[:space:]]*"\$GITHUB_STEP_SUMMARY"[[:space:]]*$/, m)) {
    if (!in_seq) { in_seq=1; summary_indent=m[1]; print summary_indent "{" }
    sub(/[[:space:]]*>>[[:space:]]*"\$GITHUB_STEP_SUMMARY"[[:space:]]*$/, "", line)
    print line
    next
  } else {
    flush_seq()
  }

  # ---- SC2015: replace "A && B || C" with if/else (gh auth check)
  if (match(line, /^([[:space:]]*)command -v gh[[:space:]]*>\/dev\/null 2>&1 && gh auth status \|\| echo "WARN: gh not authenticated or not installed"[[:space:]]*$/, m)) {
    indent=m[1]
    print indent "if command -v gh >/dev/null 2>&1; then"
    print indent "  if ! gh auth status; then echo \"WARN: gh not authenticated\"; fi"
    print indent "else"
    print indent "  echo \"WARN: gh not installed\""
    print indent "fi"
    next
  }

  print line
}
END { flush_seq() }
' "$WF" > "$tmp" && mv "$tmp" "$WF"

echo "[patch] SC2015/SC2129 appliqué à $WF"

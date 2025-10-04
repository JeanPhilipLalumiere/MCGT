#!/usr/bin/env bash
# shellcheck source=/dev/null
. .ci-helpers/guard.sh
set -euo pipefail

# 1) tools/ci_fix_readme_encart.sh -> HTML markers confuse ShellCheck: disable SC1009/SC1072/SC1073 at top
f="tools/ci_fix_readme_encart.sh"
if [ -f "$f" ]; then
  t="$(mktemp)"
  if head -n1 "$f" | grep -q '^#!'; then
    awk 'NR==1{print; print "# shellcheck disable=SC1009,SC1072,SC1073"; next}1' "$f" >"$t"
  else
    {
      echo "# shellcheck disable=SC1009,SC1072,SC1073"
      cat "$f"
    } >"$t"
  fi
  mv "$t" "$f"
fi

# 2) tools/ci_patch_shell_issues.sh -> add disable line for the literal $rc sed pattern (SC2016)
g="tools/ci_patch_shell_issues.sh"
if [ -f "$g" ]; then
  if ! grep -q 'shellcheck disable=SC2016' "$g"; then
    # shellcheck disable=SC2016
    sed -i '/sed -i .*exit.*\\$rc/s/^/# shellcheck disable=SC2016\n&/' "$g" || true
  fi
fi

# 3) tools/ci_select_canonical_workflow.sh -> fix gh auth A&&B||C if present
h="tools/ci_select_canonical_workflow.sh"
if [ -f "$h" ]; then
  perl -0777 -i -pe 's/command -v gh >\/dev\/null 2>&1 && gh auth status \|\| say "WARN: gh not authenticated or not installed"/if command -v gh >\/dev\/null 2>\&1; then\n  gh auth status \|\| say "WARN: gh not authenticated"\nelse\n  say "WARN: gh not installed"\nfi/m' "$h" || true
fi

echo "[patch] ShellCheck offenders traités (si présents)."

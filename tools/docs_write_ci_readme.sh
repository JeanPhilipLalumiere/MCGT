#!/usr/bin/env bash
# shellcheck source=/dev/null
. .ci-helpers/guard.sh
set -euo pipefail
mkdir -p docs
LOG=".ci-logs/docs_write_ci_readme-$(date +%Y%m%dT%H%M%S).log"
exec > >(stdbuf -oL -eL tee -a "$LOG") 2>&1
say() {
  date +"[%F %T] - "
  printf "%s\n" "$*"
}

say "Writing docs/CI.md"
cat >docs/CI.md <<'MD'
# CI — Sanity workflows

Workflows:
- sanity-main.yml : push + workflow_dispatch, produit artifact "sanity-diag" (.tgz contenant diag.json + diag.ts)
- sanity-echo.yml : workflow_dispatch simple (test)

How to trigger:
- Dispatch via gh:
  gh api repos/:owner/:repo/actions/workflows/sanity-main.yml/dispatches --method POST -f ref=main
- Fallback push:
  git commit --allow-empty -m "ci(sanity-main): retrigger $(date +%Y%m%dT%H%M%S)" --no-verify && git push
MD

say "Appending short CI section to README.md if not present"
grep -q "## CI" README.md 2>/dev/null || cat >>README.md <<'MD'

## CI

See docs/CI.md for workflow descriptions and trigger instructions.
MD

say "Done. Log: $LOG"

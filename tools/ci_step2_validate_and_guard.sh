#!/usr/bin/env bash
set -euo pipefail
STRICT_ORPHANS="${STRICT_ORPHANS:-0}"

ROOT="$(git rev-parse --show-toplevel)"
cd "$ROOT"

OUT_DIR=".ci-out"
mkdir -p "$OUT_DIR"
REPORT="$OUT_DIR/figures_guard_report.txt"
ALLOWLIST_FILE=".ci-config/figures_orphans_allowlist.txt"
: "${ALLOWLIST_FILE:-}"
: >"$REPORT"

# shellcheck disable=SC2329
err() { echo "ERROR: $*" | tee -a "$REPORT"; }
info() { echo "INFO:  $*" | tee -a "$REPORT"; }
fail=0

info "==> Scan des figures suivies par git"
mapfile -t FS < <(git ls-files 'zz-figures/**/*.png' 'zz-figures/**/*.jpg' 'zz-figures/**/*.jpeg' 'zz-figures/**/*.svg' 2>/dev/null | LC_ALL=C sort || true)
: "${FS[@]-}"

# Limite la recherche aux fichiers “source” (exclut artefacts/archives/baks/sha256sum/gitignore)
mapfile -t SEARCH < <(
  : "${SEARCH[@]-}"
  git ls-files |
    grep -Ev '^(\.ci-out|\.ci-logs|\.ci-archive)/' |
    grep -Ev '\.bak($|\.)' |
    grep -Ev 'manifest_publication\.sha256sum$' |
    grep -Ev '^\.gitignore$' |
    grep -Ev '^tools/ci_step4_guard_naming\.sh$'
)

exit "$fail"

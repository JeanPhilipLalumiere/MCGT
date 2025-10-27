# tools/ci_enable_pr_jobs_v3.sh
#!/usr/bin/env bash
set -euo pipefail

BRANCH="${1:-rewrite/main-20251026T134200}"
PRNUM="${2:-19}"

WFs=(
  ".github/workflows/pip-audit.yml"
  ".github/workflows/pdf.yml"
  ".github/workflows/guard-generated.yml"
  ".github/workflows/integrity.yml"
  ".github/workflows/quality-guards.yml"
)

printf "[INFO] Branch: %s • PR: #%s\n" "$BRANCH" "$PRNUM"

git checkout "$BRANCH" >/dev/null 2>&1 || { echo "[ERR ] Branch not found: $BRANCH"; exit 1; }

for f in "${WFs[@]}"; do
  if [ ! -f "$f" ]; then
    printf "[WARN] Missing workflow: %s\n" "$f"
    continue
  fi

  printf "[INFO] Ensuring triggers in %s\n" "$f"
  tmp="$(mktemp)"

  # 1) Ensure an `on:` block exists
  if ! grep -qE '^[[:space:]]*on:' "$f"; then
    {
      echo "on:"
      echo "  pull_request:"
      echo "  workflow_dispatch:"
      cat "$f"
    } > "$tmp"
    mv "$tmp" "$f"
    printf "[OK  ] added on: + pull_request + workflow_dispatch -> %s\n" "$f"
  fi

  # 2) Ensure pull_request is present
  if ! grep -qE '^[[:space:]]*pull_request:' "$f"; then
    tmp="$(mktemp)"
    awk '{print} /^on:/{print "  pull_request:"}' "$f" > "$tmp"
    mv "$tmp" "$f"
    printf "[OK  ] added pull_request -> %s\n" "$f"
  fi

  # 3) Ensure workflow_dispatch is present
  if ! grep -qE '^[[:space:]]*workflow_dispatch:' "$f"; then
    tmp="$(mktemp)"
    awk '{print} /^on:/{print "  workflow_dispatch:"}' "$f" > "$tmp"
    mv "$tmp" "$f"
    printf "[OK  ] added workflow_dispatch -> %s\n" "$f"
  fi

  # 4) Widen job-level "push-only" conditions to allow PR too
  before="$(sha1sum "$f" | awk '{print $1}')"
  perl -0777 -pe "
    s/(^\\s*if:\\s*.*?github\\.event_name\\s*==\\s*'push'[^\\n]*$)/\${1} || github.event_name == 'pull_request'/mg;
    s/(^\\s*if:\\s*.*?github\\.event_name\\s*==\\s*\"push\"[^\\n]*$)/\${1} || github.event_name == \"pull_request\"/mg;
  " -i "$f" || true
  after="$(sha1sum "$f" | awk '{print $1}')"
  if [ "$before" != "$after" ]; then
    printf "[OK  ] widened job if(push) -> push||pull_request : %s\n" "$f"
  else
    printf "[INFO] no job-level 'if: … == push' to widen in %s\n" "$f"
  fi

  # 5) Special case PDF: keep it **skipped** on PR and rewrite/* (but define a tiny job so workflow is not empty)
  if [[ "$f" == *"/pdf.yml" ]]; then
    if ! grep -qE 'build-pdf:' "$f"; then
      tmp="$(mktemp)"
      awk '
        {print}
        /^[[:space:]]*jobs:[[:space:]]*$/ && !printed{
          print "  build-pdf:"
          print "    if: github.event_name != '\''pull_request'\'' && !startsWith(github.ref, '\''refs/heads/rewrite/'\'')"
          print "    runs-on: ubuntu-latest"
          print "    steps:"
          print "      - run: echo \"PDF job guarded on PR/rewrite/*\""
          printed=1
        }
      ' "$f" > "$tmp"
      mv "$tmp" "$f"
      printf "[OK  ] injected guarded build-pdf job -> %s\n" "$f"
    fi
  fi
done

# Commit/push if there are changes
if ! git diff --quiet; then
  git add -A
  git commit -m "ci: enable PR jobs (push||pull_request); keep PDF skipped on PR/rewrite/*"
  git push -u origin "$BRANCH"
  printf "[OK  ] changes pushed\n"
else
  printf "[OK  ] no changes to push\n"
fi

# Nudge PR checks (empty commit) and dispatch
git commit --allow-empty -m "ci: nudge PR checks after job-level patches" || true
git push || true

printf "[INFO] dispatch selected workflows…\n"
gh workflow run .github/workflows/build-publish.yml -r "$BRANCH" || true
gh workflow run .github/workflows/ci-accel.yml       -r "$BRANCH" || true

printf "[NEXT] Check PR #%s checks (UI) or run: gh pr checks %s\n" "$PRNUM" "$PRNUM"

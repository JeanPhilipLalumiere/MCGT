#!/usr/bin/env bash
set -Eeuo pipefail
BR="${1:-release/zz-tools-0.3.1}"
NWO="$(gh repo view --json nameWithOwner -q .nameWithOwner)"
WF_PATH=".github/workflows/manifest-guard.yml"
echo "[INFO] REPO=$NWO WF=$WF_PATH BR=$BR"

num(){ [[ "$1" =~ ^[0-9]+$ ]]; }

get_latest(){
  gh api repos/$NWO/actions/workflows/manifest-guard.yml/runs \
    -F branch="$BR" -F per_page=1 \
    -q '.workflow_runs[0] | [.id, .created_at] | @tsv' 2>/dev/null || true
}

OLD_LINE="$(get_latest)"
OLD_ID="$(cut -f1 <<<"$OLD_LINE")"
echo "[INFO] OLD_RUN=${OLD_ID:-<none>}"

# Trigger (on: workflow_dispatch: {})
gh workflow run "$WF_PATH" --ref "$BR" >/dev/null || true

# Poll pour un NOUVEL ID
for i in {1..60}; do
  sleep 2
  NEW_LINE="$(get_latest)"
  NEW_ID="$(cut -f1 <<<"$NEW_LINE")"
  if num "${NEW_ID:-}"; then
    if [[ -z "${OLD_ID:-}" || "$NEW_ID" != "$OLD_ID" ]]; then
      echo "[INFO] NEW_RUN=$NEW_ID"
      exit 0
    fi
  fi
  echo "[WAIT] poll $i… (old=${OLD_ID:-Ø} new=${NEW_ID:-Ø})"
done

echo "[WARN] Nouveau run non observé."
exit 1

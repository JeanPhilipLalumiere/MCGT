#!/usr/bin/env bash
set -Eeuo pipefail
BR="${1:-release/zz-tools-0.3.1}"
NWO="$(gh repo view --json nameWithOwner -q .nameWithOwner)"
RID="$(gh run list --workflow=manifest-guard.yml --branch "$BR" --limit 1 --json databaseId,headSha -q '.[0].databaseId' || true)"
SHA="$(gh run list --workflow=manifest-guard.yml --branch "$BR" --limit 1 --json headSha -q '.[0].headSha' || true)"
echo "[INFO] RUN=$RID SHA=$SHA"
echo "----- CHECK RUNS (name / status / conclusion) -----"
gh api repos/$NWO/commits/$SHA/check-runs -q '.check_runs[] | [.name,.status,.conclusion] | @tsv'
echo "----- ACTIONS CONFIG ERRORS (if any) -----"
gh api repos/$NWO/commits/$SHA/check-runs -q '
  .check_runs[]
  | select(.app.slug=="github-actions")
  | {name, summary: .output.summary, text: .output.text}
'

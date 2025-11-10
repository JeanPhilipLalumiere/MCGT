#!/usr/bin/env bash
set -Eeuo pipefail
BRANCH="${1:-release/zz-tools-0.3.1}"
WF_BASENAME="manifest-guard.yml"
RID="$(gh run list --workflow="$WF_BASENAME" --branch "$BRANCH" --limit 1 --json databaseId -q '.[0].databaseId' || true)"
if [[ -z "$RID" ]]; then echo "[ERR] Aucun run trouvé"; exit 2; fi
OUT=".ci-out/manifest_guard_${RID}"
rm -rf "$OUT"; mkdir -p "$OUT"
gh run watch "$RID" --exit-status || true
# Jobs (peut être vide si échec de configuration)
if gh api "repos/$(gh repo view --json nameWithOwner -q .nameWithOwner)/actions/runs/$RID/jobs" -q '.jobs | length' | grep -q '^[1-9]'; then
  JID="$(gh api repos/$(gh repo view --json nameWithOwner -q .nameWithOwner)/actions/runs/"$RID"/jobs -q '.jobs[0].id')"
  gh run view "$RID" --job "$JID" --log > "$OUT/job.log" || true
  sed -n 's/.*::error::\(.*\)$/\1/p' "$OUT/job.log" > "$OUT/errors.txt" || true
  tail -n 40 "$OUT/job.log" > "$OUT/tail40.txt" || true
else
  echo "[WARN] Aucun job présent → on récupère les annotations de configuration."
  gh api repos/$(gh repo view --json nameWithOwner -q .nameWithOwner)/actions/runs/"$RID"/annotations > "$OUT/annotations.json" || true
fi
gh run download "$RID" -n "manifest-guard-$RID" -D "$OUT" || true
if [[ -f "$OUT/diag_report.json" ]]; then
  (jq . "$OUT/diag_report.json" 2>/dev/null || cat "$OUT/diag_report.json") | sed 's/^/[diag]/'
fi
echo "[INFO] OUT=$OUT"

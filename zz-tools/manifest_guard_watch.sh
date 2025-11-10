#!/usr/bin/env bash
set -Eeuo pipefail
BR="${1:-release/zz-tools-0.3.1}"
OUT=".ci-out"; mkdir -p "$OUT"
RID="$(gh run list --workflow=manifest-guard.yml --branch "$BR" --limit 1 --json databaseId -q '.[0].databaseId')"
[ -z "$RID" ] && echo "[ERR] aucun run trouvé pour $BR" && exit 2
gh run watch "$RID" --exit-status || true
NWO="$(gh repo view --json nameWithOwner -q .nameWithOwner)"
JID="$(gh api repos/$NWO/actions/runs/"$RID"/jobs -q '.jobs[0].id' 2>/dev/null || true)"
if [ -n "$JID" ]; then
  gh run view "$RID" --job "$JID" --log | tee "$OUT/manifest_guard_${RID}_${JID}.log" >/dev/null
  sed -n 's/.*::error::\(.*\)$/\1/p' "$OUT/manifest_guard_${RID}_${JID}.log" \
    | tee "$OUT/manifest_guard_${RID}_${JID}_ERRORS.txt"
  tail -n 40 "$OUT/manifest_guard_${RID}_${JID}.log"
else
  gh run view "$RID" \
    --json name,displayTitle,status,conclusion,event,headBranch,headSha,createdAt,updatedAt,url \
    -q '"name=\(.name) | title=\(.displayTitle) | status=\(.status) | conclusion=\(.conclusion) | event=\(.event) | branch=\(.headBranch) | sha=\(.headSha) | created=\(.createdAt) | updated=\(.updatedAt) | url=\(.url)"'
fi

#!/usr/bin/env bash
set -euo pipefail

# Usage:
#   ./mcgt_collect_pr44_diagnostics.sh <branch-or-pr-branch>
# Example:
#   ./mcgt_collect_pr44_diagnostics.sh fix/audit-on-main-20251102T173122Z

BRANCH="${1:-fix/audit-on-main-20251102T173122Z}"
TS="$(date -u +%Y%m%dT%H%M%SZ)"
OUTDIR="/tmp/mcgt_pr44_diagnostics_${TS}"
mkdir -p "$OUTDIR"

echo "[INFO] Branch: $BRANCH"
echo "[INFO] Output dir: $OUTDIR"

# 1) collect run ids with conclusion != success (failure, cancelled, timed_out, etc.)
echo "[STEP] Lister runs en échec pour la branche..."
RUNS_JSON="$(mktemp)"
gh run list --branch "$BRANCH" --limit 200 --json databaseId,headSha,displayTitle,status,conclusion,createdAt > "$RUNS_JSON"

jq -r '.[] | select(.conclusion != "success") | "\(.databaseId) \t\(.conclusion) \t\(.createdAt) \t\(.displayTitle) \t\(.headSha)"' "$RUNS_JSON" \
  > "$OUTDIR"/failed_runs_list.txt || true

echo "[INFO] Échec / non-success runs sauvegardés dans: $OUTDIR/failed_runs_list.txt"
echo

# 2) For each failed run, make a subdir, download logs and artifacts
echo "[STEP] Téléchargement des logs et artifacts..."
mkdir -p "$OUTDIR/runs"
echo "RunID | conclusion | date | title | headSha" > "$OUTDIR/index.txt"

while IFS=$'\t' read -r runid concl created title headsha; do
  runid="$(echo "$runid" | tr -d '[:space:]')"
  if [[ -z "$runid" ]]; then
    continue
  fi
  rdir="$OUTDIR/runs/$runid"
  mkdir -p "$rdir"

  echo "[RUN] $runid  ($concl) - $title"
  echo "$runid | $concl | $created | $title | $headsha" >> "$OUTDIR/index.txt"

  # 2a) logs (failed steps + full)
  gh run view "$runid" --log-failed > "$rdir/log-failed.txt" 2>&1 || true
  gh run view "$runid" --log > "$rdir/log-full.txt" 2>&1 || true

  # 2b) download artifacts for this run (if any)
  echo "[ARTIFACTS] Listing artifacts for run $runid..."
  # use the run's API to find artifacts -> fallback stable
  ARTIFACTS_JSON="$(mktemp)"
  gh api repos/JeanPhilipLalumiere/MCGT/actions/runs/"$runid"/artifacts --jq '.artifacts' > "$ARTIFACTS_JSON" 2>/dev/null || echo "[]" > "$ARTIFACTS_JSON"
  if [[ "$(jq 'length' "$ARTIFACTS_JSON")" -gt 0 ]]; then
    jq -r '.[] | "\(.id) \t\(.name) \t\(.size_in_bytes)"' "$ARTIFACTS_JSON" > "$rdir/artifacts_list.txt"
    while IFS=$'\t' read -r aid aname asz; do
      safe_name="$(echo "$aname" | tr ' /' '__')"
      echo "[DOWNLOAD] artifact $aid : $aname  ($asz bytes)"
      # gh run download accepts run-id as first arg
      # use a temp dir for extraction to avoid clobber
      mkdir -p "$rdir/artifacts"
      # try download by run id + name pattern
      gh run download "$runid" --name "$aname" --dir "$rdir/artifacts" 2>&1 || {
        # fallback: attempt download by artifacts API zip (gh api)
        zipfile="$rdir/artifacts/artifact_${aid}.zip"
        echo "[FALLBACK] downloading artifact zip to $zipfile"
        gh api repos/JeanPhilipLalumiere/MCGT/actions/artifacts/"$aid"/zip --output "$zipfile" 2>/dev/null || true
        if [[ -f "$zipfile" ]]; then
          unzip -o "$zipfile" -d "$rdir/artifacts/$safe_name" >/dev/null 2>&1 || true
        fi
      }
    done < "$rdir/artifacts_list.txt"
  else
    echo "[ARTIFACTS] Aucun artifact pour run $runid" > "$rdir/artifacts_list.txt"
  fi

  # small sleep to be polite with API rate limits
  sleep 0.2
done < "$OUTDIR/failed_runs_list.txt"

echo "[DONE] Inventaire créé: $OUTDIR/index.txt"
echo "  - runs dir: $OUTDIR/runs"
echo "  - failed list: $OUTDIR/failed_runs_list.txt"
echo "  - index: $OUTDIR/index.txt"
echo
echo "[NEXT] Pour inspecter un run particulier:"
echo "  less $OUTDIR/runs/<run-id>/log-failed.txt"
echo "  less $OUTDIR/runs/<run-id>/log-full.txt"
echo "  ls -la $OUTDIR/runs/<run-id>/artifacts"

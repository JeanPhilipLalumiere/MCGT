#!/usr/bin/env bash
# Récupère logs + artefact diag_report.json d'un run "manifest-guard"
# Usage:
#   tools/fetch_guard_artifact.sh [--branch BR] [--workflow FILE] [--job NAME] [--out DIR]
#                                 [--rid RUN_ID]
# Exemples:
#   tools/fetch_guard_artifact.sh --branch release/zz-tools-0.3.1
#   tools/fetch_guard_artifact.sh --rid 19246843387
set -Eeuo pipefail

BRANCH="release/zz-tools-0.3.1"
WORKFLOW=".github/workflows/manifest-guard.yml"
JOB_NAME="guard"
OUT_DIR=""
RID=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    --branch)   BRANCH="$2"; shift 2;;
    --workflow) WORKFLOW="$2"; shift 2;;
    --job)      JOB_NAME="$2"; shift 2;;
    --out)      OUT_DIR="$2"; shift 2;;
    --rid)      RID="$2"; shift 2;;
    -h|--help)
      echo "Usage: $0 [--branch BR] [--workflow FILE] [--job NAME] [--out DIR] [--rid RUN_ID]"
      exit 0;;
    *) echo "Arg inconnu: $1" >&2; exit 2;;
  esac
done

command -v gh >/dev/null || { echo "[ERR] gh CLI manquant"; exit 127; }

# Résout NWO (owner/repo)
NWO="$(gh repo view --json nameWithOwner -q .nameWithOwner)"

# Résout l'ID de run si non fourni
if [[ -z "${RID}" ]]; then
  # NB: le --workflow accepte soit le nom (manifest-guard.yml) soit le path relatif
  WF_BASENAME="$(basename "$WORKFLOW")"
  RID="$(gh run list --workflow="$WF_BASENAME" --branch "$BRANCH" --limit 1 \
        --json databaseId -q '.[0].databaseId')"
  if [[ -z "$RID" ]]; then
    echo "[ERR] Aucun run trouvé pour workflow=$WF_BASENAME branch=$BRANCH" >&2
    exit 1
  fi
fi

# Attend la fin du run (n'échoue pas si failure — on veut les logs)
gh run watch "$RID" --exit-status || true

# Récupération des jobs
JOBS_JSON="$(gh api "repos/$NWO/actions/runs/$RID/jobs")" || { echo "[ERR] impossible de lister les jobs"; exit 1; }

# Sélection du job (priorité au nom JOB_NAME, sinon premier)
JID="$(printf "%s" "$JOBS_JSON" | gh api --input - -X GET -q ".jobs[] | select(.name==\"$JOB_NAME\") | .id" 2>/dev/null || true)"
if [[ -z "$JID" ]]; then
  JID="$(printf "%s" "$JOBS_JSON" | gh api --input - -X GET -q '.jobs[0].id' 2>/dev/null || true)"
fi
[[ -n "$JID" ]] || { echo "[ERR] Aucun job trouvé dans le run $RID"; exit 1; }

# OUT unique par run+job (évite collisions)
TS="$(date -u +%Y%m%dT%H%M%SZ)"
OUT="${OUT_DIR:-.ci-out/manifest_guard_${RID}_${JID}_${TS}}"
rm -rf "$OUT"; mkdir -p "$OUT"

echo "[INFO] RUN=$RID JOB=$JID OUT=$OUT"

# Log complet
gh run view "$RID" --job "$JID" --log | tee "$OUT/job.log" >/dev/null

# Erreurs normalisées + tail
sed -n 's/.*::error::\(.*\)$/\1/p' "$OUT/job.log" | tee "$OUT/errors.txt" >/dev/null
tail -n 40 "$OUT/job.log" > "$OUT/tail40.txt"

# Télécharge l’artefact nommé "manifest-guard-<run_id>" (créé par le workflow)
if ! gh run download "$RID" -n "manifest-guard-$RID" -D "$OUT"; then
  echo "[WARN] Artefact 'manifest-guard-$RID' introuvable (workflow a-t-il step upload ?)"
fi

# Affiche le diag si présent
if [[ -f "$OUT/diag_report.json" ]]; then
  (jq . "$OUT/diag_report.json" 2>/dev/null || cat "$OUT/diag_report.json") | sed 's/^/[diag]/'
else
  echo "[WARN] $OUT/diag_report.json absent"
fi

# Récapitulatif
echo "[INFO] Logs:     $OUT/job.log"
echo "[INFO] Errors:   $OUT/errors.txt"
echo "[INFO] Tail40:   $OUT/tail40.txt"
echo "[INFO] Diag JSON:$OUT/diag_report.json (si présent)"

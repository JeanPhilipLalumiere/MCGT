# tools/run_manifest_guard_stack.sh
#!/usr/bin/env bash
# Commit/push si delta, déclenche le workflow "manifest-guard", récupère logs + artefact.
# Garde-fou : la fenêtre ne se ferme pas, même en cas d’erreur.

set -Eeuo pipefail

BR="${BR:-release/zz-tools-0.3.1}"
WF_NAME="${WF_NAME:-manifest-guard}"
WF_PATH="${WF_PATH:-.github/workflows/manifest-guard.yml}"
OUT_BASE=".ci-out"

pause() {
  local msg="${1:-[FIN] Appuie sur Entrée pour quitter...}"
  if [[ -t 0 ]]; then read -rp "$msg" _ || true; else echo "$msg"; sleep 5; fi
}
trap 'code=$?; echo; echo "[ERREUR] code=$code"; pause; exit $code' ERR
trap 'pause' EXIT

chmod +x zz-tools/guard_runner.py zz-tools/manifest_postprocess.py || true
mkdir -p "$OUT_BASE"

if ! git diff --quiet -- "$WF_PATH" zz-tools/guard_runner.py zz-tools/manifest_postprocess.py; then
  echo "[INFO] Modifications détectées → commit/push"
  git add "$WF_PATH" zz-tools/guard_runner.py zz-tools/manifest_postprocess.py
  git commit -m "ci(guard): restore workflow_dispatch + guard_runner + postprocess"
  git push
else
  echo "[NOTE] Aucun delta sur les fichiers guard → pas de commit."
fi

echo "[CI] Trigger '$WF_NAME' (par nom)…"
if ! gh workflow run "$WF_NAME" --ref "$BR"; then
  echo "[WARN] Échec par nom. Trigger par chemin: $WF_PATH…"
  gh workflow run "$WF_PATH" --ref "$BR"
fi

RID=""
for _ in {1..12}; do
  RID="$(gh run list --workflow "$WF_NAME" --branch "$BR" --limit 1 --json databaseId -q '.[0].databaseId' 2>/dev/null || true)"
  [[ -z "$RID" ]] && RID="$(gh run list --workflow "$(basename "$WF_PATH")" --branch "$BR" --limit 1 --json databaseId -q '.[0].databaseId' 2>/dev/null || true)"
  [[ -n "$RID" ]] && break
  sleep 2
done
[[ -z "$RID" ]] && { echo "[WARN] Impossible de récupérer le RUN ID."; exit 0; }

echo "[INFO] RUN=$RID — attente…"
gh run watch "$RID" --exit-status || true

OUTD="$OUT_BASE/manifest_guard_${RID}"
mkdir -p "$OUTD"

NWO="$(gh repo view --json nameWithOwner -q .nameWithOwner)"
gh api repos/"$NWO"/actions/runs/"$RID"/jobs -q '.jobs[] | [.id,.name,.status,.conclusion] | @tsv' | tee "$OUTD/jobs.tsv" || true
JID="$(gh api repos/"$NWO"/actions/runs/"$RID"/jobs -q '.jobs[0].id' 2>/dev/null || true)"
if [[ -n "$JID" ]]; then
  gh api repos/"$NWO"/actions/jobs/"$JID" -q '.steps[] | [.name,.status,.conclusion] | @tsv' | tee "$OUTD/steps.tsv" || true
  gh run view "$RID" --job "$JID" --log | tee "$OUTD/job.log" >/dev/null || true
  sed -n 's/.*::error::\(.*\)$/\1/p' "$OUTD/job.log" | tee "$OUTD/errors.txt" || true
fi

if gh run download "$RID" -n "manifest-guard-$RID" -D "$OUTD" 2>/dev/null; then
  :
else
  gh run download "$RID" -D "$OUTD" || true
fi

if [[ -f "$OUTD/diag_report.json" ]]; then
  echo "[diag] ---- diag_report.json ----"
  (jq . "$OUTD/diag_report.json" 2>/dev/null || cat "$OUTD/diag_report.json") | sed 's/^/[diag]/'
else
  echo "[WARN] diag_report.json introuvable dans $OUTD"
fi

echo "[OK] Fin d’exécution."

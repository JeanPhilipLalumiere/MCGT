#!/usr/bin/env bash
# round2_checkpoint_sanity.sh — Point d'étape Round-2 (lecture seule, rapports _tmp/)
set -euo pipefail

REPO_ROOT="$(git rev-parse --show-toplevel)"; cd "$REPO_ROOT"
mkdir -p _tmp _logs
TS="$(date -u +%Y%m%dT%H%M%SZ)"
LOG="_logs/round2_checkpoint_${TS}.log"
OUTDIR="_tmp/round2_checkpoint_${TS}"
mkdir -p "$OUTDIR"

say(){ echo -e "$*" | tee -a "$LOG"; }
finish(){ read -r -p $'Terminé. ENTER pour fermer…\n' _ </dev/tty || true; }
trap finish EXIT

say "[STEP] 1/6 — Branche & protection"
gh repo view --json nameWithOwner -q .nameWithOwner | tee -a "$LOG" || true

# Lecture robuste: tolère champs manquants (null) côté GitHub
if ! gh api repos/:owner/:repo/branches/main/protection > "${OUTDIR}/_prot_raw.json" 2>>"$LOG"; then
  say "[WARN] Impossible de lire la protection (auth/rate limit ?). On continue."
  printf '{"strict":false,"checks":[],"reviews":0,"conv":false}\n' \
    | tee "${OUTDIR}/protection.json" >/dev/null
else
  jq '{
        strict:  (.required_status_checks?.strict // false),
        checks:  ((.required_status_checks?.checks // []) | map(.context) // []),
        reviews: (.required_pull_request_reviews?.required_approving_review_count // 0),
        conv:    (.required_conversation_resolution?.enabled // false)
      }' "${OUTDIR}/_prot_raw.json" \
      | tee "${OUTDIR}/protection.json" | tee -a "$LOG"
fi

say "[STEP] 2/6 — Checks rapides sur main (dispatch + poll ≤60s)"
gh workflow run pypi-build.yml  --ref main >/dev/null 2>&1 || true
gh workflow run secret-scan.yml --ref main >/dev/null 2>&1 || true
for i in $(seq 1 12); do
  stat="$(gh run list --branch main --limit 20 2>/dev/null \
        | awk '/pypi-build|secret-scan/ {print $2}' | paste -sd, -)"
  say "[POLL $i] ${stat:-'(no runs yet)'}"
  ok=$(echo "${stat}" | grep -c success || true)
  [[ "$ok" -ge 2 ]] && break
  sleep 5
done

say "[STEP] 3/6 — Inventaire TODO/FIXME/SAFE_DELETE → ${OUTDIR}/todos.txt"
{ command -v rg >/dev/null && rg -n --hidden -S "TODO|FIXME|SAFE_DELETE" || \
  grep -RIn "TODO\|FIXME\|SAFE_DELETE" . 2>/dev/null; } \
  | sed 's/^\.\///' | tee "${OUTDIR}/todos.txt" >/dev/null

say "[STEP] 4/6 — Candidats attic/ → ${OUTDIR}/attic_candidates.txt"
{ find . -maxdepth 2 -type f -name "*.sh" ! -path "./tools/ci-helpers/*" ;
  find tools -maxdepth 2 -type f -name "*.tmp" -o -name "*_scratch.*" 2>/dev/null || true; } \
  | sed 's/^\.\///' | sort | tee "${OUTDIR}/attic_candidates.txt" >/dev/null

say "[STEP] 5/6 — Delta manifeste → ${OUTDIR}/manifest_delta.txt"
if [[ -f assets/zz-manifests/manifest_master.json ]]; then
  if jq -e '.' assets/zz-manifests/manifest_master.json >/dev/null 2>&1; then
    git diff -- assets/zz-manifests/manifest_master.json > "${OUTDIR}/manifest_delta.txt" || true
  else
    echo "(manifest non-JSON valide)" > "${OUTDIR}/manifest_delta.txt"
  fi
else
  echo "(absent)" > "${OUTDIR}/manifest_delta.txt"
fi

say "[STEP] 6/6 — Synthèse"
say "Rapports: ${OUTDIR}/protection.json, todos.txt, attic_candidates.txt, manifest_delta.txt"

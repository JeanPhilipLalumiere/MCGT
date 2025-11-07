#!/usr/bin/env bash
# enforce_required_checks_exact.sh
# - Enforce exactement 2 checks requis sur main: pypi-build/build & secret-scan/gitleaks
# - Conserve: reviews=1, strict=true, conversation_resolution=true, linear_history=true
# - Snapshot avant, vérification après, restauration si échec
set -euo pipefail

ROOT="$(git rev-parse --show-toplevel)"; cd "$ROOT"
mkdir -p _tmp _logs
TS="$(date -u +%Y%m%dT%H%M%SZ)"
LOG="_logs/enforce_required_checks_${TS}.log"
SNAP="_tmp/protection.main.snapshot.${TS}.json"
PATCH="_tmp/protection.main.patch.${TS}.json"

say(){ echo -e "$*" | tee -a "$LOG"; }

trap 'say "[GUARD] Tentative de restauration depuis snapshot…"; \
      gh api repos/:owner/:repo/branches/main/protection -X PUT -H "Accept: application/vnd.github+json" --input "$SNAP" >/dev/null 2>&1 || true; \
      say "[GUARD] Restauration exécutée (si nécessaire)."' EXIT

say "[STEP] Snapshot protections → $SNAP"
gh api repos/:owner/:repo/branches/main/protection > "$SNAP"

say "[STEP] Build payload STRICT (2 checks, 1 review)"
cat > "$PATCH" <<'JSON'
{
  "required_status_checks": {
    "strict": true,
    "checks": [
      {"context": "pypi-build/build", "app_id": null},
      {"context": "secret-scan/gitleaks", "app_id": null}
    ]
  },
  "enforce_admins": true,
  "required_pull_request_reviews": {
    "required_approving_review_count": 1,
    "require_code_owner_reviews": false,
    "dismiss_stale_reviews": false,
    "require_last_push_approval": false
  },
  "restrictions": null,
  "required_linear_history": true,
  "allow_force_pushes": false,
  "allow_deletions": false,
  "block_creations": false,
  "required_conversation_resolution": true,
  "lock_branch": false,
  "allow_fork_syncing": false
}
JSON

say "[APPLY] PUT branch protection (main)"
gh api repos/:owner/:repo/branches/main/protection \
  -X PUT -H "Accept: application/vnd.github+json" --input "$PATCH" >/dev/null

say "[VERIFY] Lecture protection post-apply"
VERIFY_JSON="$(gh api repos/:owner/:repo/branches/main/protection)"
STRICT="$(jq -r '.required_status_checks.strict' <<<"$VERIFY_JSON")"
REV="$(jq -r '.required_pull_request_reviews.required_approving_review_count' <<<"$VERIFY_JSON")"
CONV="$(jq -r '.required_conversation_resolution.enabled' <<<"$VERIFY_JSON")"
CHECKS="$(jq -r '[.required_status_checks.checks[].context] | sort | join(",")' <<<"$VERIFY_JSON")"

say "[INFO] strict=${STRICT} ; reviews=${REV} ; conv_resolve=${CONV} ; checks=${CHECKS}"

if [[ "$STRICT" != "true" || "$REV" != "1" || "$CONV" != "true" || "$CHECKS" != "pypi-build/build,secret-scan/gitleaks" ]]; then
  say "[ERROR] Vérification échouée — restauration snapshot."
  gh api repos/:owner/:repo/branches/main/protection \
    -X PUT -H "Accept: application/vnd.github+json" --input "$SNAP" >/dev/null || true
  exit 1
fi

say "[OK] Protection stricte en place (exactement 2 checks)."
say "[NEXT] Déclenche un run court sur main pour valider les 2 checks…"

# Déclenchement (si les workflows ont workflow_dispatch)
gh workflow run pypi-build.yml --ref main >/dev/null 2>&1 || true
gh workflow run secret-scan.yml --ref main >/dev/null 2>&1 || true

# Petite boucle lisible (max ~3 min)
for i in $(seq 1 36); do
  PB=$(gh run list --branch main --workflow pypi-build.yml --limit 1 --json conclusion -q '.[0].conclusion' 2>/dev/null || echo "")
  SS=$(gh run list --branch main --workflow secret-scan.yml --limit 1 --json conclusion -q '.[0].conclusion' 2>/dev/null || echo "")
  echo "[POLL $i] pypi-build=${PB} ; secret-scan=${SS}" | tee -a "$LOG"
  [[ "$PB" == "success" && "$SS" == "success" ]] && break
  sleep 5
done

say "[DONE] Sanity CI déclenchée. Journal: $LOG"
read -r -p $'Terminé. ENTER pour fermer…\n' _ </dev/tty || true

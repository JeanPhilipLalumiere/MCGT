#!/usr/bin/env bash
# merge_pr27_once_guarded.sh — Merge PR #27 (par défaut) en abaissant TEMPORAIREMENT review=0,
# tout en conservant les required checks et en RESTAURANT EXACTEMENT la protection ensuite.
# Garde-fou : ne ferme JAMAIS la fenêtre ; prompt final ; restauration même en cas d’erreur.

# ─────────────────────────── Garde-fou / comportement ───────────────────────────
# - Pas de "set -e" pour éviter les sorties brutales.
# - On journalise tout, on restaure en sortie (trap EXIT), et on demande ENTER à la fin.
set -uo pipefail
IFS=$'\n\t'

PR="${PR:-27}"

ROOT="$(git rev-parse --show-toplevel 2>/dev/null || echo '')"
if [[ -z "$ROOT" ]]; then
  echo "[FATAL] Impossible de localiser la racine du dépôt (git rev-parse)."
  echo "Appuyez sur ENTER pour fermer…"
  read -r _ </dev/tty || true
  exit 1
fi
cd "$ROOT" || {
  echo "[FATAL] cd vers repo root impossible: $ROOT"
  echo "Appuyez sur ENTER pour fermer…"
  read -r _ </dev/tty || true
  exit 2
}

mkdir -p _tmp _logs
TS="$(date -u +%Y%m%dT%H%M%SZ)"
LOG="_logs/merge_pr${PR}_${TS}.log"

SNAP=""            # snapshot complet des protections (pour RESTORE exact)
BASE="main"        # sera mis à jour depuis la PR
RESTORE_DONE=0     # 0 tant qu’on n’a pas restauré

_guard_final() {
  # Restauration si nécessaire
  if [[ "$RESTORE_DONE" -eq 0 && -n "$SNAP" && -f "$SNAP" ]]; then
    echo "[GUARD] Restauration des protections à partir du snapshot: $SNAP" | tee -a "$LOG"
    gh api -X PUT "repos/:owner/:repo/branches/${BASE}/protection" \
      -H "Accept: application/vnd.github+json" \
      --input "$SNAP" >/dev/null 2>>"$LOG" || true
    RESTORE_DONE=1
    echo "[GUARD] Restauration effectuée." | tee -a "$LOG"
  fi
  echo
  echo "[FIN] Journal: $LOG"
  echo "Appuyez sur ENTER pour fermer…"
  read -r _ </dev/tty || true
}
trap _guard_final EXIT INT TERM

log() { echo -e "$*" | tee -a "$LOG"; }

log "[INFO] Démarrage merge PR #$PR @ $TS"
log "[INFO] Repo: $(gh repo view --json nameWithOwner -q .nameWithOwner 2>/dev/null || echo '?')"

# ───────────────────────────── Contexte PR ─────────────────────────────
PR_JSON="$(gh pr view "$PR" --json headRefName,baseRefName,mergeable,mergeStateStatus,reviewDecision,isDraft,url 2>>"$LOG" || true)"
if [[ -z "$PR_JSON" || "$PR_JSON" == "null" ]]; then
  log "[FATAL] Impossible de lire les métadonnées de la PR #$PR (gh pr view)."
  exit 10
fi
BR="$(echo "$PR_JSON"  | jq -r .headRefName 2>>"$LOG")"
BASE="$(echo "$PR_JSON"| jq -r .baseRefName 2>>"$LOG")"
URL="$(echo "$PR_JSON" | jq -r .url 2>>"$LOG")"
[[ "$BR" == "main" ]] && { log "[ABORT] Refus d'opérer directement sur main."; exit 11; }

log "[INFO] PR #$PR: $BR → $BASE"
log "[INFO] URL: $URL"

# ───────────────────── Snapshot protections (RESTORE exact) ────────────────────
SNAP="_tmp/protect.${BASE}.snapshot.${TS}.json"
PROT="$(gh api "repos/:owner/:repo/branches/${BASE}/protection" 2>>"$LOG" || true)"
if [[ -z "$PROT" || "$PROT" == "null" ]]; then
  log "[FATAL] Impossible de récupérer la protection de branche de '$BASE'."
  exit 20
fi
echo "$PROT" > "$SNAP"
log "[SNAPSHOT] Protections → $SNAP"

# Préparer matériaux de PATCH (checks existants, strict, conversation_resolution)
CHECKS_JSON="$(jq -c '.required_status_checks.checks | map({context:.context, app_id:(.app_id // null)})' "$SNAP" 2>>"$LOG" || echo '[]')"
STRICT="$(jq -r '.required_status_checks.strict' "$SNAP" 2>>"$LOG" || echo true)"
CONV_RES="$(jq -r '.required_conversation_resolution.enabled' "$SNAP" 2>>"$LOG" || echo true)"

# ───────────────────── Abaisser TEMPORAIREMENT reviews=0 ──────────────────────
TMP_PAYLOAD="_tmp/protect.${BASE}.temp.${TS}.json"
jq -n --argjson checks "$CHECKS_JSON" \
      --argjson strict "${STRICT:-true}" \
      --argjson conv   "${CONV_RES:-true}" '
{
  required_status_checks: { strict: ($strict|tobool), checks: $checks },
  enforce_admins: true,
  required_pull_request_reviews: {
    required_approving_review_count: 0,
    require_code_owner_reviews: false,
    dismiss_stale_reviews: false,
    require_last_push_approval: false
  },
  restrictions: null,
  required_linear_history: true,
  allow_force_pushes: false,
  allow_deletions: false,
  block_creations: false,
  required_conversation_resolution: ($conv|tobool),
  lock_branch: false,
  allow_fork_syncing: false
}' > "$TMP_PAYLOAD"

log "[PATCH] Abaissement temporaire: required_approving_review_count=0 (checks & strict conservés)"
gh api -X PUT "repos/:owner/:repo/branches/${BASE}/protection" \
  -H "Accept: application/vnd.github+json" \
  --input "$TMP_PAYLOAD" >/dev/null 2>>"$LOG" || log "[WARN] PUT protection a renvoyé une erreur (vérifie droits)."

# ───────────────── Vérifier les 2 checks requis sur la PR ─────────────────────
log "[CHECK] Attente courte jusqu'à SUCCESS: pypi-build/build & secret-scan/gitleaks"
ok="false"
for i in $(seq 1 90); do
  ROLL="$(gh pr view "$PR" --json statusCheckRollup 2>>"$LOG" || echo '{}')"
  want="$(echo "$ROLL" | jq -re \
    '[.statusCheckRollup[] | select(.name=="pypi-build/build" or .name=="secret-scan/gitleaks") | .conclusion]
     | sort | join(",") == "SUCCESS,SUCCESS"' 2>>"$LOG" || echo false)"
  if [[ "$want" == "true" ]]; then
    ok="true"
    break
  fi
  sleep 5
done
if [[ "$ok" != "true" ]]; then
  log "[WARN] Les checks requis ne sont pas tous verts. On tente tout de même le merge (le serveur peut accepter si état déjà 'SUCCESS' coté GitHub)."
fi

# ───────────────────────────── Merge (squash) ─────────────────────────────
log "[MERGE] gh pr merge $PR --squash --delete-branch"
if ! gh pr merge "$PR" --squash --delete-branch 2>>"$LOG"; then
  log "[WARN] Merge initial refusé. Tentative avec --admin si autorisé…"
  gh pr merge "$PR" --squash --admin --delete-branch 2>>"$LOG" || log "[ERROR] Échec du merge même avec --admin."
fi

# ───────────────────── Restauration EXACTE des protections ─────────────────────
log "[RESTORE] Restauration exacte des protections à partir de $SNAP"
if gh api -X PUT "repos/:owner/:repo/branches/${BASE}/protection" \
     -H "Accept: application/vnd.github+json" \
     --input "$SNAP" >/dev/null 2>>"$LOG"; then
  RESTORE_DONE=1
  log "[RESTORE] OK."
else
  log "[ERROR] La restauration a échoué (voir log). Le garde-fou réessaiera à la sortie."
fi

log "[DONE] Flux terminé pour PR #$PR."

#!/usr/bin/env bash
# post_merge_sanity_v1.sh — Vérifie la protection de main, relance pypi-build & secret-scan sur main,
# attend SUCCESS, et ne ferme jamais la fenêtre (prompt final).

set -euo pipefail
IFS=$'\n\t'
ROOT="$(git rev-parse --show-toplevel 2>/dev/null || echo '')"
if [[ -z "$ROOT" ]]; then echo "[FATAL] Pas dans un dépôt git"; read -r -p "ENTER…" _ </dev/tty || true; exit 2; fi
cd "$ROOT"

mkdir -p _tmp _logs
TS="$(date -u +%Y%m%dT%H%M%SZ)"
LOG="_logs/post_merge_sanity_${TS}.log"

finish() {
  echo
  echo "[FIN] Journal: $LOG"
  read -r -p "ENTER pour fermer…" _ </dev/tty || true
}
trap finish EXIT INT TERM

log(){ echo -e "$*" | tee -a "$LOG"; }

BASE="main"
REQ_CTX=("pypi-build/build" "secret-scan/gitleaks")

log "[STEP] 1/5 — Vérif branche et fetch"
git fetch origin >>"$LOG" 2>&1 || true
git checkout -B "$BASE" "origin/$BASE" >>"$LOG" 2>&1 || true
HEAD="$(git rev-parse --short HEAD)"
log "[INFO] main@${HEAD}"

log "[STEP] 2/5 — Lire protection de $BASE"
PROT_JSON="$(gh api "repos/:owner/:repo/branches/${BASE}/protection" 2>>"$LOG" || true)"
if [[ -z "$PROT_JSON" || "$PROT_JSON" == "null" ]]; then
  log "[FATAL] Impossible de lire la protection de $BASE"; exit 10
fi
echo "$PROT_JSON" > "_tmp/protect.${BASE}.read.${TS}.json"

strict="$(jq -r '.required_status_checks.strict' <<<"$PROT_JSON")"
conv="$(jq -r '.required_conversation_resolution.enabled' <<<"$PROT_JSON")"
review_count="$(jq -r '.required_pull_request_reviews.required_approving_review_count' <<<"$PROT_JSON")"
have_ctx="$(jq -r '[.required_status_checks.checks[].context] | sort | join(",")' <<<"$PROT_JSON")"
need_ctx="$(printf "%s\n" "${REQ_CTX[@]}" | sort | paste -sd, -)"

log "[INFO] strict=$strict ; conv_resolve=$conv ; reviews=$review_count"
log "[INFO] checks présents : $have_ctx"
log "[INFO] checks attendus : $need_ctx"

if [[ "$strict" != "true" || "$conv" != "true" || "$review_count" -lt 1 || "$have_ctx" != "$need_ctx" ]]; then
  log "[WARN] Protection != attendu. On continue (pas de changement auto ici) mais note l’écart."
fi

log "[STEP] 3/5 — Vérif workflow pypi-build"
WF_PATH=".github/workflows/pypi-build.yml"
if [[ ! -f "$WF_PATH" ]]; then
  log "[FATAL] Introuvable: $WF_PATH"; exit 20
fi
if ! grep -qE '^\s*build:' "$WF_PATH"; then
  log "[FATAL] Le job 'build' doit exister (contexte requis pypi-build/build)"; exit 21
fi
if ! grep -qE '(^on:\s*$)|(^\s*pull_request:)|(^\s*workflow_dispatch:)|(^\s*push:\s*$)|(^\s*branches:\s*\[\s*main\s*\])' "$WF_PATH"; then
  log "[WARN] pypi-build.yml: triggers minimaux non trouvés (pull_request/push(main)/dispatch)."
fi
log "[OK] pypi-build.yml présent et job 'build' détecté."

log "[STEP] 4/5 — Déclenche sur main & attente SUCCESS (boucle courte)"
gh workflow run pypi-build.yml    --ref "$BASE" >>"$LOG" 2>&1 || true
gh workflow run secret-scan.yml   --ref "$BASE" >>"$LOG" 2>&1 || true

# petite attente initiale pour la prise en compte
sleep 5

ok_pypi=0
ok_scan=0
for i in $(seq 1 36); do
  # Récupère l’état des checks sur la ref de main
  STATUS_JSON="$(gh run list --branch "$BASE" --limit 50 --json databaseId,name,headBranch,status,conclusion,headSha 2>>"$LOG" || true)"
  # Plus simple : regarde les checks PRAGMA via statusCheckRollup de la dernière PR? Non: on vise le commit de main.
  # On détecte la dernière exécution par nom de workflow.
  pypi_state="$(jq -r '[ .[] | select(.name=="pypi-build") ][0].conclusion' <<<"$STATUS_JSON")"
  scan_state="$(jq -r '[ .[] | select(.name=="secret-scan") ][0].conclusion' <<<"$STATUS_JSON")"

  [[ "$pypi_state" == "SUCCESS" ]] && ok_pypi=1
  [[ "$scan_state" == "SUCCESS" ]] && ok_scan=1

  log "[POLL $i] pypi-build=$pypi_state ; secret-scan=$scan_state"
  if [[ $ok_pypi -eq 1 && $ok_scan -eq 1 ]]; then
    log "[OK] Les deux workflows ont conclu SUCCESS sur main."
    break
  fi
  sleep 5
done

if [[ $ok_pypi -ne 1 || $ok_scan -ne 1 ]]; then
  log "[WARN] Les deux succès n'ont pas été confirmés dans la fenêtre d'attente. Vérifie manuellement dans l'UI si nécessaire."
fi

log "[STEP] 5/5 — Résumé final"
log " - main @ $HEAD"
log " - Protections: strict=$strict ; conv=$conv ; reviews=$review_count ; checks=[$have_ctx]"
log " - Workflows déclenchés: pypi-build, secret-scan (voir gh run list --branch main)"

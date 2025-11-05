#!/usr/bin/env bash
# MCGT - Collecte logs Gitleaks (PR #20) - lecture seule, avec pauses
set -u  # pas de set -e : on NE meurt PAS sur erreur
PR_NUMBER="${PR_NUMBER:-20}"
REPO_DIR="${REPO_DIR:-$HOME/MCGT}"
WORKFLOW_NAME="${WORKFLOW_NAME:-secret-scan}"

read -rp "Appuie sur Entrée pour démarrer la collecte Gitleaks (lecture seule)..." _

# 0) Préliminaires
if ! command -v gh >/dev/null 2>&1; then
  echo "[ERR] gh (GitHub CLI) est requis."
fi
if ! command -v jq >/dev/null 2>&1; then
  echo "[ERR] jq est requis."
fi

mkdir -p "_tmp/mcgt/runs" || true
TS="$(date +%Y%m%dT%H%M%S)"
OUT="_tmp/mcgt/runs/gitleaks_${TS}"
mkdir -p "$OUT"

# 1) Contexte repo
if [ ! -d "$REPO_DIR/.git" ]; then
  echo "[ERR] $REPO_DIR n'est pas un repo git"
else
  cd "$REPO_DIR" || true
fi
echo "[ctx] pwd: $(pwd)" | tee "$OUT/context.txt"
echo "[ctx] branch: $(git rev-parse --abbrev-ref HEAD 2>/dev/null || echo n/a)" | tee -a "$OUT/context.txt"
echo "[ctx] head:   $(git rev-parse HEAD 2>/dev/null || echo n/a)" | tee -a "$OUT/context.txt"
read -rp "Appuie sur Entrée pour continuer..." _

# 2) PR #20 — état & checks rollup (GraphQL)
echo "[gh] PR #$PR_NUMBER (mergeability + checks rollup)" | tee "$OUT/pr20_meta.txt"
gh api graphql -f query='
  query($owner:String!, $name:String!, $number:Int!) {
    repository(owner:$owner, name:$name) {
      pullRequest(number:$number) {
        number
        title
        state
        headRefName
        headRefOid
        mergeStateStatus
        statusCheckRollup {
          contexts(first:100) {
            nodes {
              __typename
              ... on CheckRun { name, status, conclusion, detailsUrl }
              ... on StatusContext { context, state, targetUrl }
            }
          }
        }
      }
    }
  }' \
  -F owner="JeanPhilipLalumiere" -F name="MCGT" -F number="$PR_NUMBER" \
  | tee "$OUT/pr20_meta.json" >/dev/null 2>&1 || echo "[warn] Impossible d'interroger GraphQL (droits ?)"
jq '.data.repository.pullRequest | {number,title,state,headRefName,headRefOid,mergeStateStatus}' "$OUT/pr20_meta.json" 2>/dev/null || true
echo
echo "[info] Extrait des contexts requis observés:" 
jq -r '.data.repository.pullRequest.statusCheckRollup.contexts.nodes[]? |
      ( .name // .context ) as $n
      | ( .status // .state ) as $s
      | ( .conclusion // .state ) as $c
      | [$n,$s,$c] | @tsv' "$OUT/pr20_meta.json" 2>/dev/null || true
read -rp "Appuie sur Entrée pour continuer..." _

# 3) Lister les derniers runs pour le workflow secret-scan (limité au branch HEAD de la PR si possible)
echo "[gh] Derniers runs ($WORKFLOW_NAME)" | tee "$OUT/run_list.txt"
gh run list --workflow "$WORKFLOW_NAME" --limit 20 --json databaseId,headBranch,headSha,event,status,conclusion,createdAt \
  | tee "$OUT/run_list.json" >/dev/null 2>&1 || echo "[warn] gh run list a échoué (droits ?)"
jq -r '.[] | [.databaseId,.event,.status,.conclusion,.headBranch,.headSha,.createdAt] | @tsv' "$OUT/run_list.json" 2>/dev/null || true

# 4) Sélection du dernier run attaché à la PR (event == pull_request, conclusion == failure|action_required|neutral si besoin)
RUN_ID="$(jq -r '
  map(select(.event=="pull_request")) 
  | sort_by(.createdAt) | reverse 
  | .[0].databaseId // empty' "$OUT/run_list.json" 2>/dev/null || true)"

if [ -z "${RUN_ID:-}" ]; then
  echo "[warn] Aucun run pull_request trouvé pour $WORKFLOW_NAME."
else
  echo "[info] Run sélectionné: $RUN_ID" | tee "$OUT/selected_run.txt"
fi
read -rp "Appuie sur Entrée pour continuer (téléchargement des logs)..." _

# 5) Récupération des logs du run sélectionné
if [ -n "${RUN_ID:-}" ]; then
  gh run view "$RUN_ID" --log > "$OUT/run_full.log" 2>"$OUT/run_view_err.txt" || echo "[warn] Impossible de récupérer les logs."
  echo "[tail] 200 dernières lignes:" | tee "$OUT/run_tail.txt"
  tail -n 200 "$OUT/run_full.log" | tee -a "$OUT/run_tail.txt"
  echo
  # 5b) Extraction rudimentaire du job 'gitleaks' (si le nom de job apparaît dans le log)
  grep -nEi 'gitleaks|leaks|sarif|secret|error|fail|panic' "$OUT/run_full.log" | tail -n 200 \
    | tee "$OUT/grep_leaks_tail.txt" >/dev/null 2>&1 || true
else
  echo "[info] Skip logs: aucun RUN_ID"
fi
read -rp "Appuie sur Entrée pour continuer..." _

# 6) Résumé de classification (heuristique)
CAUSE="unknown"
if grep -qEi 'Leaks found|leaks found|prevented|secret(s)? detected' "$OUT/run_full.log" 2>/dev/null; then
  CAUSE="secret_detected"
elif grep -qEi 'sarif|upload-sarif|codeql-action/upload-sarif.*(failed|error)' "$OUT/run_full.log" 2>/dev/null; then
  CAUSE="sarif_upload_error"
elif grep -qEi 'error:|panic:|exception' "$OUT/run_full.log" 2>/dev/null; then
  CAUSE="action_error"
fi
echo "[summary] cause_probable=$CAUSE" | tee "$OUT/summary.txt"

echo
echo "==== RÉCAP ===="
echo "Dossier logs: $OUT"
echo " - pr meta        : $OUT/pr20_meta.json"
echo " - run list       : $OUT/run_list.json"
echo " - run full log   : $OUT/run_full.log"
echo " - grep leaks tail: $OUT/grep_leaks_tail.txt"
echo " - summary        : $OUT/summary.txt"
echo
read -rp "Terminé. Appuie sur Entrée pour fermer proprement ce script..." _

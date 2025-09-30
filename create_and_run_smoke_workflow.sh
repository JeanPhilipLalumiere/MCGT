#!/usr/bin/env bash
# Crée un workflow minimal INDEPENDANT (.github/workflows/smoke_min.yml),
# push + dispatch, poll RUN_ID, affiche logs. Fenêtre OUVERTE.

set -u -o pipefail

FIXBR="ci/testpypi-workflow-rmid"
WF_SMOKE=".github/workflows/smoke_min.yml"
WF_ID_FALLBACK=""

log(){ printf "\n== %s ==\n" "$*"; }
warn(){ printf "WARN: %s\n" "$*" >&2; }

final_loop(){
  echo
  echo "==============================================================="
  echo " Fin (smoke) — fenêtre OUVERTE. [Entrée]=quitter  [sh]=shell "
  echo "==============================================================="
  while true; do read -r -p "> " a || true; case "${a:-}" in
    sh) /bin/bash -i;;
    "") break;;
    *) echo "?";;
  esac; done
}

repo(){
  local r url
  r="$(git remote 2>/dev/null | head -n1 || true)"
  url="$(git remote get-url "${r:-origin}" 2>/dev/null || true)"
  if [[ "$url" =~ github.com[:/]+([^/]+)/([^/.]+) ]]; then
    echo "${BASH_REMATCH[1]}/${BASH_REMATCH[2]}"
  else
    echo "JeanPhilipLalumiere/MCGT"
  fi
}
GH_REPO="$(repo)"

need(){ command -v "$1" >/dev/null 2>&1 || { echo "ERROR: $1 requis"; final_loop; exit 0; }; }
need gh; need jq

log "Écrit le workflow minimal indépendant: $WF_SMOKE"
mkdir -p .github/workflows
cat > "$WF_SMOKE" <<'YAML'
name: smoke_min

on:
  workflow_dispatch:
  push:
    branches: [ci/testpypi-workflow-rmid]
    paths: [.ci_poke/**]

jobs:
  smoke:
    runs-on: ubuntu-latest
    if: github.ref == 'refs/heads/ci/testpypi-workflow-rmid' || github.event_name == 'workflow_dispatch'
    steps:
      - uses: actions/checkout@v4
      - name: Print env
        run: |
          set -x
          echo "ref=$GITHUB_REF"
          echo "event=$GITHUB_EVENT_NAME"
          echo "sha=$GITHUB_SHA"
          echo "run_id=$GITHUB_RUN_ID"
          uname -a
          python3 -V || true
          ls -la
YAML

log "Assurer branche fixe + commit/push"
git checkout -B "$FIXBR" >/dev/null 2>&1 || true
mkdir -p .ci_poke; echo "poke $(date -u +%FT%TZ)" > ".ci_poke/smoke_$$.txt"
git add "$WF_SMOKE" .ci_poke
git -c user.name="Local CI" -c user.email="local@ci" -c commit.gpgSign=false \
    commit -m "ci: add smoke_min workflow" --no-verify >/dev/null 2>&1 || true
git push -u origin "$FIXBR" >/dev/null 2>&1 || true

log "Dispatch"
gh workflow run "$WF_SMOKE" --ref "$FIXBR" -R "$GH_REPO" >/dev/null 2>&1 || true

log "Poll RUN_ID"
WFID="$(gh workflow view "$WF_SMOKE" -R "$GH_REPO" --json databaseId -q .databaseId 2>/dev/null || echo "")"
HEAD_SHA="$(git rev-parse HEAD)"
for i in $(seq 1 72); do
  rid="$(gh run list ${WFID:+--workflow "$WFID"} -R "$GH_REPO" --limit 50 \
    --json databaseId,headSha,headBranch,createdAt,status,conclusion,name \
    | jq -r --arg sha "$HEAD_SHA" --arg br "$FIXBR" '.[]|select(.headSha==$sha and .headBranch==$br and (.name|test("smoke_min";"i")))|.databaseId' | head -n1)"
  if [ -n "$rid" ]; then RUN_ID="$rid"; echo "RUN_ID: $RUN_ID"; break; fi
  printf "[%02d/72] wait…\n" "$i"; sleep 5
done

if [ -n "${RUN_ID:-}" ]; then
  log "Run info"; gh run view "$RUN_ID" -R "$GH_REPO" || true
  log "Logs";     gh run view "$RUN_ID" -R "$GH_REPO" --log || true
else
  warn "RUN_ID introuvable (poll timeout)"; gh run list -R "$GH_REPO" --limit 20 || true
fi

final_loop

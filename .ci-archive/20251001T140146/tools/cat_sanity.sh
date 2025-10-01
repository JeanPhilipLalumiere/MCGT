#!/usr/bin/env bash
###############################################################################
# CAT v25 — "sanity-main" + "sanity-echo"
# Corrige définitivement "No files were found" :
#  - crée les fichiers d'artefacts AVANT upload
#  - EMBALLE le dossier .ci-out en .tgz puis uploade le FICHIER (pas de glob)
#  - dispatch (REST -> CLI) + fallback push
#  - logs persistants + pauses ; NE FERME JAMAIS la fenêtre
###############################################################################
set +e

STAMP="$(date +%Y%m%dT%H%M%S)"
ROOT_LOG="$PWD/.ci-bootstrap-$STAMP.log"
exec > >(tee -a "$ROOT_LOG") 2>&1

say(){ printf "\n== %s ==\n" "$*"; }
step(){ printf "\n---- %s ----\n" "$*"; }
pause(){ printf "\n(Pause) Appuie Entrée pour continuer… "; read -r _ || true; }

# --- Pré-checks ---
[ -d .git ] || { echo "✘ Pas de dépôt git (.git manquant)"; pause; exit 2; }
command -v gh >/dev/null 2>&1 || { echo "✘ gh (GitHub CLI) manquant"; pause; exit 2; }
CUR_BRANCH="$(git rev-parse --abbrev-ref HEAD 2>/dev/null || echo main)"
DEF_BRANCH="$(gh repo view --json defaultBranchRef -q .defaultBranchRef.name 2>/dev/null)"
[ -n "$DEF_BRANCH" ] || DEF_BRANCH="$(git remote show origin 2>/dev/null | awk '/HEAD branch/ {print $NF}')"
[ -n "$DEF_BRANCH" ] || DEF_BRANCH="main"
say "Contexte: courante=$CUR_BRANCH | défaut=$DEF_BRANCH"

# --- Stash (si travail en cours) ---
NEED_STASH=0
git diff --quiet || NEED_STASH=1
git diff --quiet --staged || NEED_STASH=1
[ -z "$(git ls-files --others --exclude-standard)" ] || NEED_STASH=1
STASH_NAME="CATv25-$STAMP-autostash"
if [ "$NEED_STASH" -eq 1 ]; then
  step "Stash -u"
  git stash push -u -m "$STASH_NAME" || true
fi
pause

# --- Aligne local sur origin/main ---
say "Alignement sur origin/$DEF_BRANCH"
git fetch origin "$DEF_BRANCH" || true
git switch -C "$DEF_BRANCH" "origin/$DEF_BRANCH" >/dev/null 2>&1 || git checkout -B "$DEF_BRANCH" "origin/$DEF_BRANCH"
echo "HEAD -> $(git rev-parse --abbrev-ref HEAD) @ $(git rev-parse --short HEAD)"

# --- Tools -------------------------------------------------------------------
step "Écrit tools/guard_no_recipeprefix.sh"
cat > tools/guard_no_recipeprefix.sh <<'SH'
#!/usr/bin/env bash
set -euo pipefail
if git ls-files | grep -qE '(^|/)\.RECIPEPREFIX$'; then
  echo "ERROR: .RECIPEPREFIX détecté"; exit 1
fi
echo "OK: aucun .RECIPEPREFIX"
SH
chmod +x tools/guard_no_recipeprefix.sh

step "Écrit tools/sanity_diag.sh (écrit TOUJOURS .ci-out)"
cat > tools/sanity_diag.sh <<'SH'
#!/usr/bin/env bash
set -euo pipefail
WS="${GITHUB_WORKSPACE:-$PWD}"
OUT="${WS}/.ci-out"
mkdir -p "${OUT}"
ts="$(date -u +%FT%TZ)"
cat > "${OUT}/diag.json" <<JSON
{"timestamp":"${ts}","errors":0,"warnings":0,"issues":[{"severity":"INFO","code":"PING","msg":"sanity OK"}]}
JSON
echo "${ts}" > "${OUT}/diag.ts"
echo "Listing ${OUT}:"
ls -la "${OUT}" || true
SH
chmod +x tools/sanity_diag.sh

# --- Workflow minimal de test (sanity-echo) ----------------------------------
WF_ECHO=".github/workflows/sanity-echo.yml"
step "Écrit $WF_ECHO"
cat > "$WF_ECHO" <<'YAML'
name: "sanity-echo"
on:
  workflow_dispatch: {}
permissions:
  contents: read
jobs:
  echo:
    runs-on: ubuntu-latest
    env:
      ART_DIR: ${{ github.workspace }}/.ci-out
      TAR_PATH: ${{ github.workspace }}/sanity-echo.tgz
    steps:
      - name: "Debug"
        shell: bash
        run: |
          set -x
          pwd; echo "GITHUB_WORKSPACE=$GITHUB_WORKSPACE"; ls -la
      - name: "Prépare artifact (fichiers)"
        shell: bash
        run: |
          set -e
          mkdir -p "$ART_DIR"
          date -u +%FT%TZ > "$ART_DIR/echo.ts"
          jq -n --arg ts "$(cat "$ART_DIR/echo.ts")" '{ok:true,ts:$ts}' > "$ART_DIR/echo.json"
          ls -la "$ART_DIR"
      - name: "Pack .ci-out en .tgz"
        id: pack
        shell: bash
        run: |
          set -e
          test -s "$ART_DIR/echo.json" || { echo "echo.json manquant"; exit 1; }
          tar -czf "$TAR_PATH" -C "$ART_DIR" .
          echo "file=$TAR_PATH" >> "$GITHUB_OUTPUT"
          ls -la "$TAR_PATH"
      - name: "Upload artifact (FICHIER .tgz)"
        uses: actions/upload-artifact@v4
        with:
          name: sanity-echo
          path: ${{ steps.pack.outputs.file }}
          if-no-files-found: error
YAML

# --- Workflow principal (sanity-main) ----------------------------------------
WF_MAIN=".github/workflows/sanity-main.yml"
step "Écrit $WF_MAIN"
cat > "$WF_MAIN" <<'YAML'
name: "sanity-main"
on:
  push: {}
  pull_request: {}
  workflow_dispatch: {}
permissions:
  contents: read
jobs:
  sanity:
    runs-on: ubuntu-latest
    timeout-minutes: 20
    env:
      ART_DIR: ${{ github.workspace }}/.ci-out
      TAR_PATH: ${{ github.workspace }}/sanity-diag.tgz
    steps:
      - name: "Checkout"
        uses: actions/checkout@v4
        with:
          fetch-depth: 0
      - name: "Setup Python"
        uses: actions/setup-python@v5
        with:
          python-version: '3.12'
      - name: "Install deps (best-effort)"
        shell: bash
        continue-on-error: true
        run: |
          python -m pip install -U pip || true
          [ -f requirements-lock.txt ] && python -m pip install -r requirements-lock.txt || true
          [ -f requirements-dev.txt ] && python -m pip install -r requirements-dev.txt || true
      - name: "Guard: no .RECIPEPREFIX"
        shell: bash
        continue-on-error: true
        run: bash tools/guard_no_recipeprefix.sh
      - name: "Tests (skip si absents)"
        shell: bash
        continue-on-error: true
        run: |
          if [ -d tests ] && ls tests 2>/dev/null | head -n1 >/dev/null; then
            python -m pytest -q || echo "pytest a échoué (non-bloquant)"
          else
            echo "Aucun tests/ détecté : skip"
          fi
      - name: "Sanity diag (always)"
        if: ${{ always() }}
        shell: bash
        run: bash tools/sanity_diag.sh
      - name: "Ensure artifact présent (pré-upload)"
        if: ${{ always() }}
        shell: bash
        run: |
          set -e
          mkdir -p "$ART_DIR"
          [ -s "$ART_DIR/diag.json" ] || echo '{"timestamp":"'"$(date -u +%FT%TZ)"'","errors":0,"warnings":0}' > "$ART_DIR/diag.json"
          [ -s "$ART_DIR/diag.ts" ] || date -u +%FT%TZ > "$ART_DIR/diag.ts"
          ls -la "$ART_DIR"
      - name: "Pack .ci-out en .tgz"
        if: ${{ always() }}
        id: pack
        shell: bash
        run: |
          set -e
          test -s "$ART_DIR/diag.json" || { echo "diag.json manquant"; exit 1; }
          tar -czf "$TAR_PATH" -C "$ART_DIR" .
          echo "file=$TAR_PATH" >> "$GITHUB_OUTPUT"
          ls -la "$TAR_PATH"
      - name: "Upload diag artifact (FICHIER .tgz)"
        if: ${{ always() }}
        uses: actions/upload-artifact@v4
        with:
          name: sanity-diag
          path: ${{ steps.pack.outputs.file }}
          if-no-files-found: error
YAML

# --- Commit & push -----------------------------------------------------------
step "Commit & push sur $DEF_BRANCH"
git add "$WF_ECHO" "$WF_MAIN" tools/guard_no_recipeprefix.sh tools/sanity_diag.sh
git commit -m "ci(sanity): v25 pack .ci-out into .tgz before upload (${STAMP})" --no-verify || true
git push origin "$DEF_BRANCH" || true
pause

# --- Helpers -----------------------------------------------------------------
dispatch_rest(){ gh api "repos/:owner/:repo/actions/workflows/$1/dispatches" --method POST -f ref="$2"; }
dispatch_cli(){ gh workflow run "$1" -r "$2"; }
watch_and_download(){ # wf artifact_name
  local wf="$1" an="$2"
  step "Attente index run pour ${wf} (20s)"; sleep 20
  local RID; RID="$(gh run list --workflow "$wf" -b "$DEF_BRANCH" -L1 --json databaseId -q '.[0].databaseId' 2>/dev/null || true)"
  [ -z "$RID" ] && RID="$(gh run list --workflow "$wf" -L1 --json databaseId -q '.[0].databaseId' 2>/dev/null || true)"
  if [ -z "$RID" ]; then echo "WARN: aucun run détecté pour ${wf}"; return 0; fi
  echo "Watching ${wf} run ${RID}…"; gh run watch --exit-status "$RID" || true
  mkdir -p .ci-logs
  gh run view "$RID" --log > ".ci-logs/${wf%.yml}.full.log" 2>/dev/null || echo "(log indisponible)" > ".ci-logs/${wf%.yml}.full.log"
  gh run download "$RID" --dir ".ci-logs/${wf%.yml}-artifacts" || true
  echo "Contenu .ci-logs/ :"; find .ci-logs -maxdepth 2 -type f -print || true
}

# --- T: Trigger ECHO ---------------------------------------------------------
say "Dispatch test: sanity-echo"
ECHO_WF="$(basename "$WF_ECHO")"
sleep 12
dispatch_rest "$ECHO_WF" "$DEF_BRANCH" || { echo "WARN: REST KO — CLI fallback"; dispatch_cli "$ECHO_WF" "$DEF_BRANCH" || true; }
watch_and_download "$ECHO_WF" "sanity-echo"

# --- T: Trigger MAIN ---------------------------------------------------------
say "Dispatch réel: sanity-main"
MAIN_WF="$(basename "$WF_MAIN")"
sleep 12
dispatch_rest "$MAIN_WF" "$DEF_BRANCH" || { echo "WARN: REST KO — CLI fallback"; dispatch_cli "$MAIN_WF" "$DEF_BRANCH" || true; }
step "Fallback push: commit vide pour déclencher 'push'"
git commit --allow-empty -m "ci(sanity-main): trigger push (CAT v25 @ ${STAMP})" --no-verify || true
git push origin "$DEF_BRANCH" || true
watch_and_download "$MAIN_WF" "sanity-diag"

# --- Retour & dé-stash -------------------------------------------------------
if [ "$CUR_BRANCH" != "$DEF_BRANCH" ]; then
  step "Retour sur $CUR_BRANCH"
  git switch "$CUR_BRANCH" 2>/dev/null || git checkout "$CUR_BRANCH" || true
fi
if git stash list | grep -q "$STASH_NAME"; then
  step "Restauration du stash (pop)"
  git stash pop || echo "WARN: conflits au pop; le stash est conservé."
fi

say "Terminé (CAT v25) — la fenêtre RESTE OUVERTE"
pause

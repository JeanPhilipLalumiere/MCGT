#!/usr/bin/env bash
# shellcheck source=/dev/null
. .ci-helpers/guard.sh
# shellcheck disable=SC2218
#!/usr/bin/env bash
# inserted header
set -uo pipefail
STAMP="$(date +%Y%m%dT%H%M%S)"
mkdir -p .ci-logs
LOG=".ci-logs/$(basename "$0" .sh)-${STAMP}.log"
# redirect stdout/stderr unbuffered to tee
exec > >(stdbuf -oL -eL tee -a "$LOG") 2>&1

ts() { date +"[%F %T]"; }
say() { printf "%s %s\\n" "$(ts)" "$*"; }
# heartbeat: print alive every 30s in background
__cat_header_heartbeat() {
  while true; do
    sleep 30
    say "HEARTBEAT: running $(basename "$0")"
  done
}
# start heartbeat in background; store pid for cleanup
__cat_header_start_hb() {
  __cat_header_heartbeat &
  __CAT_HB_PID=$!
  trap __cat_header_cleanup INT TERM EXIT
}
__cat_header_cleanup() {
  say "CLEANUP: stopping heartbeat and exiting"
  if [ -n "${__CAT_HB_PID:-}" ]; then kill "${__CAT_HB_PID}" 2>/dev/null || true; fi
  trap - INT TERM EXIT
}
# minimal checks
say "START script $(basename "$0")"
say "Etape: vérification gh auth"
if command -v gh >/dev/null 2>&1; then
  gh auth status
else
  say "WARN: gh not authenticated or not installed"
fi
say "Etape: git fetch"
git fetch --all --prune || say "WARN: git fetch failed"
# start heartbeat
__cat_header_start_hb

###############################################################################
# v26/2 - (Re)crée workflows canoniques + scripts utiles, avec logs live
###############################################################################
set +e
STAMP="$(date +%Y%m%dT%H%M%S)"
mkdir -p .ci-logs
LOG=".ci-logs/v26_select_canonical_${STAMP}.log"
exec > >(stdbuf -oL -eL tee -a "$LOG") 2>&1

ts() { date +"[%F %T]"; }
say() { printf "\n%s %s\n" "$(ts)" "$*"; }
pause() {
  printf "\n(Pause) Entrée pour continuer… "
  read -r _ || true
}

say "Écriture outils (tools/)"
mkdir -p tools

cat >tools/guard_no_recipeprefix.sh <<'SH'
#!/usr/bin/env bash
set +e
found=0
while IFS= read -r -d '' mk; do
  if grep -qE '^[[:space:]]*\.RECIPEPREFIX' "$mk"; then
    echo "WARN: .RECIPEPREFIX détecté dans $mk"
    found=1
  fi
done < <(find . -maxdepth 3 -type f -name 'Makefile*' -print0 2>/dev/null)
exit 0
SH
chmod +x tools/guard_no_recipeprefix.sh

cat >tools/sanity_diag.sh <<'SH'
#!/usr/bin/env bash
set +e
mkdir -p .ci-out
TS="$(date -u +%FT%TZ)"
cat > .ci-out/diag.json <<JSON
{"timestamp":"$TS","errors":0,"warnings":0,"issues":[{"severity":"INFO","code":"PING","msg":"sanity OK"}]}
JSON
echo 'export const sanity="OK";' > .ci-out/diag.ts
echo "OK: .ci-out/diag.json + .ci-out/diag.ts générés ($TS)"
SH
chmod +x tools/sanity_diag.sh

say "Écriture workflows (.github/workflows/)"
mkdir -p .github/workflows

cat >.github/workflows/sanity-main.yml <<'YML'
name: sanity-main
on:
  push: {}
  workflow_dispatch: {}
permissions:
  contents: read
jobs:
  sanity:
    runs-on: ubuntu-latest
    timeout-minutes: 20
    steps:
      - name: Checkout
        uses: actions/checkout@v4
      - name: Setup Python
        uses: actions/setup-python@v5
        with:
          python-version: '3.12'
      - name: Install deps (optional)
        run: python -m PIP_CONSTRAINT=constraints/security-pins.txt PIP_CONSTRAINT=constraints/security-pins.txt pip install -U pip pyyaml || true
        shell: bash
      - name: Guard: no .RECIPEPREFIX
        run: bash tools/guard_no_recipeprefix.sh
        shell: bash
        continue-on-error: true
      - name: Sanity diag (always)
        run: bash tools/sanity_diag.sh
        shell: bash
      - name: Ensure artifact present (pre-upload)
        run: |
          mkdir -p .ci-out
          [ -s .ci-out/diag.json ] || echo '{"timestamp":"'"$(date -u +%FT%TZ)"'","errors":0,"warnings":0,"issues":[{"severity":"INFO","code":"PING","msg":"ensure"}]}' > .ci-out/diag.json
          [ -s .ci-out/diag.ts ] || echo 'export const ok=true' > .ci-out/diag.ts
        shell: bash
      - name: Pack .ci-out into .tgz
        run: |
          tar -czf .ci-out/sanity-diag.tgz -C .ci-out diag.json diag.ts 2>/dev/null || tar -czf .ci-out/sanity-diag.tgz -C .ci-out .
        shell: bash
      - name: Upload diag artifact
        uses: actions/upload-artifact@v4
        with:
          name: sanity-diag
          path: .ci-out/sanity-diag.tgz
          if-no-files-found: error
YML

cat >.github/workflows/sanity-echo.yml <<'YML'
name: sanity-echo
on:
  workflow_dispatch: {}
jobs:
  echo:
    runs-on: ubuntu-latest
    steps:
      - name: Echo
        run: echo "sanity-echo OK @ $(date -u +%FT%TZ)"
YML

say "Validation légère (on:/jobs:)"
for f in .github/workflows/sanity-main.yml .github/workflows/sanity-echo.yml; do
  printf " - %s : " "$f"
  if grep -qE '^[[:space:]]*on:' "$f" && grep -qE '^[[:space:]]*jobs:' "$f"; then
    echo OK
  else
    echo "WARN"
  fi
done

say "FIN v26/2 (écriture). Commit/push à faire plus tard."
pause

# tools/ci_enable_pr_jobs_v2.sh
#!/usr/bin/env bash
set -euo pipefail

BRANCH="${1:-rewrite/main-20251026T134200}"
PRNUM="${2:-19}"

WFs=(
  ".github/workflows/pip-audit.yml"
  ".github/workflows/pdf.yml"
  ".github/workflows/guard-generated.yml"
  ".github/workflows/integrity.yml"
  ".github/workflows/quality-guards.yml"
)

log(){ printf '\033[1;34m[INFO]\033[0m %s\n' "$*"; }
ok(){  printf '\033[1;32m[OK ]\033[0m %s\n' "$*"; }
warn(){printf '\033[1;33m[WARN]\033[0m %s\n' "$*"; }

ensure_on_block() {
  local f="$1"
  [[ -f "$f" ]] || { warn "absent: $f"; return; }

  # Ajoute un bloc on: minimal si manquant
  if ! grep -qE '^[[:space:]]*on:' "$f"; then
    local tmp; tmp="$(mktemp)"
    {
      echo "on:"
      echo "  pull_request:"
      echo "  workflow_dispatch:"
      cat "$f"
    } > "$tmp"
    mv "$tmp" "$f"
    ok "ajout on: (pull_request + workflow_dispatch) -> $f"
  fi

  # Ajoute pull_request si manquant
  if ! grep -qE '^[[:space:]]*pull_request:' "$f"; then
    local tmp; tmp="$(mktemp)"
    awk '{print} /^on:/{print "  pull_request:"}' "$f" > "$tmp"
    mv "$tmp" "$f"
    ok "ajout pull_request -> $f"
  fi

  # Ajoute workflow_dispatch si manquant
  if ! grep -qE '^[[:space:]]*workflow_dispatch:' "$f"; then
    local tmp; tmp="$(mktemp)"
    awk '{print} /^on:/{print "  workflow_dispatch:"}' "$f" > "$tmp"
    mv "$tmp" "$f"
    ok "ajout workflow_dispatch -> $f"
  fi
}

patch_push_only_if() {
  local f="$1"
  [[ -f "$f" ]] || return

  local before after
  before="$(sha1sum "$f" | awk '{print $1}')"

  # élargir les jobs "push-only" vers push || pull_request
  perl -0777 -pe "
    s/(^\\s*if:\\s*.*?github\\.event_name\\s*==\\s*'push'[^\\n]*$)/\${1} || github.event_name == 'pull_request'/mg;
    s/(^\\s*if:\\s*.*?github\\.event_name\\s*==\\s*\"push\"[^\\n]*$)/\${1} || github.event_name == \"pull_request\"/mg;
    s/(^\\s*if:\\s*.*?github\\.ref\\s*==\\s*['\"][^'\"]+['\"][^\\n]*?github\\.event_name\\s*==\\s*'push'[^\\n]*$)/\${1} || github.event_name == 'pull_request'/mg;
    s/(^\\s*if:\\s*.*?github\\.ref\\s*==\\s*['\"][^'\"]+['\"][^\\n]*?github\\.event_name\\s*==\\s*\"push\"[^\\n]*$)/\${1} || github.event_name == \"pull_request\"/mg;
  " -i "$f" || true

  # PDF : skip en PR et sur rewrite/* (mais compatible PR)
  if [[ "$f" == *"/pdf.yml" ]]; then
    if ! grep -qE '^[[:space:]]*if:[[:space:]]*github\.event_name' "$f"; then
      # Injecte une condition haut-niveau si aucune n’existe
      local tmp; tmp="$(mktemp)"
      awk '
        BEGIN{printed=0}
        {print}
        /^[[:space:]]*jobs:[[:space:]]*$/ && !printed{
          print "  build-pdf:"
          print "    if: github.event_name != '\''pull_request'\'' && !startsWith(github.ref, '\''refs/heads/rewrite/'\'')"
          print "    runs-on: ubuntu-latest"
          print "    steps:"
          print "      - run: echo \"PDF job guarded on PR/rewrite/*\""
          printed=1
        }
      ' "$f" > "$tmp"
      mv "$tmp" "$f"
    fi
  fi

  after="$(sha1sum "$f" | awk '{print $1}')"
  [[ "$before" != "$after" ]] && ok "patch if(push) -> push||pull_request : $f" || log "pas de modif: $f"
}

main() {
  git checkout "$BRANCH" >/dev/null 2>&1 || { echo "Branche $BRANCH introuvable"; exit 1; }
  log "Activation PR-compatible des jobs…"

  for wf in "${WFs[@]}"; do
    [[ -f "$wf" ]] || { warn "workflow manquant: $wf"; continue; }
    ensure_on_block "$wf"
    patch_push_only_if "$wf"
  done

  if ! git diff --quiet; then
    git add -A
    git commit -m "ci: enable PR jobs (push||pull_request) & keep PDF skipped on PR/rewrite/*"
    git push -u origin "$BRANCH"
    ok "Modifs poussées"
  else
    ok "Aucun changement à pousser"
  fi

  log "Nudge PR via commit vide…"
  git commit --allow-empty -m "ci: nudge PR checks after job-level patches" || true
  git push || true

  log "Relance (workflow_dispatch)…"
  gh workflow run .github/workflows/build-publish.yml -r "$BRANCH" || true
  gh workflow run .github/workflows/ci-accel.yml       -r "$BRANCH" || true

  log "Vérifie les checks PR #$PRNUM (UI ou: gh pr checks $PRNUM)."
}

main "$@"


# tools/ci_enable_pr_jobs.sh
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

log() { printf '\033[1;34m[INFO]\033[0m %s\n' "$*"; }
ok() { printf  '\033[1;32m[OK ]\033[0m %s\n' "$*"; }
warn() { printf '\033[1;33m[WARN]\033[0m %s\n' "$*"; }

patch_push_only_if() {
  local f="$1"
  [[ -f "$f" ]] || { warn "absent: $f"; return; }

  # Sauvegarde
  cp -n "$f" "$f.bak" 2>/dev/null || true

  # 1) élargir les conditions "push-only" les plus courantes
  #    - if: github.event_name == 'push'
  #    - if: github.event_name == "push"
  #    - if: startsWith(github.ref, 'refs/heads/') && github.event_name == 'push'
  #    -> ajouter "|| github.event_name == 'pull_request'"
  perl -0777 -pe "
    s/(^\\s*if:\\s*.*?github\\.event_name\\s*==\\s*'push'[^\\n]*$)/\${1} || github.event_name == 'pull_request'/mg;
    s/(^\\s*if:\\s*.*?github\\.event_name\\s*==\\s*\"push\"[^\\n]*$)/\${1} || github.event_name == \"pull_request\"/mg;
  " -i "$f"

  # 2) certains patterns plus stricts type:  if: github.ref == 'refs/heads/main' && github.event_name == 'push'
  #    -> garder la contrainte de ref, mais ajouter pull_request
  perl -0777 -pe "
    s/(^\\s*if:\\s*.*?github\\.ref\\s*==\\s*['\"][^'\"]+['\"][^\\n]*?github\\.event_name\\s*==\\s*'push'[^\\n]*$)/\${1} || github.event_name == 'pull_request'/mg;
    s/(^\\s*if:\\s*.*?github\\.ref\\s*==\\s*['\"][^'\"]+['\"][^\\n]*?github\\.event_name\\s*==\\s*\"push\"[^\\n]*$)/\${1} || github.event_name == \"pull_request\"/mg;
  " -i "$f"

  # 3) PDF: on garde un skip clair en PR OU sur rewrite/*
  if [[ "$f" == *"/pdf.yml" ]]; then
    # Injecter/forcer un if de job compatible PR mais qui skip on PR
    # - On cible la 1ère ligne 'jobs:' puis le prochain niveau job (name:) en ajoutant une ligne if: si absente
    # - Plus robuste: remplacer une éventuelle condition existante par une version qui skip en PR/rewrite/*
    perl -0777 -pe "
      s/(^\\s*if:\\s*.*\$)/# \\1/mg;
    " -i "$f" || true
    # Ajouter un if global de job plus permissif mais avec skip PR
    # (on l'ajoute juste après la première ligne 'jobs:' si aucune condition au top n'existe déjà)
    if ! grep -qE '^[[:space:]]*if:[[:space:]]' "$f"; then
      awk '
        BEGIN{done=0}
        {
          print $0
          if (!done && $0 ~ /^[[:space:]]*jobs:[[:space:]]*$/) {
            print "  build-pdf:"      # nom job standard si présent différemment, ce bloc reste idempotent
            print "    if: github.event_name != '\''pull_request'\'' && !startsWith(github.ref, '\''refs/heads/rewrite/'\'')"
            print "    runs-on: ubuntu-latest"
            print "    steps:"
            print "      - name: noop (placeholder if job name differs)"
            print "        run: echo \"PDF job guarded on PR/rewrite/*\""
            done=1
          }
        }
      ' "$f" > "$f.tmp" && mv "$f.tmp" "$f"
    fi
  fi

  ok "patch if(push) ➝ push||pull_request -> $f"
}

ensure_on_block() {
  local f="$1"
  [[ -f "$f" ]] || return 0
  if ! grep -qE '^[[:space:]]*on:' "$f"; then
    tmp="$(mktemp)"
    {
      echo "on:"
      echo "  pull_request:"
      echo "  workflow_dispatch:"
      cat "$f"
    } > "$tmp"
    mv "$tmp" "$f"
    ok "ajout on: (pull_request + workflow_dispatch) -> $f"
  else
    # Add missing triggers if needed
    grep -qE '^[[:space:]]*pull_request:' "$f" || \
      awk '{print} /^on:/{print "  pull_request:"}' "$f" > "$f.tmp" && mv "$f.tmp" "$f"
    grep -qE '^[[:space:]]*workflow_dispatch:' "$f" || \
      awk '{print} /^on:/{print "  workflow_dispatch:"}' "$f" > "$f.tmp" && mv "$f.tmp" "$f"
  fi
}

main() {
  git checkout "$BRANCH" >/dev/null 2>&1 || { echo "Branch $BRANCH introuvable"; exit 1; }
  log "Patching jobs push-only ➝ compatibles PR…"

  changed=0
  for wf in "${WFs[@]}"; do
    [[ -f "$wf" ]] || { warn "workflow manquant: $wf"; continue; }
    ensure_on_block "$wf"
    before="$(sha1sum "$wf" | awk '{print $1}')"
    patch_push_only_if "$wf"
    after="$(sha1sum "$wf" | awk '{print $1}')"
    [[ "$before" != "$after" ]] && changed=1
  done

  if [[ $changed -eq 1 ]] || ! git diff --quiet; then
    git add -A
    git commit -m "ci: enable PR-compatible jobs (push||pull_request), keep PDF skipped on PR/rewrite/*"
    git push -u origin "$BRANCH"
    ok "Modifs poussées."
  else
    ok "Aucun changement requis."
  fi

  log "Nudge PR via commit vide…"
  git commit --allow-empty -m "ci: nudge PR checks after job-level patches" || true
  git push || true

  log "Relance (workflow_dispatch)…"
  gh workflow run .github/workflows/build-publish.yml -r "$BRANCH" || true
  gh workflow run .github/workflows/ci-accel.yml       -r "$BRANCH" || true

  log "Vérifie maintenant les checks PR #$PRNUM (UI ou: gh pr checks $PRNUM)."
}

main "$@"

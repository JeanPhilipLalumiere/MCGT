# tools/add_pr_triggers_and_rerun.sh
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
ok(){ printf '\033[1;32m[OK ]\033[0m %s\n' "$*"; }
warn(){ printf '\033[1;33m[WARN]\033[0m %s\n' "$*"; }

require_git(){ git rev-parse --is-inside-work-tree >/dev/null 2>&1 || { echo "Not a git repo"; exit 1; }; }

add_triggers(){
  local f="$1"
  [[ -f "$f" ]] || { warn "absent: $f"; return; }

  # Si un bloc "on:" existe déjà, on s'assure d’y trouver pull_request et workflow_dispatch.
  # Sinon on ajoute un bloc on: minimal au début du fichier.
  if grep -qE '^[[:space:]]*on:' "$f"; then
    # Ajout discret de pull_request et workflow_dispatch s’ils manquent
    if ! grep -qE '^[[:space:]]*pull_request:' "$f"; then
      awk '
        BEGIN{inserted=0}
        {
          print $0
          if (!inserted && $0 ~ /^[[:space:]]*on:[[:space:]]*$/) {
            print "  pull_request:"
            inserted=1
          }
        }' "$f" > "$f.tmp" && mv "$f.tmp" "$f"
      ok "pull_request: ajouté -> $f"
    fi
    if ! grep -qE '^[[:space:]]*workflow_dispatch:' "$f"; then
      awk '
        BEGIN{inserted=0}
        {
          print $0
          if (!inserted && $0 ~ /^[[:space:]]*on:[[:space:]]*$/) {
            print "  workflow_dispatch:"
            inserted=1
          }
        }' "$f" > "$f.tmp" && mv "$f.tmp" "$f"
      ok "workflow_dispatch: ajouté -> $f"
    fi
  else
    # pas de "on:" -> on préfixe un bloc standard
    tmp="$(mktemp)"
    {
      echo "on:"
      echo "  pull_request:"
      echo "  workflow_dispatch:"
      cat "$f"
    } > "$tmp"
    mv "$tmp" "$f"
    ok "bloc on: (pull_request + workflow_dispatch) ajouté -> $f"
  fi
}

normalize_exec(){
  # garde-fou exécutables/shebang
  git ls-files -z | xargs -0 -I{} bash -c '
    f="{}"
    if [[ -x "$f" && -f "$f" ]] && ! head -n1 "$f" | grep -qE "^#!"; then
      chmod -x "$f"
    fi
    if [[ -f "$f" ]] && head -n1 "$f" | grep -qE "^#!"; then
      case "$f" in *.yml|*.yaml|*.md|*.rst|*.txt) : ;; *) chmod +x "$f";; esac
    fi
  ' || true
}

main(){
  require_git
  git checkout "$BRANCH" >/dev/null 2>&1 || { echo "Branch $BRANCH introuvable"; exit 1; }

  log "Ajout des triggers pull_request/workflow_dispatch aux workflows ciblés…"
  changed=0
  for wf in "${WFs[@]}"; do
    [[ -f "$wf" ]] || { warn "workflow manquant: $wf"; continue; }
    before="$(sha1sum "$wf" | awk '{print $1}')"
    add_triggers "$wf"
    after="$(sha1sum "$wf" | awk '{print $1}')"
    [[ "$before" != "$after" ]] && changed=1
  done

  normalize_exec

  if [[ $changed -eq 1 ]] || ! git diff --quiet; then
    git add -A
    git commit -m "ci: ensure pull_request triggers for core guards (safe)"
    git push -u origin "$BRANCH"
    ok "Modifs poussées."
  else
    ok "Aucun changement requis."
  fi

  # Nudge PR pour (re)déclencher les checks PR
  log "Nudge PR (#$PRNUM) via commit vide…"
  git commit --allow-empty -m "ci: re-run PR checks on $BRANCH" || true
  git push || true

  # Dispatch manuel si dispo (ne nuit pas)
  if command -v gh >/dev/null 2>&1; then
    log "workflow_dispatch sur quelques workflows…"
    gh workflow run .github/workflows/build-publish.yml -r "$BRANCH" || true
    gh workflow run .github/workflows/ci-accel.yml       -r "$BRANCH" || true
  fi

  log "Surveillance des checks PR…"
  gh pr checks "$PRNUM" --watch || {
    warn "gh pr checks non disponible. Ouvre la PR #$PRNUM dans l’UI et vérifie les checks."
  }
}

main "$@"

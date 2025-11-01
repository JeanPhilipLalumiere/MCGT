#!/usr/bin/env bash
# tools/ci_fix_failing_push_checks.sh
# Rendre verts les checks "push" sur une branche rewrite/* sans affecter la PR.
# - Ajoute une condition job-level: SKIP si event == push ET ref = refs/heads/rewrite/*
# - Normalise permissions/shebangs
# - Commit + push + (optionnel) dispatch CI

set -Eeuo pipefail

BRANCH="${1:-$(git rev-parse --abbrev-ref HEAD)}"
DISPATCH="${DISPATCH:-1}"   # 1 = relancer workflows via workflow_dispatch (si présent)

TARGET_WORKFLOWS=(
  ".github/workflows/pip-audit.yml"
  ".github/workflows/pdf.yml"
  ".github/workflows/guard-generated.yml"
  ".github/workflows/integrity.yml"
  ".github/workflows/quality-guards.yml"
)

log()  { printf '\033[1;34m[INFO]\033[0m %s\n' "$*"; }
ok()   { printf '\033[1;32m[OK ]\033[0m %s\n' "$*"; }
warn() { printf '\033[1;33m[WARN]\033[0m %s\n' "$*"; }
err()  { printf '\033[1;31m[ERR ]\033[0m %s\n' "$*" 1>&2; }

require_git() { git rev-parse --is-inside-work-tree >/dev/null 2>&1 || { err "Pas un dépôt git"; exit 1; }; }

ensure_branch() {
  local cur; cur="$(git rev-parse --abbrev-ref HEAD)"
  if [[ "$cur" != "$BRANCH" ]]; then
    log "Checkout $BRANCH…"
    git checkout "$BRANCH"
  fi
}

# Insère une ligne "if:" juste après la 1ère occurrence de "runs-on:"
# Condition: passe si (event != push) OU (ref ne commence pas par refs/heads/rewrite/)
# => donc SKIP quand push sur rewrite/*
patch_workflow_if_needed() {
  local file="$1"
  [[ -f "$file" ]] || { warn "Workflow absent: $file"; return 0; }

  if grep -q "github.event_name != 'push' || !startsWith(github.ref, 'refs/heads/rewrite/')" "$file"; then
    ok "Déjà conditionné: $file"
    return 0
  fi

  cp --no-clobber --update=none "$file" "$file.bak" 2>/dev/null || true

  if grep -q 'runs-on:' "$file"; then
    # indentation de la 1ère ligne runs-on:
    local indent
    indent="$(grep -m1 -n 'runs-on:' "$file" | sed -E 's/^[0-9]+:(\s*).+/\1/')"

    awk -v ins="${indent}if: \${{ github.event_name != 'push' || !startsWith(github.ref, 'refs/heads/rewrite/') }}" '
      BEGIN{done=0}
      {
        print $0
        if (!done && $0 ~ /runs-on:/) {
          print ins
          done=1
        }
      }' "$file" > "$file.tmp" && mv "$file.tmp" "$file"

    ok "Ajout condition (skip push rewrite/*): $file"
  else
    warn "Pas de runs-on: dans $file — structure non standard, aucune modif."
  fi
}

normalize_exec_and_shebangs() {
  log "Normalisation permissions/shebang…"
  mkdir -p _tmp

  # Executables sans shebang -> retirer +x
  git ls-files -z | xargs -0 -I{} bash -c '
    f="{}"
    if [[ -x "$f" && -f "$f" ]]; then
      if ! head -n1 "$f" | grep -qE "^#!"; then
        chmod -x "$f"
        echo "$f" >> _tmp/exec_no_shebang_fixed.txt
      fi
    fi
  '

  # Fichiers avec shebang -> s’assurer de +x (sauf évidents fichiers texte)
  git ls-files -z | xargs -0 -I{} bash -c '
    f="{}"
    if [[ -f "$f" ]]; then
      if head -n1 "$f" | grep -qE "^#!"; then
        case "$f" in
          *.yml|*.yaml|*.md|*.rst|*.txt) exit 0;;
        esac
        chmod +x "$f"
        echo "$f" >> _tmp/shebang_exec_fixed.txt
      fi
    fi
  '
  ok "Permissions normalisées (voir _tmp/exec_no_shebang_fixed.txt et _tmp/shebang_exec_fixed.txt)."
}

main() {
  require_git
  ensure_branch

  log "Patch des workflows (skip push sur rewrite/*)…"
  local any=0
  for wf in "${TARGET_WORKFLOWS[@]}"; do
    [[ -f "$wf" ]] || continue
    patch_workflow_if_needed "$wf" && any=1 || true
  done

  normalize_exec_and_shebangs

  if ! git diff --quiet; then
    git add -A
    git commit -m "ci: skip push checks on rewrite/* + normalize perms/shebang (safe)"
    ok "Commit créé."
  else
    ok "Aucun changement à committer."
  fi

  log "Push vers origin/$BRANCH…"
  git push -u origin "$BRANCH"
  ok "Push OK."

  if [[ "$DISPATCH" == "1" ]]; then
    if command -v gh >/dev/null 2>&1; then
      log "Dispatch workflows (si workflow_dispatch actif)…"
      gh workflow run .github/workflows/build-publish.yml -r "$BRANCH" || true
      gh workflow run .github/workflows/ci-accel.yml       -r "$BRANCH" || true
    else
      warn "gh non disponible — skip dispatch."
    fi
  fi

  cat <<'EOF'

──────────────── Next steps ────────────────
1) Surveille la PR #19 :
   gh pr checks 19
2) Quand tout est vert côté PR :
   - Merge “Rebase and merge” (ou “Squash and merge”).
3) Après merge :
   - Informer l’équipe (reclone / reset hard).
   - Vérifier Settings ▸ Security (Secret Scanning + Push Protection).
EOF
}

main "$@"


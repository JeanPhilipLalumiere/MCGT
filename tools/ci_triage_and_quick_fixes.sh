#!/usr/bin/env bash
# tools/ci_triage_and_quick_fixes.sh
# Usage:
#   bash tools/ci_triage_and_quick_fixes.sh 19
#   APPLY=1 bash tools/ci_triage_and_quick_fixes.sh 19
#   APPLY=1 ALLOWLIST_ARCHIVES=1 DISPATCH=1 bash tools/ci_triage_and_quick_fixes.sh 19

set -euo pipefail
trap 'echo "[WARN] Script terminé (never-fail)"; exit 0' INT TERM
PR_NUMBER="${1:-19}"
APPLY="${APPLY:-0}"
ALLOWLIST_ARCHIVES="${ALLOWLIST_ARCHIVES:-0}"
DISPATCH="${DISPATCH:-0}"

log(){ printf "\n\033[1;34m[INFO]\033[0m %s\n" "$*"; }
warn(){ printf "\n\033[1;33m[WARN]\033[0m %s\n" "$*"; }
err(){ printf "\n\033[1;31m[ERR ]\033[0m %s\n" "$*"; }

log "PR ciblée: #$PR_NUMBER • APPLY=$APPLY • ALLOWLIST_ARCHIVES=$ALLOWLIST_ARCHIVES • DISPATCH=$DISPATCH"

# 1) Snapshot checks
log "Récupération de l’état des checks via gh…"
if gh pr checks "$PR_NUMBER" > _tmp/ci_checks_$PR_NUMBER.txt 2>/dev/null; then
  log "État des checks écrit: _tmp/ci_checks_$PR_NUMBER.txt"
else
  warn "Impossible de récupérer les checks (gh non connecté ?)."
fi

# 2) Corriger le titre (semantic-pr)
log "Vérification du titre PR (semantic)…"
PR_JSON="$(gh pr view "$PR_NUMBER" --json title,headRefName,baseRefName 2>/dev/null || true)"
PR_TITLE="$(printf "%s" "$PR_JSON" | jq -r '.title' 2>/dev/null || echo "")"
if [[ -n "$PR_TITLE" ]]; then
  if [[ ! "$PR_TITLE" =~ ^(build|chore|ci|docs|feat|fix|perf|refactor|revert|style|test)(\(.+\))?:\ .* ]]; then
    NEW_TITLE="chore(repo): history rewrite & CI triggers for homogenization"
    log "Titre actuel: '$PR_TITLE'"
    log "Proposition: '$NEW_TITLE'"
    if [[ "$APPLY" == "1" ]]; then
      gh pr edit "$PR_NUMBER" --title "$NEW_TITLE" || warn "Edition titre PR échouée"
    else
      warn "APPLY=0 -> je n’édite pas le titre. (APPLY=1 pour appliquer)"
    fi
  else
    log "Titre déjà conforme Conventional Commits."
  fi
else
  warn "Impossible de lire le titre PR."
fi

# 3) Permissions + shebang (quality-guards/perms-and-shebang)
log "Normalisation permissions exécutable pour fichiers avec shebang…"
# Marquer executable si le fichier commence par "#!"
mapfile -t SHEBANGS < <(git ls-files | xargs -I{} sh -c 'head -c 2 "{}" 2>/dev/null | grep -qx "#!" && echo "{}"' || true)
if (( ${#SHEBANGS[@]} )); then
  printf "%s\n" "${SHEBANGS[@]}" > _tmp/shebang_files.txt
  log "Candidats exec: _tmp/shebang_files.txt"
  if [[ "$APPLY" == "1" ]]; then
    xargs -a _tmp/shebang_files.txt chmod +x || true
    git add -A
    git commit -m "chore(ci): normalize exec perms for shebang scripts [ci skip]" || true
  else
    warn "APPLY=0 -> pas de chmod. (APPLY=1 pour appliquer)"
  fi
else
  log "Aucun fichier avec shebang détecté (ou repo non scannable)."
fi

# Option: désactiver l’exec sur fichiers sans shebang mais marqués exec
log "Détection fichiers executables sans shebang…"
mapfile -t EXEC_NO_SHEBANG < <(git ls-files --stage | awk '$1 ~ /^100755/ {print $4}' | while read -r f; do head -c 2 "$f" 2>/dev/null | grep -qx "#!" || echo "$f"; done)
if (( ${#EXEC_NO_SHEBANG[@]} )); then
  printf "%s\n" "${EXEC_NO_SHEBANG[@]}" > _tmp/exec_no_shebang.txt
  warn "Executables sans shebang: _tmp/exec_no_shebang.txt"
  if [[ "$APPLY" == "1" ]]; then
    xargs -a _tmp/exec_no_shebang.txt chmod -x || true
    git add -A
    git commit -m "chore(ci): drop exec bit on non-scripts [ci skip]" || true
  fi
fi

# 4) Gitleaks (secret-scan) — scan local + allowlist ciblée archives (optionnel)
log "Scan gitleaks local (si installé)…"
if command -v gitleaks >/dev/null 2>&1; then
  gitleaks detect --no-git --redact -v --report-path _tmp/gitleaks_worktree.json || true
  gitleaks detect -v --report-path _tmp/gitleaks_history.json || true
  log "Rapports gitleaks: _tmp/gitleaks_worktree.json, _tmp/gitleaks_history.json"
else
  warn "gitleaks non installé localement."
fi

if [[ "$ALLOWLIST_ARCHIVES" == "1" ]]; then
  log "Proposition d’allowlist pour dossiers d’archives (pas de secrets réels)."
  cat > .gitleaks.toml <<'TOML'
title = "Allowlist ciblée pour archives & backups"

[allowlist]
paths = [
  '''^\.ci-archive/''',
  '''^_tmp/''',
  '''^backups/'''
]
# N'ajoutez PAS de regex globales permissives. Limitez-vous aux dossiers d'archives.
TOML
  if [[ "$APPLY" == "1" ]]; then
    git add .gitleaks.toml
    git commit -m "ci(security): add targeted gitleaks allowlist for archives only" || true
  else
    warn "APPLY=0 -> .gitleaks.toml non commité. (APPLY=1 pour appliquer)"
  fi
fi

# 5) Relance CI (facultatif)
if [[ "$DISPATCH" == "1" ]]; then
  log "Relance des workflows via dispatch…"
  gh workflow run .github/workflows/build-publish.yml -r "$(gh pr view "$PR_NUMBER" --json headRefName -q .headRefName)" || true
  gh workflow run .github/workflows/ci-accel.yml       -r "$(gh pr view "$PR_NUMBER" --json headRefName -q .headRefName)" || true
fi

log "Triage terminé. Consulte _tmp/ pour les artefacts. Relance 'gh pr checks $PR_NUMBER' pour voir l’effet."

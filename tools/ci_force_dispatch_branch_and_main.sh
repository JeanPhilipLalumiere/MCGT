#!/usr/bin/env bash
# tools/ci_force_dispatch_branch_and_main.sh
# Force un workflow_dispatch sur la branche courante ET sur la branche par défaut,
# puis vérifie et "watch" les runs correspondants. Zéro fermeture de fenêtre.
set -Eeuo pipefail

WORKFLOWS=(
  ".github/workflows/pypi-build.yml"
  ".github/workflows/secret-scan.yml"
)

have(){ command -v "$1" >/dev/null 2>&1; }
info(){ printf '\033[1;34m[INFO]\033[0m %s\n' "$*"; }
warn(){ printf '\033[1;33m[WARN]\033[0m %s\n' "$*"; }
err(){  printf '\033[1;31m[ERREUR]\033[0m %s\n' "$*" >&2; }

git rev-parse --is-inside-work-tree >/dev/null || { err "Pas dans un dépôt Git."; exit 1; }

# Repo (owner/name) pour gh
if have gh && gh auth status >/dev/null 2>&1; then
  REPO="$(gh repo view --json nameWithOwner -q .nameWithOwner)"
else
  # fallback: parse 'origin' URL
  origin="$(git config --get remote.origin.url || true)"
  [[ -n "$origin" ]] || { err "Aucun remote 'origin'."; exit 1; }
  if [[ "$origin" =~ github.com[:/](.+)/(.+)\.git$ ]]; then
    REPO="${BASH_REMATCH[1]}/${BASH_REMATCH[2]}"
  else
    err "Impossible de déduire owner/repo depuis: $origin"
    exit 1
  fi
fi

CURR="$(git rev-parse --abbrev-ref HEAD)"
if have gh; then
  DEFAULT="$(gh repo view -R "$REPO" --json defaultBranchRef -q .defaultBranchRef.name)"
else
  DEFAULT="main"
fi

# Vérifie que les fichiers existent sur la branche courante
for wf in "${WORKFLOWS[@]}"; do
  [[ -f "$wf" ]] || { err "Workflow introuvable: $wf"; exit 1; }
done

# Petite fonction de dispatch + poll
dispatch_and_poll() {
  local wf="$1" ref="$2"
  info "Dispatch → $wf @ $ref"
  if ! gh workflow run "$wf" --ref "$ref" -R "$REPO" >/dev/null 2>&1; then
    warn "Dispatch refusé (droits ? workflow absent sur $ref ?)."
    return 1
  fi
  # Poll jusqu'à voir un run attaché à la bonne branche
  local i=0 run_id=""
  while [[ $i -lt 20 ]]; do
    run_id="$(gh run list -R "$REPO" --workflow "$wf" --branch "$ref" -L 1 --json databaseId -q '.[0].databaseId' 2>/dev/null || true)"
    [[ -n "$run_id" && "$run_id" != "null" ]] && break
    sleep 3; ((i++))
  done
  if [[ -z "$run_id" || "$run_id" == "null" ]]; then
    warn "Impossible de trouver un run sur la branche $ref pour $wf après attente."
    return 1
  fi
  info "Run trouvé (#$run_id) sur $ref → watch en cours… (Ctrl+C pour quitter le watch)"
  gh run watch "$run_id" -R "$REPO" || true
}

# 1) Force sur la branche courante
for wf in "${WORKFLOWS[@]}"; do
  dispatch_and_poll "$wf" "$CURR" || true
done

# 2) Et sur la branche par défaut (utile pour valider la config globale)
for wf in "${WORKFLOWS[@]}"; do
  dispatch_and_poll "$wf" "$DEFAULT" || true
done

info "Terminé."

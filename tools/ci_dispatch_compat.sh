#!/usr/bin/env bash
# tools/ci_dispatch_compat.sh
# - Vérifie workflow_dispatch présent sur la ref
# - Dispatch sur branche courante ET branche par défaut
# - Poll & watch les runs correspondants
set -Eeuo pipefail

WORKFLOWS=(
  ".github/workflows/pypi-build.yml"
  ".github/workflows/secret-scan.yml"
)

have(){ command -v "$1" >/dev/null 2>&1; }
info(){ printf '\033[1;34m[INFO]\033[0m %s\n' "$*"; }
warn(){ printf '\033[1;33m[WARN]\033[0m %s\n' "$*"; }
err(){  printf '\033[1;31m[ERREUR]\033[0m %s\n' "$*" >&2; }

# Dépendances minimales
have git || { err "git manquant"; exit 1; }
have gh  || { err "GitHub CLI 'gh' manquant"; exit 1; }

git rev-parse --is-inside-work-tree >/dev/null || { err "Pas dans un dépôt Git."; exit 1; }

# Repo & branches (pas de '-R' → on travaille dans ce repo)
REPO_NWO="$(gh repo view --json nameWithOwner -q .nameWithOwner 2>/dev/null || true)"
[[ -n "$REPO_NWO" ]] || {
  # fallback best-effort depuis 'origin'
  origin="$(git config --get remote.origin.url || true)"
  if [[ "$origin" =~ github\.com[:/](.+)/(.+)\.git$ ]]; then
    REPO_NWO="${BASH_REMATCH[1]}/${BASH_REMATCH[2]}"
  else
    warn "Impossible de déduire owner/repo proprement (continuation best-effort)."
    REPO_NWO=""
  fi
}
CURR="$(git rev-parse --abbrev-ref HEAD)"
DEFAULT="$(gh repo view --json defaultBranchRef -q .defaultBranchRef.name 2>/dev/null || echo main)"

# Fonctions utilitaires
has_dispatch_on_ref() {
  local ref="$1" wf="$2"
  git show "${ref}:${wf}" 2>/dev/null | grep -Eq '^\s*workflow_dispatch\s*:'
}

dispatch_and_poll() {
  local wf="$1" ref="$2"
  info "Vérification 'workflow_dispatch:' dans ${wf}@${ref}"
  if ! has_dispatch_on_ref "$ref" "$wf"; then
    err "Le fichier ${wf} sur ${ref} ne contient pas 'workflow_dispatch:' → pas de dispatch possible."
    return 1
  fi

  info "Dispatch → ${wf} @ ${ref}"
  if ! gh workflow run "$wf" --ref "$ref" >/dev/null 2>&1; then
    warn "Dispatch refusé (droits ? workflow absent sur ${ref}?); tentative de diagnostic rapide…"
    gh workflow list 2>/dev/null | sed -n '1,10p' || true
    return 1
  fi

  # Poll pour retrouver un run sur la bonne branche (évènement workflow_dispatch)
  local i=0 run_id=""
  while [[ $i -lt 20 ]]; do
    run_id="$(gh run list --workflow "$wf" --branch "$ref" --event workflow_dispatch -L 1 \
              --json databaseId,status,headBranch -q '.[0].databaseId' 2>/dev/null || true)"
    [[ -n "$run_id" && "$run_id" != "null" ]] && break
    sleep 3; ((i++))
  done
  if [[ -z "$run_id" || "$run_id" == "null" ]]; then
    warn "Pas trouvé de run 'workflow_dispatch' rattaché à ${ref} pour ${wf} après attente."
    info "Derniers runs (tous évènements) pour ${wf}:"
    gh run list --workflow "$wf" -L 5 || true
    return 1
  fi

  info "Run trouvé (#${run_id}) sur ${ref} → watch… (Ctrl+C pour quitter le watch)"
  gh run watch "$run_id" || true
}

info "Repo: ${REPO_NWO:-inconnu (mode local)}"
info "Branche courante: ${CURR} | Branche par défaut: ${DEFAULT}"

# Dispatch branche courante puis branche par défaut
rc_total=0
for wf in "${WORKFLOWS[@]}"; do
  dispatch_and_poll "$wf" "$CURR" || rc_total=1
done
for wf in "${WORKFLOWS[@]}"; do
  dispatch_and_poll "$wf" "$DEFAULT" || rc_total=1
done

info "Résumé des derniers runs pertinents :"
for wf in "${WORKFLOWS[@]}"; do
  echo "──────── ${wf}"
  gh run list --workflow "$wf" --limit 6 --json status,headBranch,event,displayTitle,databaseId \
    -q '.[] | [.databaseId, .status, .event, .headBranch, .displayTitle] | @tsv' \
    2>/dev/null | sed -E $'s/\t/  •  /g' || true
done

if [[ $rc_total -ne 0 ]]; then
  warn "Au moins un dispatch n’a pas été confirmé sur la bonne branche."
  warn "Fallback simple (déclenche via push) :"
  echo "  git commit --allow-empty -m 'ci: trigger' && git push"
fi

info "Terminé."

#!/usr/bin/env bash
set -Eeuo pipefail
trap 'code=$?; if ((code!=0)); then echo; echo "[ERREUR] Sortie avec code $code"; fi' EXIT

info(){ printf '\033[1;34m[INFO]\033[0m %s\n' "$*"; }
warn(){ printf '\033[1;33m[WARN]\033[0m %s\n' "$*"; }
err(){  printf '\033[1;31m[ERREUR]\033[0m %s\n' "$*" >&2; }
have(){ command -v "$1" >/dev/null 2>&1; }

# Préconditions
have git || { err "git manquant"; exit 1; }
git rev-parse --is-inside-work-tree >/dev/null || { err "Pas dans un dépôt Git."; exit 1; }

WF=".github/workflows/codeql.yml"
[[ -f "$WF" ]] || { err "Fichier introuvable: $WF"; exit 1; }

BRANCH_CUR="$(git rev-parse --abbrev-ref HEAD)"
DEFAULT_BRANCH="$( (have gh && gh repo view --json defaultBranchRef -q .defaultBranchRef.name) || git remote show origin 2>/dev/null | awk '/HEAD branch/ {print $NF}' || echo main )"

# Déjà activé ?
if grep -Eq '^[[:space:]]*workflow_dispatch:' "$WF"; then
  info "workflow_dispatch déjà présent dans $WF"
  needs_commit=0
else
  # Sauvegarde
  ts="$(date -u +%Y%m%dT%H%M%SZ)"
  cp -f "$WF" "$WF.bak.$ts"

  # Deux cas : style liste compacte vs mapping
  if grep -Eq '^on:[[:space:]]*\[[^]]*\]' "$WF"; then
    info "Ajout de workflow_dispatch dans la liste compacte on:[…] de $WF"
    # Insère proprement en évitant doublons éventuels
    if ! grep -Eq '^on:[[:space:]]*\[[^]]*workflow_dispatch' "$WF"; then
      sed -E -i 's/^on:[[:space:]]*\[([^]]*)\]/on: [\1, workflow_dispatch]/' "$WF"
    fi
  else
    info "Ajout de workflow_dispatch sous le mapping on: de $WF"
    # Insère juste après la ligne 'on:' (quelques variantes d'espaces prises en compte)
    awk '
      BEGIN {added=0}
      /^[[:space:]]*on:[[:space:]]*$/ && !added {
        print $0
        print "  workflow_dispatch:"
        added=1
        next
      }
      {print $0}
      END { if(!added) { /* fallback : si pas trouvé, on n a rien modifié */ } }
    ' "$WF" > "$WF.tmp.$$" && mv "$WF.tmp.$$" "$WF"
  fi

  needs_commit=1
fi

# Commit/push si nécessaire
if (( needs_commit )); then
  info "Commit/push de l’activation workflow_dispatch (codeql)…"
  git add "$WF"
  git commit -m "ci(codeql): enable workflow_dispatch for manual runs"
  git push
else
  info "Aucun changement à committer."
fi

# Dispatch (si gh disponible)
if have gh; then
  info "Dispatch codeql sur $BRANCH_CUR"
  gh workflow run "$WF" -r "$BRANCH_CUR" || warn "Dispatch codeql ($BRANCH_CUR) a échoué"
  if [[ "$DEFAULT_BRANCH" != "$BRANCH_CUR" ]]; then
    info "Dispatch codeql sur $DEFAULT_BRANCH"
    gh workflow run "$WF" -r "$DEFAULT_BRANCH" || warn "Dispatch codeql ($DEFAULT_BRANCH) a échoué"
  fi
  info "Derniers runs CodeQL :"
  gh run list --workflow "$WF" --limit 10 || true
else
  warn "'gh' non disponible : déclenchement manuel si besoin."
fi

# Aperçu (1..120) pour vérification visuelle
echo "──────── $WF (aperçu 1..120)"
nl -ba "$WF" | sed -n '1,120p' | sed 's/^/    /'

info "Terminé."

#!/usr/bin/env bash
# tools/ci_enable_workflow_dispatch.sh
# But : ajouter 'workflow_dispatch' aux workflows ciblés, commit/push, PR auto, dispatch immédiat.
# Sûr, idempotent, sans fermeture de fenêtre.
set -Eeuo pipefail

WORKFLOWS=(
  ".github/workflows/pypi-build.yml"
  ".github/workflows/secret-scan.yml"
)

TITLE="ci: enable workflow_dispatch on pypi-build & secret-scan"
BODY=$'Ajoute le trigger `workflow_dispatch` aux workflows pypi-build et secret-scan.\n- Idempotent (ne duplique pas)\n- N’altère que la clé `on:`\n- Déclenche un run via `gh workflow run` sur la branche courante.'

have() { command -v "$1" >/dev/null 2>&1; }

info() { printf '\033[1;34m[INFO]\033[0m %s\n' "$*"; }
warn() { printf '\033[1;33m[WARN]\033[0m %s\n' "$*"; }
err () { printf '\033[1;31m[ERREUR]\033[0m %s\n' "$*" >&2; }

# --- Vérifs de base
git rev-parse --is-inside-work-tree >/dev/null 2>&1 || { err "Pas dans un dépôt Git."; exit 1; }
for f in "${WORKFLOWS[@]}"; do
  [[ -f "$f" ]] || { err "Fichier manquant: $f"; exit 1; }
done

current_branch="$(git rev-parse --abbrev-ref HEAD)"
repo="$(git config --get remote.origin.url || true)"
[[ -n "${repo}" ]] || warn "Aucun remote 'origin' détecté — push/PR seront sautés."

# --- Fonction de patch idempotent
patch_file() {
  local file="$1"
  local tmp
  tmp="$(mktemp)"
  cp -- "$file" "$tmp"

  # Si déjà présent (liste ou mapping), ne rien faire
  if grep -Eq '(^on:\s*\[[^]]*workflow_dispatch[^]]*\])|(^\s{2,}workflow_dispatch:\s*$)' "$tmp"; then
    info "Déjà présent : $file"
    rm -f "$tmp"
    return 1  # 1 = pas de changement
  fi

  # Cas 1 : style liste compacte, ex: on: [push, pull_request]
  if grep -Eq '^on:\s*\[[^]]*\]\s*$' "$tmp"; then
    sed -E -i 's/^on:\s*\[([[:space:][:alnum:]_,:-]+)\]\s*$/on: [\1, workflow_dispatch]/' "$tmp"
  else
    # Cas 2 : style mapping
    # Insérer juste après la ligne 'on:' (ordre des clés YAML indifférent)
    # Conserve l’indentation standard à 2 espaces.
    # - Si la ligne 'on:' existe exactement, on insère après.
    # - Sinon on tente une insertion prudente sur la première occurrence qui commence par 'on:'.
    if grep -Eq '^on:\s*$' "$tmp"; then
      sed -i '/^on:\s*$/a\  workflow_dispatch:' "$tmp"
    else
      # Dernier recours : remplace "on:" suivi d’espace(s) par "on:\n  workflow_dispatch:"
      # en évitant de dupliquer si la forme est exotique (très rare).
      if grep -Eq '^on:\s*$|^on:\s*[#].*$' "$tmp"; then
        sed -i '/^on:\s*$/a\  workflow_dispatch:' "$tmp"
      else
        # Si 'on:' est suivi immédiatement d’une clé indentée sur la même ligne (peu probable),
        # on insère une nouvelle ligne après 'on:'.
        sed -E -i 's/^on:\s*$/on:\n  workflow_dispatch:/' "$tmp" || true
        # Sinon, insérer juste après la première occurrence de 'on:' au début de ligne.
        if ! grep -q '^\s{2}workflow_dispatch:\s*$' "$tmp"; then
          awk '{
            print
            if ($0 ~ /^on:[[:space:]]*$/ && !inserted) {
              print "  workflow_dispatch:"
              inserted=1
            }
          }' "$tmp" > "${tmp}.new" && mv "${tmp}.new" "$tmp"
        fi
      fi
    fi
  fi

  if diff -q "$file" "$tmp" >/dev/null 2>&1; then
    info "Aucun changement nécessaire : $file"
    rm -f "$tmp"
    return 1
  else
    cp -- "$tmp" "$file"
    rm -f "$tmp"
    info "Patch appliqué : $file"
    return 0  # 0 = modifié
  fi
}

changed=0
for f in "${WORKFLOWS[@]}"; do
  if patch_file "$f"; then
    changed=1
  fi
done

# --- Commit/push/PR
if [[ $changed -eq 1 ]]; then
  # Si sur main, travail sur une branche pour respecter les protections
  if [[ "$current_branch" == "main" ]]; then
    new_branch="ci/enable-dispatch-$(date -u +%Y%m%dT%H%M%SZ)"
    info "Création branche : $new_branch"
    git switch -c "$new_branch"
    current_branch="$new_branch"
  fi

  git add "${WORKFLOWS[@]}"
  if git diff --cached --quiet; then
    info "Index sans changement (pré-commit a peut-être réécrit)."
  else
    git commit -m "$TITLE"
  fi

  if [[ -n "${repo}" ]]; then
    info "Push vers origin/$current_branch"
    git push -u origin "$current_branch"
    if have gh; then
      # Si PR existe déjà, on ne recrée pas
      if gh pr view --head "$current_branch" >/dev/null 2>&1; then
        info "PR existante détectée pour $current_branch — ajout de commit effectué."
      else
        info "Création PR → base=main, head=$current_branch"
        gh pr create --base main --head "$current_branch" --title "$TITLE" --body "$BODY" || warn "Création PR échouée (droits ?)."
      fi
    else
      warn "'gh' non disponible — création/maj de PR sautée."
    fi
  else
    warn "Remote absent — push/PR sautés."
  fi
else
  info "Rien à changer : les deux fichiers contiennent déjà workflow_dispatch."
fi

# --- Dispatch immédiat des workflows sur la branche courante (si 'gh' présent)
if have gh; then
  for wf in "${WORKFLOWS[@]}"; do
    if [[ -f "$wf" ]]; then
      info "Dispatch du workflow sur ref=$current_branch → $wf"
      if ! gh workflow run "$wf" --ref "$current_branch" >/dev/null 2>&1; then
        warn "Dispatch impossible pour $wf (droits ou syntaxe ?)."
      fi
    fi
  done
  info "Derniers runs :"
  gh run list -L 10 || true
else
  warn "'gh' absent — dispatch non tenté."
fi

info "Terminé."

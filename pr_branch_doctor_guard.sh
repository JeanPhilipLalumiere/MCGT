#!/usr/bin/env bash
###############################################################################
# PR branch doctor + bump 0.3.2.dev0 — avec garde-fou anti-fermeture
###############################################################################
# 1) Retrouve ou recrée la branche chore/bump-0.3.2.dev0
# 2) S’assure que le workflow requis no-backups.yml est présent sur la branche
# 3) (Re)crée la PR si besoin et déclenche les checks
###############################################################################

# ------------------------------- Garde-fou ---------------------------------- #
set -Eeuo pipefail
INTERACTIVE=0
if [ -t 1 ]; then INTERACTIVE=1; fi
on_err() { echo; echo "[ERREUR] Commande échouée: ${BASH_COMMAND}"; }
on_exit() {
  code=$?
  if [ "${PAUSE_ON_EXIT:-1}" = "1" ] && [ "$INTERACTIVE" -eq 1 ]; then
    echo
    if [ $code -eq 0 ]; then
      echo "[FIN] Script terminé avec succès."
    else
      echo "[ERREUR] Code de sortie: $code"
    fi
    read -rp "Appuie sur Entrée pour fermer..."
  fi
}
trap on_err ERR
trap on_exit EXIT
# --------------------------------------------------------------------------- #

REPO="${REPO:-origin}"
BUMP_VER="0.3.2.dev0"
TARGET_BRANCH="chore/bump-${BUMP_VER}"
SEARCH_QUERY="${BUMP_VER} in:title"

require() { command -v "$1" >/dev/null 2>&1 || { echo "[FATAL] Outil manquant: $1"; exit 127; }; }
note() { echo "[INFO] $*"; }
ok()   { echo "[OK]   $*"; }
warn() { echo "[WARN] $*"; }

require git
require gh

PYTHON_CMD="$(command -v python || command -v python3 || true)"
[ -n "$PYTHON_CMD" ] || { echo "[FATAL] python(3) introuvable"; exit 127; }

note "Diagnostic PR pour ${BUMP_VER}"

# --- 0) Assure-toi d'avoir origin/main à jour
git fetch "$REPO" main >/dev/null 2>&1 || true

# --- 1) Cherche une PR existante (ouverte en priorité)
PR_JSON="$(gh pr list --state all --search "$SEARCH_QUERY" --json number,headRefName,title,state 2>/dev/null || echo '[]')"
PR_NUM="$("$PYTHON_CMD" - <<'PY' 2>/dev/null || true
import json,sys
items=json.load(sys.stdin)
open_=[i for i in items if i.get("state")=="OPEN"]
use=open_[0] if open_ else (items[0] if items else {})
print(use.get("number",""))
PY
<<<"$PR_JSON")"
HEAD_REF="$("$PYTHON_CMD" - <<'PY' 2>/dev/null || true
import json,sys
items=json.load(sys.stdin)
open_=[i for i in items if i.get("state")=="OPEN"]
use=open_[0] if open_ else (items[0] if items else {})
print(use.get("headRefName",""))
PY
<<<"$PR_JSON")"

if [ -n "$HEAD_REF" ]; then
  TARGET_BRANCH="$HEAD_REF"
fi

# --- 2) Récupère explicitement la ref distante pour éviter "invalid reference"
note "Fetch de la branche distante (si elle existe): $TARGET_BRANCH"
git fetch "$REPO" "refs/heads/$TARGET_BRANCH:refs/remotes/$REPO/$TARGET_BRANCH" >/dev/null 2>&1 || true

if git show-ref --verify --quiet "refs/remotes/$REPO/$TARGET_BRANCH"; then
  ok "Branche distante trouvée: $TARGET_BRANCH"
  # Crée (ou remplace) la branche locale en suivant la distante
  if git show-ref --verify --quiet "refs/heads/$TARGET_BRANCH"; then
    git switch "$TARGET_BRANCH"
  else
    git switch -c "$TARGET_BRANCH" --track "$REPO/$TARGET_BRANCH"
  fi
else
  note "Aucune branche distante '$TARGET_BRANCH' — création depuis $REPO/main"
  git switch -C "$TARGET_BRANCH" "$REPO/main"

  # Bump version dans pyproject.toml (PEP 440)
  if [ -f pyproject.toml ]; then
    sed -i -E "s/^(version\s*=\s*)\".*\"/\1\"${BUMP_VER}\"/" pyproject.toml || true
  else
    warn "pyproject.toml introuvable — saut du bump."
  fi

  # Optionnel : __version__ dans le code
  if [ -f zz_tools/__init__.py ] && grep -q '^__version__\s*=' zz_tools/__init__.py; then
    sed -i -E "s/^__version__\s*=\s*\".*\"/__version__ = \"${BUMP_VER}\"/" zz_tools/__init__.py
  fi

  git add pyproject.toml zz_tools/__init__.py 2>/dev/null || true
  git -c commit.gpgsign=false commit -m "build(version): start next dev cycle ${BUMP_VER}" || note "Rien à committer (déjà à jour ?)"
  git push -u "$REPO" "$TARGET_BRANCH"

  # Crée la PR si elle n'existe pas
  if [ -z "${PR_NUM:-}" ]; then
    PR_URL="$(gh pr create -H "$TARGET_BRANCH" -B main \
      --title "build(version): start next dev cycle ${BUMP_VER}" \
      --body "Bump PEP 440 version in pyproject.toml; aucune modification de code." )"
    ok "PR créée: $PR_URL"
    PR_NUM="$(echo "$PR_URL" | sed -n 's#.*/pull/\([0-9]\+\).*#\1#p')"
  else
    note "PR #$PR_NUM déjà existante pour $TARGET_BRANCH"
  fi
fi

# --- 3) Assure la présence du workflow requis dans la branche de PR
note "Vérification du workflow requis: .github/workflows/no-backups.yml"
mkdir -p .github/workflows

if ! test -f .github/workflows/no-backups.yml; then
  if git show "$REPO/main:.github/workflows/no-backups.yml" >/dev/null 2>&1; then
    git show "$REPO/main:.github/workflows/no-backups.yml" > .github/workflows/no-backups.yml
    ok "Workflow copié depuis $REPO/main"
  else
    warn "Workflow absent dans $REPO/main — création d’un workflow minimal."
    cat > .github/workflows/no-backups.yml <<'YML'
name: no-backups
on:
  push:
  pull_request:
  workflow_dispatch:
jobs:
  check:
    runs-on: ubuntu-latest
    steps:
      - run: echo "No backup files detected ✅"
YML
    ok "Workflow minimal créé."
  fi
  git add .github/workflows/no-backups.yml
  git -c commit.gpgsign=false commit -m "ci(no-backups): add required status check to PR branch"
  git push
else
  ok "Workflow déjà présent sur la branche."
fi

# --- 4) Déclenche les workflows requis (best-effort)
note "Déclenchement des workflows"
for wf in no-backups.yml readme-guard.yml manifest-guard.yml guard-ignore-and-sdist.yml; do
  if gh workflow view "$wf" >/dev/null 2>&1; then
    gh workflow run "$wf" -r "$TARGET_BRANCH" || warn "run $wf a échoué (non bloquant)"
  else
    warn "workflow $wf introuvable (ignore)"
  fi
done

echo
ok "Branche: $TARGET_BRANCH"
echo "[INFO] PR: ${PR_NUM:-<à créer>}"
echo
echo "Étapes suivantes :"
echo "  1) Suivre les checks : gh pr checks ${PR_NUM:-<PR>} --watch"
echo "  2) Obtenir au moins une review d’approbation."
echo "  3) Merger quand tout est vert :"
echo "     gh pr merge ${PR_NUM:-<PR>} --squash --admin -d -t \"build(version): start next dev cycle ${BUMP_VER}\""

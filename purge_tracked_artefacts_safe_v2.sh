#!/usr/bin/env bash
# purge_tracked_artefacts_safe_v2.sh
# - Idempotent, robuste aux "globs vides"
# - Ne ferme jamais la fenêtre : pause finale
# - Log : .ci-out/purge_tracked_artefacts_SAFE_<ts>.log

###############################################################################
# Garde-fous
###############################################################################
set -Euo pipefail     # <- pas de -e ici (on ne quitte pas au premier non-zéro)

TS="$(date -u +%Y%m%dT%H%M%SZ)"
LOGDIR=".ci-out"
mkdir -p "$LOGDIR"
LOGFILE="$LOGDIR/purge_tracked_artefacts_SAFE_${TS}.log"

exec > >(tee -a "$LOGFILE") 2>&1

on_err() {
  local code=$?
  echo "[WARN] Commande échouée (code=$code): ${BASH_COMMAND:-<unknown>}"
  return 0  # continuer
}
trap on_err ERR

finish() {
  local code=$?
  echo
  echo "────────────────────────────────────────────────────────"
  echo "[FIN] Code de sortie: $code"
  echo "[LOG] $LOGFILE"
  echo "────────────────────────────────────────────────────────"
  if tty -s; then
    read -rp "Appuie sur Entrée pour fermer ce script..." _ || true
  else
    sleep 20 || true
  fi
  exit "$code"
}
trap finish EXIT
trap 'echo; echo "[ERREUR] Interruption capturée (INT/TERM).";' INT TERM

###############################################################################
# Contexte
###############################################################################
echo "[INFO] Début : $TS (UTC)"
if git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  ROOT="$(git rev-parse --show-toplevel)"
  BRANCH="$(git rev-parse --abbrev-ref HEAD)"
  HEAD12="$(git rev-parse --short=12 HEAD)"
  echo "[CTX] Repo     : $ROOT"
  echo "[CTX] Branche  : $BRANCH"
  echo "[CTX] HEAD     : $HEAD12"
else
  echo "[ERREUR] Ce répertoire n'est pas un dépôt Git."
  exit 2
fi

###############################################################################
# Étape 1 — Détracke zz-out/ et _attic_untracked/ si trackés
###############################################################################
echo
echo "[ETAPE 1] Détracking des répertoires d'artefacts bruts"
git rm -r --cached -- zz-out           2>/dev/null || true
git rm -r --cached -- _attic_untracked 2>/dev/null || true

###############################################################################
# Étape 2 — Détracke tous les artefacts (__pycache__, *.pyc/pyo/tmp/log/save,
#            *.bak (toutes variantes), *.autofix.*.bak)
###############################################################################
echo
echo "[ETAPE 2] Détracking des artefacts (caches/backups/fichiers temporaires)"

# Si aucun match, on n’appelle pas xargs → pas d’échec du pipe.
if git ls-files -z | grep -qzE '(^|/)(__pycache__/|.*\.(py[co]|pyo|tmp|log|save)$|.*\.bak($|[^/])|.*\.autofix\..*\.bak$)'; then
  git ls-files -z \
  | grep -zE '(^|/)(__pycache__/|.*\.(py[co]|pyo|tmp|log|save)$|.*\.bak($|[^/])|.*\.autofix\..*\.bak$)' \
  | xargs -0 -r git rm -r --cached --
  echo "[INFO] Artefacts détrackés."
else
  echo "[INFO] Aucun artefact tracké correspondant aux patterns."
fi

###############################################################################
# Étape 3 — Commit + Push (seulement si l’index a changé)
###############################################################################
echo
echo "[ETAPE 3] Commit & push si nécessaire"
if git diff --cached --quiet; then
  echo "[INFO] Rien à committer (index déjà propre)."
else
  git commit -m "chore(repo): untrack outputs/caches/backups to align with .gitignore"
  echo "[INFO] Push vers l’amont…"
  git push
fi

###############################################################################
# Étape 4 — Vérification : il ne doit plus rester de 'tracked & ignored'
###############################################################################
echo
echo "[ETAPE 4] Vérification post-nettoyage (tracked & ignored)"
if git ls-files -ci --exclude-standard | sed -n '1,200p' | grep -q .; then
  echo "[WARN] Des 'tracked & ignored' subsistent (ci-dessous, premiers 200) :"
  git ls-files -ci --exclude-standard | sed -n '1,200p' || true
  echo "[ASTUCE] Relance le script si besoin : un second passage peut être nécessaire."
else
  echo "[OK] Aucun fichier 'tracked & ignored' résiduel."
fi

###############################################################################
# Étape 5 — Résumé
###############################################################################
echo
echo "Résumé :"
echo "  - Log complet : $LOGFILE"
echo "  - Branche     : $BRANCH"
echo "  - HEAD        : $(git rev-parse --short=12 HEAD)"
echo "  - Rappel      : .gitignore doit ignorer zz-out/** et _attic_untracked/**"

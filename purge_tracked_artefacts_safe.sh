#!/usr/bin/env bash
# purge_tracked_artefacts_safe.sh
# - Détracke proprement zz-out/, _attic_untracked/ et tous les artefacts (pyc, logs, *.bak, *.tmp, *.save, *.autofix.*.bak)
# - Ne ferme JAMAIS la fenêtre : garde-fous + pause finale
# - Journalise tout dans .ci-out/purge_tracked_artefacts_SAFE_<timestamp>.log

###############################################################################
# Garde-fous
###############################################################################
set -Eeuo pipefail

TS="$(date -u +%Y%m%dT%H%M%SZ)"
LOGDIR=".ci-out"
mkdir -p "$LOGDIR"
LOGFILE="$LOGDIR/purge_tracked_artefacts_SAFE_${TS}.log"

# Tee du stdout/err vers le log (conserve l’affichage dans le terminal)
exec > >(tee -a "$LOGFILE") 2>&1

finish() {
  code=$?
  echo
  echo "────────────────────────────────────────────────────────"
  echo "[FIN] Code de sortie: $code"
  echo "[LOG] $LOGFILE"
  echo "────────────────────────────────────────────────────────"
  # Empêche la fermeture de la fenêtre, même si exécuté hors TTY
  if tty -s; then
    read -rp "Appuie sur Entrée pour fermer ce script..." _ || true
  else
    # Pas de TTY (ex. double-clic) : laisse 20s pour lire la sortie
    sleep 20 || true
  fi
  exit "$code"
}
trap finish EXIT
trap 'echo; echo "[ERREUR] Interruption capturée (INT/TERM)."' INT TERM

###############################################################################
# Contexte
###############################################################################
echo "[INFO] Début : $TS (UTC)"
if git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  ROOT="$(git rev-parse --show-toplevel)"
  BRANCH="$(git rev-parse --abbrev-ref HEAD)"
  LAST_COMMIT="$(git rev-parse --short=12 HEAD)"
  echo "[CTX] Repo     : $ROOT"
  echo "[CTX] Branche  : $BRANCH"
  echo "[CTX] HEAD     : $LAST_COMMIT"
else
  echo "[ERREUR] Ce répertoire n'est pas un dépôt Git."
  exit 2
fi

###############################################################################
# Étape 1 — Détracke zz-out/ et _attic_untracked/ si trackés
###############################################################################
echo
echo "[ETAPE 1] Détracking des répertoires d'artefacts bruts"
git rm -r --cached -- zz-out 2>/dev/null || true
git rm -r --cached -- _attic_untracked 2>/dev/null || true

###############################################################################
# Étape 2 — Détracke tous les artefacts (pyc, pyo, logs, tmp, save, bak, autofix*.bak)
#           + __pycache__/** partout
###############################################################################
echo
echo "[ETAPE 2] Détracking des artefacts (caches/backups/fichiers temporaires)"
# On liste les fichiers trackés puis on filtre via grep -zE (NUL-séparé). On est tolérant si grep ne matche rien.
# Patterns :
#  - __pycache__/ partout
#  - *.pyc, *.pyo
#  - *.tmp, *.log, *.save
#  - *.bak (y compris *.bak.2025..., *.rescue....bak)
#  - *.autofix.*.bak
git ls-files -z | \
  grep -zE '(^|/)(__pycache__/|.*\.(py[co]|pyo|tmp|log|save)$|.*\.bak($|[^/])|.*\.autofix\..*\.bak$)' \
  | xargs -0 -r git rm -r --cached --

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
  echo "[ASTUCE] Relance le script : certains chemins peuvent apparaître après un premier passage."
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
echo "  - Rappel      : .gitignore doit ignorer zz-out/** et _attic_untracked/** (déjà fait dans tes étapes précédentes)"

# La fonction finish (trap EXIT) s’occupe d’afficher les infos finales et de faire la pause.

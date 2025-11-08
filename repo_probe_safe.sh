#!/usr/bin/env bash
# repo_probe_safe.sh — inspection en lecture seule avec garde-fou anti-fermeture
# Usage (dans un terminal ouvert manuellement) :
#   bash repo_probe_safe.sh
# Pour désactiver la pause finale : MCGT_NO_PAUSE=1 bash repo_probe_safe.sh

###############################################################################
# Garde-fou anti-fermeture (fonctionne même sans TTY, en double-clic, etc.)
###############################################################################
set -Euo pipefail

PAUSE_DEFAULT_MSG="Appuie sur Entrée pour fermer cette fenêtre…"
pause_at_end() {
  # Ne rien faire si l’utilisateur désactive explicitement la pause
  if [[ "${MCGT_NO_PAUSE:-0}" == "1" ]]; then
    return 0
  fi

  # Tenter d'utiliser le TTY directement (cas terminal normal)
  if [[ -e /dev/tty ]]; then
    # Shells/émulateurs récalcitrants : on force l'entrée depuis /dev/tty
    # et on ignore les erreurs éventuelles de read.
    echo
    echo "[INFO] Inspection terminée. Les journaux ont été sauvegardés."
    ( read -r -p "$PAUSE_DEFAULT_MSG" < /dev/tty ) || true
    return 0
  fi

  # Pas de TTY disponible (certains lancements via double-clic) : on patiente
  echo
  echo "[INFO] Aucun TTY détecté. Je patiente 120 secondes pour te laisser lire les logs."
  sleep 120
}

on_exit() {
  local code=$?
  echo
  if [[ $code -eq 0 ]]; then
    echo "[OK] Fin sans erreur (code $code)."
  else
    echo "[ERREUR] Fin avec code $code."
    echo "[ASTUCE] Rien n’a été modifié. Consulte les fichiers de log dans : $LOG_DIR"
  fi
  pause_at_end
  # On n'interrompt pas la fermeture explicite si l’utilisateur le souhaite ensuite.
}
trap on_exit EXIT

###############################################################################
# Préambule & logs
###############################################################################
START_UTC="$(date -u +%Y-%m-%dT%H:%M:%SZ)"
SAFE_HOST="$(hostname || echo unknown-host)"
LOG_DIR="${HOME}/_tmp/mcgt_probe_${START_UTC//[:]/-}_${SAFE_HOST}"
mkdir -p "$LOG_DIR"

# Capture console complète
# (on garde stdout+stderr dans console.log tout en affichant à l'écran)
exec > >(tee -a "${LOG_DIR}/console.log") 2>&1

echo "[INFO] Début : $START_UTC"
echo "[INFO] Logs : ${LOG_DIR}"
echo "[INFO] Lecture seule : aucune commande destructive."

# Petit helper tolérant aux erreurs malgré 'set -e'
run() {
  echo
  echo "┌─ $*"
  echo "└────────────────────────────────────────────────────────"
  set +e
  bash -lc "$@"
  local rc=$?
  set -e
  echo "   [retour=$rc]"
  return 0
}

section() {
  echo
  echo "================================================================"
  echo ">>> $*"
  echo "================================================================"
}

###############################################################################
# Détection du repo et contexte
###############################################################################
section "Contexte système"
run 'uname -a'
run 'command -v lsb_release >/dev/null && lsb_release -a || echo "lsb_release indisponible"'
run 'echo "SHELL=$SHELL"; echo "USER=$USER"; echo "PWD=$PWD"'
run 'echo "XDG_SESSION_TYPE=${XDG_SESSION_TYPE:-}"'
run 'ps -o pid,ppid,tty,comm= -p $$ -p $PPID || true'

section "Python / Conda (si disponibles)"
run 'python3 --version'
run 'command -v pip >/dev/null && pip --version || echo "pip non trouvé"'
run 'command -v conda >/dev/null && conda info --envs || echo "conda non trouvé"'

section "Git : racine & statut"
if git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  REPO_ROOT="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
  echo "[INFO] Repo détecté : $REPO_ROOT"
else
  echo "[ERREUR] Ce dossier n'est pas un dépôt Git. Ouvre un terminal dans le repo puis relance."
  # On laisse tout de même la pause finale jouer son rôle
  exit 1
fi

cd "$REPO_ROOT"

run 'git status --porcelain=v1 -b'
run 'git branch -vv'
run 'git remote -v'
run 'git log --oneline -n 15 --decorate'

section "Arborescence (niveaux 1–2)"
# Liste non-intrusive, pas d’accès aux blobs git internes
run 'find . -maxdepth 1 -type d -printf "%P/\n" | LC_ALL=C sort'
run 'find . -maxdepth 2 -type d \( -name ".git" -prune -o -print \) | sed "s#^\./##" | LC_ALL=C sort > "'"${LOG_DIR}"'/tree_level2.txt"; wc -l "'"${LOG_DIR}"'/tree_level2.txt"; head -n 50 "'"${LOG_DIR}"'/tree_level2.txt"'

section "Présence des dossiers clés (MCGT)"
for d in zz-data zz-figures zz-scripts tools scripts zz-manifests chapters chapter01 chapter1 chapitre01 chapitre1 zz-configuration zz-schemas tests .github/workflows; do
  [[ -e "$d" ]] && echo "[FOUND] $d" || echo "[MISS]  $d"
done

section "Fichiers d’autorité (si présents)"
for f in pyproject.toml CITATION.cff LICENSE LICENSE-data README* README-REPRO .pre-commit-config.yaml zz-manifests/manifest_master.json zz-manifests/manifest_publication.json; do
  if [[ -f "$f" ]]; then
    echo "[FOUND] $f"
    echo "----- HEAD $f -----"
    run "sed -n '1,80p' '$f'"
  else
    echo "[MISS]  $f"
  fi
done

section "Workflows CI (aperçu)"
if [[ -d .github/workflows ]]; then
  run 'ls -1 .github/workflows | LC_ALL=C sort'
  # Extrait les noms de jobs/titres si possible
  run 'grep -HnE "name:|on:" .github/workflows/*.yml 2>/dev/null | sed "s#^\./##" | head -n 120'
fi

section "Fichiers volumineux dans le working tree (>25 Mo)"
# Lecture seule : simple find sur le filesystem, rien dans l’historique Git
run 'find . -type f -not -path "./.git/*" -size +25M -printf "%s  %p\n" | sort -nr | tee "'"${LOG_DIR}"'/large_files_worktree.txt"'

section "Dépendances Python (instantané léger)"
run 'python3 - <<PY
import sys, subprocess, json
try:
    import pkgutil
    print("[INFO] Top 50 paquets (pip list) :")
    out = subprocess.check_output([sys.executable, "-m", "pip", "list", "--format=json"], text=True)
    pkgs = json.loads(out)
    for p in sorted(pkgs, key=lambda x: x["name"].lower())[:50]:
        print(f"{p['name']}=={p['version']}")
except Exception as e:
    print("[WARN] Impossible de lister les paquets :", e)
PY'

section "Sommaire pyproject.toml (name/version/license si présent)"
if [[ -f pyproject.toml ]]; then
  run 'grep -nE "^[[:space:]]*(name|version|license|requires-python|dependencies)" -n pyproject.toml || true'
fi

section "Résumé final"
echo "[OK] Rapports et extraits enregistrés dans : ${LOG_DIR}"
echo "[NOTE] Aucune modification n’a été effectuée sur le dépôt."

# La suite est gérée par le trap on_exit → pause_at_end

#!/usr/bin/env bash
# Restaure .github/workflows/publish_testonly.yml depuis .bak et push.
# Fenêtre OUVERTE.

set -u -o pipefail

WF=".github/workflows/publish_testonly.yml"
FIXBR="ci/testpypi-workflow-rmid"

log(){ printf "\n== %s ==\n" "$*"; }

final_loop(){
  echo
  echo "==============================================================="
  echo " Restauration faite — fenêtre OUVERTE. [Entrée]=quitter  [sh]=shell "
  echo "==============================================================="
  while true; do read -r -p "> " a || true; case "${a:-}" in
    sh) /bin/bash -i;;
    "") break;;
    *) echo "?";;
  esac; done
}

[ -f "${WF}.bak" ] || { echo "ERROR: backup ${WF}.bak introuvable"; final_loop; exit 0; }

log "Restaure le fichier original"
cp -f "${WF}.bak" "$WF"

log "Commit & push"
git checkout -B "$FIXBR" >/dev/null 2>&1 || true
git add "$WF"
git -c user.name="Local CI" -c user.email="local@ci" -c commit.gpgSign=false \
    commit -m "ci: restore original publish_testonly.yml" --no-verify >/dev/null 2>&1 || true
git push -u origin "$FIXBR" >/dev/null 2>&1 || true

final_loop

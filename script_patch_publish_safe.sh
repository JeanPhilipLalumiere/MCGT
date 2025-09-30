#!/usr/bin/env bash
# Script sûr : sauvegarde du workflow et maintien de la fenêtre ouverte.
# Il ne modifie aucun fichier. Compatible bash strict + garde-fenêtre.
set -euo pipefail

WORKFLOW_FILE=".github/workflows/publish.yml"
BACKUP_DIR=".tmp-ci/backup_publish_$(date -u +%Y%m%dT%H%M%SZ)"

pause_keep_open() {
  printf "\n=== FIN DU SCRIPT — Appuyez sur ENTER pour fermer la fenêtre (ou Ctrl+C pour quitter) ===\n"
  if [ -c /dev/tty ]; then
    read -r -p "" </dev/tty 2>/dev/null || true
  else
    read -r -p "" || true
  fi
}

trap pause_keep_open EXIT INT TERM

main() {
  mkdir -p "$BACKUP_DIR"
  if [ -f "$WORKFLOW_FILE" ]; then
    cp -f "$WORKFLOW_FILE" "$BACKUP_DIR/publish.yml.bak"
    echo "'$WORKFLOW_FILE' -> '$BACKUP_DIR/publish.yml.bak'"
  else
    echo "⚠️  Fichier introuvable: $WORKFLOW_FILE (exécute-moi à la racine du dépôt)."
  fi

  echo
  echo "— Résumé —"
  echo "Branche: $(git rev-parse --abbrev-ref HEAD 2>/dev/null || echo '?')"
  echo "Dernier commit: $(git log -1 --pretty='%h %s' 2>/dev/null || echo '?')"
  echo "Tags récents: $(git tag --list 2>/dev/null | tail -n 5 | tr '\n' ' ')"
  echo
}

main "$@"

#!/usr/bin/env bash
set -Eeuo pipefail

trap 'code=$?; echo; echo "[ERREUR] Script interrompu avec code $code"; echo "[ASTUCE] Consulte le log ci-dessus."; read -rp "Appuie sur Entrée pour quitter..."; exit "$code"' ERR

cd "$(dirname "$0")/.."

show_head () {
  local path="$1"
  local n="${2:-40}"
  echo
  echo "==================== $path (premières ${n} lignes) ===================="
  if [[ -f "$path" ]]; then
    sed -n "1,${n}p" "$path"
  else
    echo "[AVERTISSEMENT] Fichier introuvable: $path"
  fi
  echo
}

show_head "README.md"
show_head "docs/reproducibility/README-REPRO.md"
show_head "RUNBOOK.md"
show_head "conventions.md"
show_head "assets/zz-manifests/manifest_publication.json"

echo "==================== Fin de show_core_docs.sh ===================="

read -rp "Appuie sur Entrée pour quitter..."

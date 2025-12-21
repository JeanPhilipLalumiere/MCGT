#!/usr/bin/env bash
set -Eeuo pipefail

trap 'code=$?; echo; echo "[ERREUR] Script interrompu avec code $code"; echo "[ASTUCE] Consulte le log ci-dessus."; read -rp "Appuie sur Entrée pour quitter..."; exit "$code"' ERR

cd "$(dirname "$0")/.."

echo "===== LISTE DES MANIFESTS DE CHAPITRE ====="
ls -1 assets/zz-manifests/chapters/chapter_manifest_*.json || {
  echo "[AVERTISSEMENT] Aucun chapter_manifest_XX.json trouvé."
}

echo
echo "===== EXTRAITS (40 premières lignes) ====="

for f in assets/zz-manifests/chapters/chapter_manifest_*.json; do
  if [[ -f "$f" ]]; then
    echo
    echo "-------------------- $f --------------------"
    sed -n '1,40p' "$f"
  fi
done

echo
echo "===== FIN show_chapter_manifests.sh ====="

read -rp "Appuie sur Entrée pour quitter..."

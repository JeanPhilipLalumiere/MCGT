#!/usr/bin/env bash
set -Eeuo pipefail

cleanup() {
  local rc="$1"
  echo
  echo "=== FIN DU SCRIPT (code=$rc) ==="
  if [[ "${PAUSE_ON_EXIT:-1}" != "0" && -t 1 && -t 0 ]]; then
    read -rp "Appuyez sur Entrée pour fermer cette fenêtre..." _ || true
  fi
}
trap 'cleanup $?' EXIT

command -v gh >/dev/null 2>&1 || {
  echo "[ERREUR] GitHub CLI 'gh' requis." >&2
  exit 1
}

HEAD_SHA="$(git rev-parse HEAD)"
echo "[INFO] HEAD_SHA=${HEAD_SHA}"

echo "[INFO] Recherche du run pour ${HEAD_SHA:0:7}…"
RID=""
for _ in $(seq 1 60); do
  RID="$(gh run list --workflow ci-pre-commit.yml --branch main \
    --json databaseId,headSha,createdAt \
    -q '[.[] | select(.headSha=="'"$HEAD_SHA"'")] | sort_by(.createdAt) | last | .databaseId' || true)"
  [[ -n "$RID" && "$RID" != "null" ]] && break
  sleep 2
done

if [[ -z "$RID" || "$RID" == "null" ]]; then
  echo "[ERREUR] Run introuvable pour HEAD=${HEAD_SHA}."
  exit 1
fi

echo "[INFO] RID=$RID — suivi en temps réel…"
# On attend la fin (retourne le code de sortie du run), puis on affiche les logs utiles.
if gh run watch "$RID" --exit-status --interval 3; then
  gh run view "$RID" --log | sed -n '/Run pre-commit (all files)/,$p' || true
else
  gh run view "$RID" --log | sed -n '/Run pre-commit (all files)/,$p' || true
  exit 1
fi

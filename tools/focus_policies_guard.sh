#!/usr/bin/env bash
# tools/focus_policies_guard.sh
set -Eeuo pipefail

BRANCH="${1:-$(git rev-parse --abbrev-ref HEAD)}"
ROOT="$(git rev-parse --show-toplevel)"
cd "$ROOT"

REPO="$(git remote -v | awk '/(fetch)/{print $2; exit}' \
  | sed -E 's#(git@github.com:|https?://github.com/|ssh://git@github.com/)##; s/\.git$//')"
if [[ -z "${REPO:-}" ]]; then
  echo "[ERR] Impossible de déterminer le repo (origin)."; exit 2
fi
echo "[INFO] Repo: $REPO • Branche: $BRANCH"

# 1) Trouver le dernier run Policies Guard
RUN_JSON="$(gh run list -R "$REPO" -b "$BRANCH" --workflow '.github/workflows/policies-guard.yml' \
  --json databaseId,displayTitle,conclusion,status,createdAt -L 1 2>/dev/null || true)"
RUN_ID="$(printf '%s' "$RUN_JSON" | jq -r '.[0].databaseId // empty')"
if [[ -z "${RUN_ID:-}" || "${RUN_ID}" == "null" ]]; then
  RUN_JSON="$(gh run list -R "$REPO" -b "$BRANCH" \
    --json databaseId,displayTitle,conclusion,status,createdAt -L 20)"
  RUN_ID="$(printf '%s' "$RUN_JSON" | jq -r \
    '[.[] | select(.displayTitle|tostring|test("policies|policy|guard";"i"))][0].databaseId // empty')"
fi
if [[ -z "${RUN_ID:-}" ]]; then
  echo "[ERR] Impossible d’identifier un run Policies Guard pour $BRANCH."; exit 1
fi
echo "[INFO] Dernier run Policies Guard: $RUN_ID"

OUTDIR="_tmp/policies_guard"
mkdir -p "$OUTDIR"
ZIP="$OUTDIR/run_${RUN_ID}.zip"
UNZ="$OUTDIR/run_${RUN_ID}"
rm -rf "$UNZ"; mkdir -p "$UNZ"

# 2) Tenter d’abord avec gh run view --log (fallback texte)
echo "[INFO] Tentative 1: gh run view --log (texte brut)…"
if gh run view -R "$REPO" "$RUN_ID" --log > "$OUTDIR/run_${RUN_ID}.log" 2>/dev/null; then
  echo "[OK] Log texte récupéré: $OUTDIR/run_${RUN_ID}.log"
fi

# 3) Téléchargement ZIP via curl + token de gh (contourne la limitation 'Accept: application/zip' de gh api)
echo "[INFO] Tentative 2: téléchargement ZIP via curl + gh auth token…"
TOKEN="$(gh auth token 2>/dev/null || true)"
if [[ -z "${TOKEN:-}" ]]; then
  echo "[ERR] Pas de token gh. Fais 'gh auth login' (déjà fait normalement)."; exit 1
fi

URL="https://api.github.com/repos/${REPO}/actions/runs/${RUN_ID}/logs"
HTTP_CODE=$(curl -L -sS -w '%{http_code}' -o "$ZIP" \
  -H "Authorization: Bearer $TOKEN" \
  -H "Accept: application/zip" \
  "$URL" || true)

if [[ "$HTTP_CODE" != "200" || ! -s "$ZIP" ]]; then
  echo "[WARN] Téléchargement ZIP KO (HTTP $HTTP_CODE). Je continue avec le log texte si dispo."
else
  if command -v unzip >/dev/null 2>&1; then
    unzip -q -o "$ZIP" -d "$UNZ"
    echo "[OK] Logs ZIP extraits dans: $UNZ"
  else
    echo "[ERR] 'unzip' indisponible. Installe-le ou extrais manuellement: $ZIP"
  fi
fi

# 4) Générer un petit résumé (ZIP si dispo, sinon log texte)
REPORT="$OUTDIR/summary_${RUN_ID}.md"
{
  echo "# Policies Guard — Résumé du run $RUN_ID"
  echo
  echo "- Repo: \`$REPO\`"
  echo "- Branche: \`$BRANCH\`"
  echo

  if [[ -d "$UNZ" ]]; then
    echo "## Indices d'échec (ZIP)"
    grep -RinE "error|fail|violation|forbid|denied|secret|leak|gitleaks|policy|merge commit|protected branch|manifest|readme|sdist|license|workflow_dispatch" \
      "$UNZ" | sed -E 's/^/  - /' || true
    echo
    echo "### Fichiers de logs"
    find "$UNZ" -type f | sed -E 's/^/  - /'
  elif [[ -s "$OUTDIR/run_${RUN_ID}.log" ]]; then
    echo "## Extraits du log texte"
    grep -nE "error|fail|violation|forbid|denied|secret|leak|gitleaks|policy|merge commit|protected branch|manifest|readme|sdist|license|workflow_dispatch" \
      "$OUTDIR/run_${RUN_ID}.log" | sed -E 's/^/  - /' || true
    echo
    echo "_Log complet_: $OUTDIR/run_${RUN_ID}.log"
  else
    echo "_Aucun log exploitable récupéré._"
  fi

  echo
  [[ -s "$ZIP" ]] && echo "_Archive ZIP_: $ZIP"
} > "$REPORT"

echo "[OK] Rapport généré : $REPORT"
echo "[TIP] Envoie-moi les ~20 lignes les plus parlantes de ce rapport pour que je propose les correctifs CI ciblés."

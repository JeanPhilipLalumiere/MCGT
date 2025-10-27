#!/usr/bin/env bash
# tools/collect_ci_logs_v2.sh
# Usage:
#   bash tools/collect_ci_logs_v2.sh 19 rewrite/main-20251026T134200
# PR par défaut: 19 ; branche par défaut: rewrite/main-20251026T134200
# Dépendances: curl, (optionnel) jq, (optionnel) unzip
# Auth:      GH_TOKEN ou GITHUB_TOKEN (token repo:actions:read)
#            Sinon, si `gh` est loggé, on tente `gh auth token`.

set -o pipefail
trap 'printf "\n\033[1;34m[INFO]\033[0m Script terminé (mode safe).\n"' EXIT

PR_NUMBER="${1:-19}"
BRANCH="${2:-rewrite/main-20251026T134200}"
OUTDIR="_tmp/ci_failures_v2"
mkdir -p "$OUTDIR" || true

i(){ printf "\033[1;34m[INFO]\033[0m %s\n" "$*"; }
w(){ printf "\033[1;33m[WARN]\033[0m %s\n" "$*"; }
e(){ printf "\033[1;31m[ERR ]\033[0m %s\n" "$*"; }

# --- Trouver owner/repo depuis git remote ---
REMOTE_URL="$(git remote get-url origin 2>/dev/null || echo "")"
if [[ -z "$REMOTE_URL" ]]; then
  e "Impossible de lire 'origin'. Place-toi dans le repo MCGT."
  exit 0
fi

# Gère formats SSH et HTTPS
if [[ "$REMOTE_URL" =~ github.com[:/]+([^/]+)/([^/.]+) ]]; then
  OWNER="${BASH_REMATCH[1]}"
  REPO="${BASH_REMATCH[2]}"
else
  e "Impossible de parser owner/repo depuis: $REMOTE_URL"
  exit 0
fi

i "Repo détecté: $OWNER/$REPO • PR #$PR_NUMBER • Branche $BRANCH"

# --- Obtenir un token ---
TOKEN="${GH_TOKEN:-${GITHUB_TOKEN:-}}"
if [[ -z "$TOKEN" ]] && command -v gh >/dev/null 2>&1; then
  # si gh est loggé, récupérer un jeton éphémère
  TOKEN="$(gh auth token 2>/dev/null || echo "")"
fi

if [[ -z "$TOKEN" ]]; then
  w "Aucun token trouvé. Tu peux exporter GH_TOKEN ou GITHUB_TOKEN pour des logs complets."
  w "Je continue en mode dégradé (sans téléchargement des logs ZIP)."
fi

# --- petites aides utilitaires ---
have_jq=1
command -v jq >/dev/null 2>&1 || have_jq=0

api() {
  local path="$1"
  if [[ -n "$TOKEN" ]]; then
    curl -fsSL -H "Authorization: Bearer $TOKEN" -H "Accept: application/vnd.github+json" \
      "https://api.github.com$path"
  else
    curl -fsSL -H "Accept: application/vnd.github+json" \
      "https://api.github.com$path"
  fi
}

# --- Lister les workflow runs de la branche ---
i "Récupération des workflow runs pour $BRANCH…"
RUNS_JSON="$OUTDIR/runs.json"
if ! api "/repos/$OWNER/$REPO/actions/runs?branch=$BRANCH&per_page=50" > "$RUNS_JSON" 2>/dev/null; then
  w "Impossible d’appeler l’API runs. Je m’arrête proprement."
  exit 0
fi

# --- Extraire la liste basique des runs + conclusions ---
SUMMARY="$OUTDIR/summary.txt"
: > "$SUMMARY"
echo "Repo      : $OWNER/$REPO" >> "$SUMMARY"
echo "Branche   : $BRANCH" >> "$SUMMARY"
echo "PR        : #$PR_NUMBER" >> "$SUMMARY"
echo "Dossier   : $OUTDIR" >> "$SUMMARY"
echo >> "$SUMMARY"

if [[ $have_jq -eq 1 ]]; then
  i "Analyse des runs (jq présent)…"
  jq -r '.workflow_runs[] | [.id, .name, .event, .status, .conclusion, .created_at] | @tsv' "$RUNS_JSON" \
    > "$OUTDIR/runs.tsv" || true

  echo "──────── Workflow runs récents ────────" >> "$SUMMARY"
  awk -F'\t' '{printf "• id=%s | %-20s | event=%-14s | status=%-10s | concl=%-10s | %s\n",$1,$2,$3,$4,$5,$6}' \
    "$OUTDIR/runs.tsv" >> "$SUMMARY" || true
  echo >> "$SUMMARY"

  # Sélectionner les runs non “success”
  cut -f1,5 "$OUTDIR/runs.tsv" | awk -F'\t' '$2!="success"{print $1}' > "$OUTDIR/run_ids_failed.txt" || true
else
  w "jq absent — résumé simplifié."
  echo "Installe jq pour un rapport détaillé: sudo apt-get install -y jq" >> "$SUMMARY"
  # fallback ultra simple: tenter grep dans JSON
  grep -o '"id":[0-9]\+' "$RUNS_JSON" | head -n 10 | sed 's/"id"://' > "$OUTDIR/run_ids_failed.txt" || true
fi

# --- Pour chaque run en échec: lister jobs + récupérer logs ZIP ---
if [[ -s "$OUTDIR/run_ids_failed.txt" ]]; then
  i "Extraction des jobs en échec et téléchargement des logs (si token dispo)…"
  while IFS= read -r RUN_ID; do
    [[ -z "${RUN_ID// }" ]] && continue

    JOBS_JSON="$OUTDIR/jobs_$RUN_ID.json"
    if api "/repos/$OWNER/$REPO/actions/runs/$RUN_ID/jobs?per_page=100" > "$JOBS_JSON" 2>/dev/null; then
      if [[ $have_jq -eq 1 ]]; then
        FAIL_JOBS_TSV="$OUTDIR/jobs_failed_$RUN_ID.tsv"
        jq -r '.jobs[] | select(.conclusion!="success") | [.id, .name, .status, .conclusion, .started_at] | @tsv' \
          "$JOBS_JSON" > "$FAIL_JOBS_TSV" || true

        if [[ -s "$FAIL_JOBS_TSV" ]]; then
          {
            echo "Run $RUN_ID — jobs en échec :"
            awk -F'\t' '{printf "  - job_id=%s | %-30s | status=%-10s | concl=%-10s | %s\n",$1,$2,$3,$4,$5}' "$FAIL_JOBS_TSV"
            echo
          } >> "$SUMMARY"
        fi
      fi
    else
      w "Impossible de récupérer les jobs pour run=$RUN_ID"
    fi

    if [[ -n "$TOKEN" ]]; then
      ZIP_PATH="$OUTDIR/run_${RUN_ID}.zip"
      if curl -fsSL -H "Authorization: Bearer $TOKEN" -H "Accept: application/vnd.github+json" \
           -o "$ZIP_PATH" "https://api.github.com/repos/$OWNER/$REPO/actions/runs/$RUN_ID/logs" ; then
        i "Logs téléchargés: $ZIP_PATH"
        echo "  • Logs ZIP: $ZIP_PATH" >> "$SUMMARY"
        # Décompression optionnelle
        if command -v unzip >/dev/null 2>&1; then
          DEST="$OUTDIR/run_${RUN_ID}_logs"
          mkdir -p "$DEST" && unzip -q -o "$ZIP_PATH" -d "$DEST" || true
          echo "  • Décompressé: $DEST" >> "$SUMMARY"
        fi
      else
        w "Téléchargement logs échoué pour run=$RUN_ID (manque droits 'actions:read' ?)"
      fi
    else
      w "Pas de token -> pas de téléchargement de logs ZIP pour run=$RUN_ID."
    fi

  done < "$OUTDIR/run_ids_failed.txt"
else
  i "Aucun run en échec détecté (ou parsing limité sans jq)."
  echo "Aucun run en échec détecté (ou parsing limité sans jq)." >> "$SUMMARY"
fi

# --- Pistes génériques (utile si pas de logs détaillés) ---
{
  echo
  echo "──────── Pistes de correction (guides rapides) ────────"
  echo "• semantic-pr            : (déjà renommé) re-dispatch si encore listé."
  echo "• secret-scan/gitleaks   : restreindre l'allowlist aux dossiers d'archives uniquement."
  echo "• manifest-guard/sdist   : aligner MANIFEST.in + pyproject (inclure/exclure identiques)."
  echo "• readme-guard           : régénérer sections/badges auto ou ignorer explicitement."
  echo "• guard-generated        : (re)générer fichiers annoncés comme générés et commit."
  echo "• integrity              : régénérer checksums/locks puis commit."
  echo "• pip-audit              : constraints.txt minimal (pinnings), résoudre CVEs bruyants."
  echo "• pdf/build-pdf          : installer LaTeX dans le job ou stub temporaire."
} >> "$SUMMARY"

i "Résumé CI écrit dans: $SUMMARY"

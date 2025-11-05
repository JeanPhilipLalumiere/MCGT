#!/usr/bin/env bash
# tools/collect_ci_logs.sh
# Usage:
#   bash tools/collect_ci_logs.sh 19 rewrite/main-20251026T134200
#   # PR par défaut: 19 ; branche par défaut: rewrite/main-20251026T134200

set -Eeuo pipefail
trap 'printf "\n\033[1;34m[INFO]\033[0m Script terminé (mode safe).\n"' EXIT

PR_NUMBER="${1:-19}"
BRANCH="${2:-rewrite/main-20251026T134200}"
OUTDIR="_tmp/ci_failures"
mkdir -p "$OUTDIR" || true

info(){ printf "\033[1;34m[INFO]\033[0m %s\n" "$*"; }
warn(){ printf "\033[1;33m[WARN]\033[0m %s\n" "$*"; }

if ! command -v gh >/dev/null 2>&1; then
  warn "gh introuvable. J’essaie quand même un résumé basique via gh… (les commandes échoueront silencieusement)."
fi

info "Cible: PR #$PR_NUMBER • Branche: $BRANCH"
SUMMARY="$OUTDIR/summary.txt"
: > "$SUMMARY"

# 1) Lister les checks PR
info "Récupération des checks PR…"
if gh pr checks "$PR_NUMBER" > "$OUTDIR/pr_checks_raw.txt" 2>/dev/null; then
  awk 'NR>2 {print}' "$OUTDIR/pr_checks_raw.txt" > "$OUTDIR/pr_checks.txt" || true
else
  warn "Impossible de lister les checks via gh. Je continue."
fi

# 2) Identifier les jobs en échec
FAILED_NAMES_FILE="$OUTDIR/failed_jobs.txt"
: > "$FAILED_NAMES_FILE"

if [[ -f "$OUTDIR/pr_checks.txt" ]]; then
  # Cherche lignes commençant par X (échec)
  grep -E '^[[:space:]]*X[[:space:]]' "$OUTDIR/pr_checks.txt" | sed 's/^[[:space:]]*X[[:space:]]*//' | cut -f1 -d'(' | sed 's/[[:space:]]*$//' > "$FAILED_NAMES_FILE" || true
fi

if [[ ! -s "$FAILED_NAMES_FILE" ]]; then
  info "Aucun job en échec détecté dans la sortie actuelle. Peut-être que la CI n’a pas fini ?"
  echo "Aucun job en échec détecté." >> "$SUMMARY"
fi

# 3) Pour chaque job: tenter d’extraire les logs
if command -v gh >/dev/null 2>&1; then
  RUNS_JSON="$OUTDIR/runs.json"
  if gh run list --branch "$BRANCH" --json databaseId,name,status,conclusion,headBranch,headSha -L 50 > "$RUNS_JSON" 2>/dev/null; then
    info "Extraction des logs pour les jobs en échec…"
    while IFS= read -r NAME; do
      [[ -z "${NAME// }" ]] && continue
      # Cherche le run correspondant par nom (approx)
      RUN_ID=$(jq -r --arg n "$NAME" '.[] | select(.name | contains($n)) | .databaseId' "$RUNS_JSON" | head -n1)
      if [[ -n "${RUN_ID// }" && "$RUN_ID" != "null" ]]; then
        FILE_BASENAME="$(echo "$NAME" | tr ' /:' '___' | sed 's/[^A-Za-z0-9_.-]/_/g')"
        LOG_PATH="$OUTDIR/${FILE_BASENAME}.log"
        if gh run view "$RUN_ID" --log > "$LOG_PATH" 2>/dev/null; then
          info "→ $NAME  (run:$RUN_ID)  logs: $LOG_PATH"
        else
          warn "Logs indisponibles pour $NAME (run:$RUN_ID)."
        fi
      else
        warn "Run introuvable pour le job: $NAME"
      fi
    done < "$FAILED_NAMES_FILE"
  else
    warn "Impossible de lister les runs. Je saute l’étape d’extraction des logs."
  fi
else
  warn "gh non disponible — aucune extraction de logs détaillés."
fi

# 4) Résumé des familles probables et next steps
{
  echo "──────── Résumé & pistes de correction ────────"
  echo "Dossier: $OUTDIR"
  echo
  if [[ -s "$FAILED_NAMES_FILE" ]]; then
    echo "Jobs en échec détectés:"
    nl -ba "$FAILED_NAMES_FILE"
    echo
  fi
  echo "Pistes par famille:"
  echo " • semantic-pr → (déjà corrigé via renommage) : re-dispatch si encore listé."
  echo " • gitleaks/secret-scan → limiter allowlist aux *archives* (déjà amorcé), vérifier qu’aucun secret réel n’est présent."
  echo " • manifest-guard / guard-ignore-and-sdist → aligner MANIFEST.in/pyproject sdist + cohérence .gitignore vs sdist."
  echo " • readme-guard → badges/sections générées : régénérer ou ignorer explicitement les artefacts générés."
  echo " • guard-generated → vérifier que les fichiers annoncés comme générés sont à jour (régénérer, committer)."
  echo " • integrity → contrôler checksums/lockfiles (regénérer lock/checksums et commit)."
  echo " • pip-audit → utiliser un constraints/pins minimal, ou un allowlist temporaire si faux positifs (puis corriger)."
  echo " • pdf/build-pdf → installer la toolchain LaTeX dans le job, ou stubber l’étape si hors scope PR."
  echo
  echo "Ensuite:"
  echo "  1) Corriger un groupe d’échecs → commit."
  echo "  2) Relancer CI: bash tools/ci_dispatch_now.sh $BRANCH"
  echo "  3) Suivre: gh pr checks $PR_NUMBER"
} >> "$SUMMARY"

info "Résumé écrit dans: $SUMMARY"
info "Si tu m’envoies les 2–3 logs les plus bruités du dossier $OUTDIR, je fournis les patches ciblés."

#!/usr/bin/env bash
# ------------------------------------------------------------------------------
# run_safe_attic.sh — Déplacement RÉVERSIBLE des fichiers SAFE_DELETE vers attic/
# Garde-fou : dry-run par défaut, confirmation requise pour --apply, logs + pause.
# ------------------------------------------------------------------------------

set -Eeuo pipefail

### ---------- Garde-fou & journalisation ----------

TS="$(date -u +%Y%m%dT%H%M%SZ)"
LOGDIR="_logs"
mkdir -p "$LOGDIR"
LOGFILE="$LOGDIR/cleanup_safe_attic_${TS}.log"

# Duplique la sortie dans un log complet
exec > >(tee -a "$LOGFILE") 2>&1

STATUS="OK"

pause_exit () {
  echo
  echo "────────────────────────────────────────────────────────────────────────"
  echo " Journal: $LOGFILE"
  echo " Script:  $(realpath "$0")"
  echo "────────────────────────────────────────────────────────────────────────"
  # Empêche la fermeture de la fenêtre même en cas d'erreur
  read -rp "Fin d'exécution. Appuie sur ENTER pour fermer cette fenêtre..." _
}

on_error () {
  STATUS="ERROR"
  echo
  echo "[ERROR] Une erreur est survenue. Consulte le log: $LOGFILE"
}

on_exit () {
  local code=$?
  if [[ "$STATUS" != "OK" || $code -ne 0 ]]; then
    echo "[EXIT] Statut: ERROR (code=$code)"
  else
    echo "[EXIT] Statut: OK"
  fi
  pause_exit
}

trap on_error ERR
trap on_exit EXIT
trap 'echo "[INTERRUPT] Interruption utilisateur (Ctrl-C)"; exit 130' INT

### ---------- Options & aide ----------

APPLY=0
CREATE_PR=1      # on prépare la PR (comportement précédent), change à 0 pour désactiver
BRANCH_PREFIX="cleanup/round2-safe-to-attic"
ATTIC_ROOT="attic"
SAFE_GLOB="_tmp/cleanup_probe_*/*"
SAFE_PATTERN="safe_delete.list"

usage () {
  cat <<EOF
Usage:
  DRY-RUN (par défaut)   : bash $0
  APPLIQUER (déplacement): CONFIRM=YES bash $0 --apply

Options:
  --apply         Exécute réellement les déplacements (sinon DRY-RUN)
  --no-pr         N'ouvre PAS de branche/PR (prévisualisation pure)
  --attic DIR     Racine attic/ (défaut: $ATTIC_ROOT)
  --prefix NAME   Préfixe de branche (défaut: $BRANCH_PREFIX)

Notes:
  - Dry-run liste exactement ce qui serait fait, sans rien modifier.
  - En mode --apply, CONFIRM=YES est OBLIGATOIRE (sinon abort).
  - Tout est LOGGÉ dans: $LOGFILE
EOF
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --apply) APPLY=1; shift ;;
    --no-pr) CREATE_PR=0; shift ;;
    --attic) ATTIC_ROOT="${2:?}"; shift 2 ;;
    --prefix) BRANCH_PREFIX="${2:?}"; shift 2 ;;
    -h|--help) usage; exit 0 ;;
    *) echo "[WARN] Option inconnue: $1"; usage; exit 2 ;;
  esac
done

if [[ $APPLY -eq 1 && "${CONFIRM:-}" != "YES" ]]; then
  echo "[ABORT] --apply nécessite CONFIRM=YES (garde-fou)."
  exit 3
fi

### ---------- Préconditions ----------

if ! command -v git >/dev/null 2>&1; then
  echo "[ERR] git introuvable."
  exit 4
fi

ROOT="$(git rev-parse --show-toplevel 2>/dev/null || true)"
if [[ -z "$ROOT" ]]; then
  echo "[ERR] Ce répertoire n'est pas un repo Git."
  exit 5
fi
cd "$ROOT"

# Branche courante (uniquement informatif)
CURR_BRANCH="$(git rev-parse --abbrev-ref HEAD || echo '?')"
echo "[INFO] Repo: $ROOT | Branche: $CURR_BRANCH"

# Cherche la dernière liste SAFE_DELETE
SAFE_LIST="$(ls -1 $SAFE_GLOB 2>/dev/null | rg "$SAFE_PATTERN" | tail -n1 || true)"
if [[ -z "$SAFE_LIST" || ! -f "$SAFE_LIST" ]]; then
  echo "[ERR] Liste SAFE_DELETE introuvable (pattern: $SAFE_GLOB … $SAFE_PATTERN)."
  echo "      Assure-toi d'avoir généré la liste (ex. probe round2)."
  exit 6
fi
COUNT="$(wc -l <"$SAFE_LIST" | tr -d ' ')"
echo "[INFO] Liste SAFE_DELETE: $SAFE_LIST  (items: $COUNT)"

if [[ $COUNT -eq 0 ]]; then
  echo "[OK] Rien à déplacer. Fin."
  exit 0
fi

### ---------- Plan d'exécution ----------

TSU="$(date -u +%Y%m%dT%H%M%SZ)"
ATTIC="$ATTIC_ROOT/cleanup_${TSU}"
echo "[PLAN] Déplacement RÉVERSIBLE vers: $ATTIC"
mkdir -p "$ATTIC"

MOVELIST="_logs/move_plan_${TSU}.tsv"
echo -e "SRC\tDEST\tTRACKED" > "$MOVELIST"

# Pré-scan & affichage DRY-RUN
echo "[SCAN] Préparation du plan…"
while IFS= read -r f; do
  [[ -z "$f" ]] && continue
  if [[ ! -e "$f" ]]; then
    echo "[SKIP] Manquant: $f"
    continue
  fi
  dest="$ATTIC/$f"
  tracked="no"
  if git ls-files --error-unmatch -- "$f" >/dev/null 2>&1; then
    tracked="yes"
  fi
  echo -e "$f\t$dest\t$tracked" >> "$MOVELIST"
  echo "[PLAN] $f  →  $dest  (tracked=$tracked)"
done < "$SAFE_LIST"

echo
echo "[INFO] Plan enregistré: $MOVELIST"
if [[ $APPLY -eq 0 ]]; then
  echo "[DRY-RUN] AUCUNE modification effectuée. Relance avec: CONFIRM=YES bash $0 --apply"
  exit 0
fi

### ---------- Application (déplacements réversibles) ----------

echo
echo "[APPLY] Déplacements vers $ATTIC (confirmation reçue: CONFIRM=YES)…"

# S’assure de rester propre côté Git
git add -A || true

# Effectue les déplacements
while IFS=$'\t' read -r SRC DEST TRACKED; do
  [[ "$SRC" == "SRC" ]] && continue
  [[ -z "$SRC" || -z "$DEST" ]] && continue
  if [[ ! -e "$SRC" ]]; then
    echo "[SKIP] Disparu entre-temps: $SRC"
    continue
  fi
  mkdir -p "$(dirname "$DEST")"
  if [[ "$TRACKED" == "yes" ]]; then
    git mv -f -- "$SRC" "$DEST"
  else
    mv -f -- "$SRC" "$DEST"
    # on archive aussi ces artefacts dans Git pour revue/PR
    git add -f -- "$DEST"
  fi
  echo "[MOVE] $SRC → $DEST"
done < <(tail -n +2 "$MOVELIST")

# Commit unique
git add -A || true
git commit -m "round2(cleanup): move ${COUNT} SAFE_DELETE → ${ATTIC} (reversible) + logs (${TSU})" || true

if [[ $CREATE_PR -eq 1 ]]; then
  # Branche dédiée + PR
  NEW_BR="${BRANCH_PREFIX}-${TSU}"
  echo "[GIT] Création branche: $NEW_BR"
  git switch -c "$NEW_BR"

  echo "[GIT] Push…"
  git push -u origin "$NEW_BR"

  if command -v gh >/dev/null 2>&1; then
    echo "[PR ] Ouverture PR…"
    gh pr create \
      --title "round2(cleanup): SAFE_DELETE → attic (${TSU})" \
      --body  "Déplacement réversible de ${COUNT} fichiers SAFE_DELETE vers \`${ATTIC}\`.\n- Logs: \`${LOGFILE}\`\n- Plan: \`${MOVELIST}\`\nCI attendue verte (pypi-build/secret-scan)."
    # Déclenche les 2 workflows requis (best effort)
    gh workflow run .github/workflows/pypi-build.yml  --ref "$NEW_BR" || true
    gh workflow run .github/workflows/secret-scan.yml --ref "$NEW_BR" || true
  else
    echo "[INFO] gh CLI non trouvé : PR non créée automatiquement."
  fi
else
  echo "[INFO] --no-pr : aucun push, aucune PR créée."
fi

echo "[DONE] Opération terminée."

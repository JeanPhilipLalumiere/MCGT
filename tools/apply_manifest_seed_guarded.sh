#!/usr/bin/env bash
# apply_manifest_seed_guarded.sh
# - Copie zz-manifests/manifest_master.json depuis .ci-out/manifest_master.candidate.json si différent
# - Commit/push uniquement si changement
# - Déclenche manifest-guard sur la branche BR
# - Récupère artefacts/logs
# - NE FERME PAS la fenêtre (pause en fin / en cas d'erreur)

set -Eeu -o pipefail

# ---------- Garde-fou (pause robuste) ----------
PAUSED=0
pause() {
  local msg="${1:-[FIN] Appuie sur Entrée pour quitter...}"
  if [[ "$PAUSED" -eq 1 ]]; then return; fi
  PAUSED=1
  if [[ -t 0 ]]; then
    read -rp "$msg" _ || true
  elif [[ -e /dev/tty ]]; then
    read -rp "$msg" _ < /dev/tty || true
  else
    echo "$msg"
    sleep 5
  fi
}

on_err() {
  local code=$?
  echo
  echo "[ERREUR] Le script s'est arrêté avec le code ${code}."
  echo "[ASTUCE] Vérifie les messages ci-dessus; rien n'a été supprimé."
  pause
  exit "$code"
}

on_exit() {
  local code=$?
  if [[ "$code" -eq 0 ]]; then
    echo
    echo "[OK] Terminé sans erreur."
  fi
  pause
}

trap on_err ERR
trap on_exit EXIT

# ---------- Paramètres ----------
BR="${BR:-release/zz-tools-0.3.1}"
WF="${WF:-.github/workflows/manifest-guard.yml}"
CAND="${CAND:-.ci-out/manifest_master.candidate.json}"
TARGET="${TARGET:-zz-manifests/manifest_master.json}"

echo "[INFO] BR=${BR}"
echo "[INFO] WF=${WF}"
echo "[INFO] CAND=${CAND}"
echo "[INFO] TARGET=${TARGET}"
echo

# ---------- Pré-checks ----------
command -v git >/dev/null || { echo "[FATAL] git introuvable"; exit 127; }
command -v gh  >/dev/null || { echo "[FATAL] gh (GitHub CLI) introuvable"; exit 127; }

[[ -f "$CAND" ]] || { echo "[FATAL] Candidat introuvable: $CAND"; exit 2; }
mkdir -p "$(dirname "$TARGET")"

# ---------- Appliquer seulement si différent ----------
NEEDS_COPY=1
if [[ -f "$TARGET" ]] && cmp -s "$CAND" "$TARGET"; then
  NEEDS_COPY=0
  echo "[NOTE] Le manifest cible est déjà identique au candidat — aucune copie nécessaire."
fi

if [[ "$NEEDS_COPY" -eq 1 ]]; then
  if [[ -f "$TARGET" ]]; then
    BK="${TARGET}.bak_$(date -u +%Y%m%dT%H%M%SZ)"
    cp -a "$TARGET" "$BK"
    echo "[SAFE] Backup créé: $BK"
  fi
  cp -f "$CAND" "$TARGET"
  echo "[OK] Copié: $CAND -> $TARGET"
fi

# ---------- Commit + push S'IL Y A changement ----------
if ! git diff --quiet -- "$TARGET"; then
  set +e
  git add "$TARGET"
  git commit -m "manifests: seed minimal files list (exclude backups/autofix), schema clean"
  commit_rc=$?
  set -e
  if [[ "$commit_rc" -eq 0 ]]; then
    echo "[OK] Commit effectué."
    git push
    echo "[OK] Push effectué."
  else
    echo "[WARN] git commit a renvoyé rc=${commit_rc}. Poursuite quand même (déclenchement CI)."
  fi
else
  echo "[NOTE] Aucun delta à committer sur $TARGET."
fi

# ---------- Déclenche workflow guard (même sans commit) ----------
echo "[INFO] Déclenchement du workflow guard sur ${BR}…"
set +e
gh workflow run "$WF" --ref "$BR"
dispatch_rc=$?
set -e
if [[ "$dispatch_rc" -ne 0 ]]; then
  echo "[WARN] Échec du déclenchement via gh workflow run (rc=${dispatch_rc})."
  echo "      Le workflow est peut-être déjà en cours ou le déclencheur manque."
fi

# ---------- Attente + récupération artefacts/logs ----------
sleep 2
NWO="$(gh repo view --json nameWithOwner -q .nameWithOwner)"
RID="$(gh run list --workflow=$(basename "$WF") --branch "$BR" --limit 1 --json databaseId -q '.[0].databaseId' 2>/dev/null || true)"

if [[ -n "$RID" ]]; then
  echo "[INFO] RID=$RID — attente de la fin du run…"
  gh run watch "$RID" --exit-status || true

  OUT_DIR=".ci-out/manifest_guard_${RID}"
  rm -rf "$OUT_DIR"; mkdir -p "$OUT_DIR"

  # Si l’outil helper existe, on l’utilise; sinon fallback natif
  if [[ -x tools/fetch_guard_artifact.sh ]]; then
    echo "[INFO] Utilisation de tools/fetch_guard_artifact.sh --rid $RID"
    tools/fetch_guard_artifact.sh --rid "$RID" --out "$OUT_DIR" || true
  else
    echo "[INFO] Téléchargement artefact…"
    gh run download "$RID" -n "manifest-guard-$RID" -D "$OUT_DIR" || echo "[WARN] Artefact non trouvé."

    echo "[INFO] Journal du job…"
    JID="$(gh api repos/$NWO/actions/runs/"$RID"/jobs -q '.jobs[0].id' 2>/dev/null || true)"
    if [[ -n "$JID" ]]; then
      gh run view "$RID" --job "$JID" --log > "$OUT_DIR/job.log" || true
      sed -n 's/.*::error::\(.*\)$/\1/p' "$OUT_DIR/job.log" > "$OUT_DIR/errors.txt" || true
      tail -n 40 "$OUT_DIR/job.log" > "$OUT_DIR/tail40.txt" || true
    fi
  fi

  # Affichage défensif du diag
  if [[ -f "$OUT_DIR/diag_report.json" ]]; then
    echo "[INFO] diag_report.json ↓"
    (jq . "$OUT_DIR/diag_report.json" 2>/dev/null || cat "$OUT_DIR/diag_report.json") | sed 's/^/[diag]/'
  else
    echo "[WARN] diag_report.json absent dans $OUT_DIR"
  fi
else
  echo "[WARN] Aucun RUN ID récupéré pour $(basename "$WF") sur ${BR}."
fi

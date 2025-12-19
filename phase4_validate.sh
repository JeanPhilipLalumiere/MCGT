#!/usr/bin/env bash
# ===== Phase 4 : Validation post-publication (ne ferme pas la fenêtre) =====
set -Eeuo pipefail

VER="${VER:-0.2.22}"                      # Override: VER=0.2.22 ./phase4_validate.sh
WORKDIR="/tmp"
VENV_DIR="${WORKDIR}/venv_phase4_${VER//./_}"
VENV_PY="${VENV_DIR}/bin/python"
LOG_FILE="$(pwd)/phase4_$(date +%Y%m%d_%H%M%S)_v${VER}.log"
FAILED=""

is_tty() { [ -t 0 ] && [ -t 1 ]; }
log() { printf "%s\n" "$*" | tee -a "$LOG_FILE"; }

trap 'FAILED=1; log "‼️  Erreur capturée à la ligne ${BASH_LINENO[0]} — commande: ${BASH_COMMAND}"' ERR

hold_window() {
  [[ "${NO_HOLD:-0}" == "1" ]] && return 0
  echo "" | tee -a "$LOG_FILE"
  if is_tty; then read -rp "Phase 4 terminée. Appuyez sur Entrée pour fermer cette fenêtre..." _; fi
}

{
  log "=== Phase 4 (VER=${VER}) démarrée: $(date -Is) ==="
  log "CWD: $(pwd)"
  log "[1/6] Création du venv propre dans ${VENV_DIR}"
  rm -rf "${VENV_DIR}"
  python3 -m venv "${VENV_DIR}"
  . "${VENV_DIR}/bin/activate"
  python -m pip install -U pip >/dev/null

  log "[2/6] Installation PyPI (sans cache) : mcgt-core==${VER}"
  pip install --no-cache-dir "mcgt-core==${VER}"

  log "[3/6] Vérification version + chemin (site-packages attendu)"
  "$VENV_PY" - <<'PY'
import mcgt, sys
print("version:", mcgt.__version__)
print("module file:", mcgt.__file__)
print("sys.path[0]:")
print(sys.path[0])
PY

  log "[4/6] Imports publics (auto-install des deps manquantes)"
  for i in 1 2 3; do
    out="$("$VENV_PY" - <<'PY' 2>&1 || true
try:
    import mcgt
    from mcgt import phase, scalar_perturbations
    print("OK_IMPORT")
except ModuleNotFoundError as e:
    print("MISSING:"+ (e.name or "unknown"))
except Exception as e:
    print("IMPORT_ERR:"+repr(e))
PY
)"
    echo "$out" | tee -a "$LOG_FILE"
    if grep -q 'OK_IMPORT' <<<"$out"; then
      echo "Imports réussis." | tee -a "$LOG_FILE"; break
    fi
    if grep -q '^MISSING:' <<<"$out"; then
      pkg="$(echo "$out" | sed -n 's/^MISSING://p' | tail -n1)"
      echo "MISSING:$pkg -> tentative d'installation..." | tee -a "$LOG_FILE"
      pip install --no-cache-dir "$pkg"
    else
      echo "Import non résolu, abandon." | tee -a "$LOG_FILE"; exit 1
    fi
  done

  log "[5/6] Nettoyage/options (aucune action requise)"
  log "[6/6] Terminé"

  if [[ -z "$FAILED" ]]; then
    log ""
    log "✅ Phase 4 OK : installation & import depuis site-packages en v${VER}"
  else
    log "❌ Phase 4 échouée (voir log)"
  fi
  log ""
  log "=== Fin Phase 4: $(date -Is) ==="
} 2>&1 | tee -a "$LOG_FILE"

hold_window
exit 0

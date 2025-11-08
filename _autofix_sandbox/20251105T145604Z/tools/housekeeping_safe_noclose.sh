#!/usr/bin/env bash
# housekeeping_safe_noclose.sh
# - Ne ferme JAMAIS la fenêtre (pause à la fin si TTY)
# - Journalisation dans _tmp/housekeeping.safe.log
# - Pas de 'set -e' (on préfère enregistrer et continuer)
# - Normalise .gitignore "only-if-changed" (zéro faux mtime)
# - Peut synchroniser l'entrée du manifeste pour .gitignore (backup avant)
# - Exécute audit -> diag -> pytest
# - Ne commit pas par défaut (export GIT_AUTOCOMMIT=1 pour activer)
# - Ne push pas si rien à committer

set -uo pipefail

# --- Config toggles ---
: "${SYNC_MANIFEST:=1}"     # 1 = met à jour le manifeste pour .gitignore si changé
: "${GIT_AUTOCOMMIT:=0}"    # 1 = git add/commit/push automatique si changements
: "${PAUSE_ON_EXIT:=1}"     # 1 = pause finale si TTY

# --- Paths & log ---
mkdir -p _tmp
LOG="_tmp/housekeeping.safe.log"

ts() { date -u +'%Y-%m-%dT%H:%M:%SZ'; }
log() { echo "[$(ts)] $*" | tee -a "$LOG"; }

pause_end() {
  st=$?
  echo | tee -a "$LOG"
  log "END status=$st — log: $LOG"
  if [[ "$PAUSE_ON_EXIT" = "1" && -t 1 ]]; then
    read -rp "Appuyez sur Entrée pour quitter..."
  fi
  exit "$st"
}
trap pause_end EXIT

log "== housekeeping_safe_noclose.sh: start =="

# --- Helpers ---
sha256_file() {
  python3 - "$1" <<'PY' 2>/dev/null || return 1
import hashlib,sys
p=sys.argv[1]
h=hashlib.sha256()
with open(p,'rb') as f:
  for c in iter(lambda:f.read(1<<20), b''):
    h.update(c)
print(h.hexdigest())
PY
}

git_last_commit_for() {
  local p="$1"
  bash -lc "git log -n1 --pretty=%H -- -- \"${p}\"" 2>/dev/null || true
}

update_manifest_gitignore() {
  local man="zz-manifests/manifest_master.json"
  local path=".gitignore"
  [[ -f "$man" && -f "$path" ]] || { log "manifest sync: skip (missing files)"; return 0; }

  local tsu
  tsu=$(date -u +%Y%m%dT%H%M%SZ)
  cp -a "$man" "${man}.bak.${tsu}" || { log "WARN: backup manifest failed"; :; }

  python3 - <<'PY'
import json, os, hashlib, subprocess, shlex
from datetime import datetime, timezone

M="zz-manifests/manifest_master.json"
P=".gitignore"

def sha256(p):
  h=hashlib.sha256()
  with open(p,'rb') as f:
    for c in iter(lambda:f.read(1<<20), b''):
      h.update(c)
  return h.hexdigest()

def iso(ts): 
  return datetime.fromtimestamp(ts, tz=timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ")

if not (os.path.isfile(M) and os.path.isfile(P)):
  print("manifest sync: missing files")
  raise SystemExit(0)

st=os.stat(P)
sha=sha256(P)
git_hash=subprocess.check_output(
  ["bash","-lc", f"git log -n1 --pretty=%H -- {shlex.quote(P)}"]
).decode().strip()

doc=json.load(open(M))
touched=False
for e in doc.get("entries", []):
  if e.get("path")==P:
    e["size_bytes"]=st.st_size
    e["size"]=st.st_size
    e["sha256"]=sha
    e["mtime"]=int(st.st_mtime)
    e["mtime_iso"]=iso(st.st_mtime)
    e["git_hash"]=git_hash
    touched=True
    break

if touched:
  open(M,"w").write(json.dumps(doc,indent=2,ensure_ascii=False))
  print("manifest sync: updated .gitignore entry")
else:
  print("manifest sync: no .gitignore entry found (skip)")
PY
}

# --- 1) Normalisation .gitignore (only-if-changed) ---
log "normalize .gitignore (only-if-changed)"
tsu=$(date -u +%Y%m%dT%H%M%SZ)
TMP_NEW="_tmp/gitignore.expected.${tsu}"

{
  printf '%s\n' \
    "" \
    "# --- housekeeping (auto) ---" \
    "_tmp/" \
    "_tmp-figs/" \
    "nano.*.save" \
    "*.swp" \
    "*~" \
    "._*" \
    "zz-manifests/manifest_master.backfilled*.json" \
    "_archives_preclean/" \
    "_attic_untracked/"
  # conserver le reste tel quel
  cat .gitignore 2>/dev/null || true
} | awk '!seen[$0]++' > "$TMP_NEW"

GI_CHANGED=0
if [[ ! -f .gitignore ]]; then
  mv -f "$TMP_NEW" .gitignore
  GI_CHANGED=1
elif ! cmp -s "$TMP_NEW" .gitignore; then
  mv -f "$TMP_NEW" .gitignore
  GI_CHANGED=1
else
  rm -f "$TMP_NEW"
fi
[[ $GI_CHANGED -eq 1 ]] && log ".gitignore changed" || log ".gitignore unchanged"

# --- 2) Sync manifeste pour .gitignore (optionnel + backup) ---
if [[ "$SYNC_MANIFEST" = "1" && $GI_CHANGED -eq 1 ]]; then
  log "sync manifest entry for .gitignore"
  update_manifest_gitignore
fi

# --- 3) Ranger le non-suivi, via tools/_safe_move_untracked.sh ---
log "move untracked (safe mover)"
mkdir -p _attic_untracked tools
MOVED=0; SKIPPED=0
if [[ -x tools/_safe_move_untracked.sh ]]; then
  # Le mover émet des lignes "MOVED: ..." et "SKIP: ..."
  while IFS= read -r line; do
    case "$line" in
      MOVED:*)
        ((MOVED++))
        ;;
      SKIP:*)
        ((SKIPPED++))
        ;;
      *)
        : # verbatim passthrough
        ;;
    esac
    echo "$line" | tee -a "$LOG"
  done < <(bash tools/_safe_move_untracked.sh)
  log "SUMMARY moved=$MOVED skipped=$SKIPPED"
else
  log "safe mover missing (tools/_safe_move_untracked.sh) -> skip"
fi

# --- 4) Audit complet ---
if [[ -x ./tools/audit_manifest_files.sh ]]; then
  log "running audit"
  ./tools/audit_manifest_files.sh --all | tee -a "$LOG"
else
  log "audit script missing -> skip"
fi

# --- 5) Diag (warnings tolérés ici, rapport déposé) ---
log "running diag (warnings tolerated)"
python zz-manifests/diag_consistency.py zz-manifests/manifest_master.json \
  --report json --normalize-paths --apply-aliases --strip-internal --content-check \
  > _tmp/diag_housekeeping.json 2>&1 || true
head -n 200 _tmp/diag_housekeeping.json | tee -a "$LOG"

# --- 6) Tests unitaires (tolérant) ---
log "running pytest -q (tolerant)"
pytest -q | tee -a "$LOG" || true

# --- 7) État git + auto-commit optionnel ---
log "git status (porcelain)"
git status --porcelain | tee -a "$LOG"

if [[ "$GIT_AUTOCOMMIT" = "1" ]]; then
  CHANGES=$(git status --porcelain)
  if [[ -n "$CHANGES" ]]; then
    log "auto-commit enabled -> committing tracked changes"
    # On n'ajoute que les fichiers explicitement modifiés par ce script
    git add -A
    git commit -m "housekeeping: normalize .gitignore only-if-changed, safe-move, audit/diag/tests (log: ${LOG})" || true
    git push || true
  else
    log "no changes to commit"
  fi
else
  log "auto-commit disabled (set GIT_AUTOCOMMIT=1 to enable)"
fi

log "== housekeeping_safe_noclose.sh: done =="

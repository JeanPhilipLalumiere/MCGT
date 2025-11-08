#!/usr/bin/env bash
set -euo pipefail

# -------------------- GARDEFOU : NE PAS FERMER LA FENÊTRE --------------------
KEEP_OPEN="${KEEP_OPEN:-1}"
stay_open() {
  local rc=$?
  echo
  echo "[refresh-manifest-full] Script terminé avec exit code: $rc"
  if [[ "${KEEP_OPEN}" == "1" && -t 1 && -z "${CI:-}" ]]; then
    echo "[refresh-manifest-full] Appuie sur Entrée pour quitter…"
    # shellcheck disable=SC2034
    read -r _
  fi
}
trap 'stay_open' EXIT
# -----------------------------------------------------------------------------

cd "$(git rev-parse --show-toplevel)"

MAN="zz-manifests/manifest_master.json"
[[ -f "$MAN" ]] || { echo "ERREUR: introuvable: $MAN" >&2; exit 1; }

DROP_MISSING="${DROP_MISSING:-0}"   # 1 => supprime les entrées dont le fichier n’existe plus

echo "==> (1) Sauvegarde du manifest (timestampée)"
cp -f "$MAN" "${MAN}.bak.$(date -u +%Y%m%dT%H%M%SZ)"

echo "==> (2) Rafraîchit git_hash + size_bytes + sha256 + mtime_iso (UTC) depuis le repo"
python - <<'PY'
import json, subprocess, sys, hashlib, os, datetime
from pathlib import Path

root = Path(".").resolve()
man  = root/"zz-manifests"/"manifest_master.json"
data = json.loads(man.read_text(encoding="utf-8"))
DROP_MISSING = os.environ.get("DROP_MISSING","0") == "1"

# --- helpers -----------------------------------------------------------------
def git_blob_hash(path: str):
    out = subprocess.run(["git","rev-parse", f":{path}"], capture_output=True, text=True)
    if out.returncode != 0:
        return None
    return out.stdout.strip()

def file_stats(p: Path):
    st = p.stat()
    size = int(st.st_size)
    # mtime in UTC, ISO8601 Z
    mt  = datetime.datetime.fromtimestamp(st.st_mtime, tz=datetime.timezone.utc)\
                           .replace(microsecond=0).isoformat().replace("+00:00","Z")
    h = hashlib.sha256()
    with p.open("rb") as f:
        for chunk in iter(lambda: f.read(1024*1024), b""):
            h.update(chunk)
    return size, h.hexdigest(), mt

def to_entries(container):
    # list
    if isinstance(container, list):
        return "list", container
    # dict with "entries"
    if isinstance(container, dict) and isinstance(container.get("entries"), list):
        return "entries", container["entries"]
    # map: {path: {...}}
    if isinstance(container, dict) and all(isinstance(k,str) and isinstance(v,dict) for k,v in container.items()):
        # normalize to list of {path: k, **v}
        return "map", [{"path": k, **v} for k,v in container.items()]
    print("ERREUR: format de manifest inattendu", file=sys.stderr); sys.exit(1)

fmt, entries = to_entries(data)

changed_git = changed_size = changed_sha = changed_mtime = 0
missing, errors = [], []

new_entries = []
for e in entries:
    path = e.get("path") or e.get("file") or e.get("location")
    if not path or not isinstance(path, str):
        # on conserve tel quel
        new_entries.append(e);
        continue

    # git hash (blob)
    gh = git_blob_hash(path)
    if gh and e.get("git_hash") != gh:
        e["git_hash"] = gh
        changed_git += 1

    fp = root / path
    if not fp.exists():
        missing.append(path)
        if DROP_MISSING:
            # on n’ajoute pas cette entrée
            continue
        else:
            # on garde l’entrée telle quelle
            new_entries.append(e)
            continue

    # contenu actuel
    size, sha, mt = file_stats(fp)
    if e.get("size_bytes") != size:
        e["size_bytes"] = size; changed_size += 1
    if e.get("sha256") != sha:
        e["sha256"] = sha; changed_sha += 1
    # mtime_iso strict en Z
    if e.get("mtime_iso") != mt:
        e["mtime_iso"] = mt; changed_mtime += 1

    new_entries.append(e)

# reconstruit dans le style d’origine
if fmt == "entries":
    data["entries"] = new_entries
elif fmt == "list":
    data = new_entries
elif fmt == "map":
    remap = {}
    for e in new_entries:
        p = e.get("path") or e.get("file") or e.get("location")
        if not p: continue
        ee = dict(e)
        ee.pop("path", None); ee.pop("file", None); ee.pop("location", None)
        remap[p] = ee
    data = remap

out = json.dumps(data, ensure_ascii=False, indent=2) + "\n"
man.write_text(out, encoding="utf-8")

print(json.dumps({
  "changed": {
    "git_hash": changed_git,
    "size_bytes": changed_size,
    "sha256": changed_sha,
    "mtime_iso": changed_mtime
  },
  "missing_count": len(missing),
  "missing_preview": missing[:20],
  "drop_missing": DROP_MISSING
}, indent=2, ensure_ascii=False))
PY

echo "==> (3) pre-commit ciblé & commit/push si diff"
pre-commit run --files "$MAN" || true
git add "$MAN" || true
if ! git diff --cached --quiet; then
  git commit -m "manifests: full refresh (git_hash, size_bytes, sha256, mtime_iso)"
  git push
else
  echo "Rien à committer"
fi

echo "==> (4) Revalide diag_consistency via le guard"
KEEP_OPEN=0 tools/ci_step6_schemas_guard.sh || {
  echo "❌ schemas-guard a échoué. Aperçu des erreurs:"
  python - <<'PY'
import json, subprocess, sys
from pathlib import Path
root = Path(".").resolve()
diag = root/"zz-manifests"/"diag_consistency.py"
master = root/"zz-manifests"/"manifest_master.json"
out = subprocess.run(
    [sys.executable, str(diag), str(master), "--report","json",
     "--normalize-paths","--apply-aliases","--strip-internal",
     "--content-check","--fail-on","errors"],
    capture_output=True, text=True
)
try:
    payload = json.loads(out.stdout or "{}")
except Exception:
    print(out.stdout); sys.exit(0)
errs = [i for i in payload.get("issues",[]) if i.get("severity")=="ERROR"]
print(f"ERRORS: {len(errs)}")
for i in errs[:80]:
    print(f"- {i.get('code')} :: {i.get('path')}")
PY
  exit 1
}

echo "✅ Manifest rafraîchi (contenu + git) et tests schémas OK (à warnings près)."

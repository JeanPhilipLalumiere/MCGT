#!/usr/bin/env bash
set -euo pipefail

# -------------------- GARDEFOU : NE PAS FERMER LA FENÊTRE --------------------
KEEP_OPEN="${KEEP_OPEN:-1}"
stay_open() {
  local rc=$?
  echo
  echo "[refresh-manifest] Script terminé avec exit code: $rc"
  if [[ "${KEEP_OPEN}" == "1" && -t 1 && -z "${CI:-}" ]]; then
    echo "[refresh-manifest] Appuie sur Entrée pour quitter…"
    # shellcheck disable=SC2034
    read -r _
  fi
}
trap 'stay_open' EXIT
# -----------------------------------------------------------------------------

cd "$(git rev-parse --show-toplevel)"

MAN="zz-manifests/manifest_master.json"
[[ -f "$MAN" ]] || { echo "ERREUR: introuvable: $MAN" >&2; exit 1; }

echo "==> (1) Sauvegarde du manifest (timestampée)"
cp -f "$MAN" "${MAN}.bak.$(date -u +%Y%m%dT%H%M%SZ)"

echo "==> (2) Rafraîchit les git_hash à partir de HEAD"
python - <<'PY'
import json, subprocess, sys
from pathlib import Path

root = Path(".").resolve()
man  = root/"zz-manifests"/"manifest_master.json"
data = json.loads(man.read_text(encoding="utf-8"))

# Détecte la liste d'entrées (formats tolérés)
def get_entries(container):
    if isinstance(container, list):
        return container
    if isinstance(container, dict):
        if isinstance(container.get("entries"), list):
            return container["entries"]
        # format map {path: {...}}
        if all(isinstance(k, str) and isinstance(v, dict) for k,v in container.items()):
            # le normaliser en liste d'objets {path: k, ...v}
            return [{"path": k, **v} for k,v in container.items()]
    print("ERREUR: format de manifest inattendu", file=sys.stderr)
    sys.exit(1)

entries = get_entries(data)
changed = 0
missing = []
errors  = []

def git_blob_hash(path: str) -> str|None:
    try:
        # Equivalent lisible: git ls-files -s -- path | awk '{print $2}'
        out = subprocess.run(
            ["git","rev-parse", f":{path}"],
            capture_output=True, text=True, check=False
        )
        if out.returncode != 0:
            return None
        return out.stdout.strip()
    except Exception as e:
        errors.append((path, str(e)))
        return None

for e in entries:
    path = e.get("path") or e.get("file") or e.get("location")
    if not path or not isinstance(path, str):
        continue
    h = git_blob_hash(path)
    if h is None:
        missing.append(path)
        continue
    old = e.get("git_hash")
    if old != h:
        e["git_hash"] = h
        changed += 1

# Si on avait un format "dict {path:info}", on ne le reconstruit pas : on réécrit tel qu'on l'a lu
# => Donc si data est dict avec 'entries', on y remet entries; si c'était une list, on réécrit la list.
if isinstance(data, dict) and isinstance(data.get("entries"), list):
    data["entries"] = entries
elif isinstance(data, list):
    data = entries
# (si c'était un dict map, on laisse data tel quel: ci-dessus on a travaillé sur une copie list; on recompose)
elif isinstance(data, dict) and all(isinstance(k,str) for k in data.keys()):
    new_map = {}
    for e in entries:
        p = e.get("path") or e.get("file") or e.get("location")
        if not p: continue
        ee = dict(e)
        ee.pop("path", None); ee.pop("file", None); ee.pop("location", None)
        new_map[p] = ee
    data = new_map

out = json.dumps(data, ensure_ascii=False, indent=2) + "\n"
man.write_text(out, encoding="utf-8")

print(json.dumps({
    "changed": changed,
    "missing_count": len(missing),
    "missing_paths_preview": missing[:15],
    "errors_count": len(errors),
    "errors_preview": errors[:5],
}, indent=2, ensure_ascii=False))
PY

echo "==> (3) pre-commit (ciblé) & commit/push si diff"
pre-commit run --files "$MAN" || true
git add "$MAN" || true
if ! git diff --cached --quiet; then
  git commit -m "manifests: refresh git_hash to HEAD (auto)"
  git push
else
  echo "Rien à committer"
fi

echo "==> (4) Revalide diag_consistency via le guard"
KEEP_OPEN=0 tools/ci_step6_schemas_guard.sh || {
  echo "❌ schemas-guard a échoué. Inspection rapide des erreurs seulement…"
  python - <<'PY'
import json, subprocess, sys
from pathlib import Path
from pprint import pprint
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
    print(out.stdout)
    sys.exit(0)
errs = [i for i in payload.get("issues",[]) if i.get("severity")=="ERROR"]
print(f"ERRORS: {len(errs)}");
for i in errs[:50]:
    print(f"- {i.get('code')} :: {i.get('path')}")
PY
  exit 1
}

echo "✅ Manifest rafraîchi et tests schémas OK (sauf autres erreurs)."

#!/usr/bin/env bash
set -euo pipefail

# -------------------- GARDEFOU : NE PAS FERMER LA FENÊTRE --------------------
KEEP_OPEN="${KEEP_OPEN:-1}"
stay_open() {
  local rc=$?
  echo
  echo "[normalize-constants] Script terminé avec exit code: $rc"
  if [[ "${KEEP_OPEN}" == "1" && -t 1 && -z "${CI:-}" ]]; then
    echo "[normalize-constants] Appuie sur Entrée pour quitter…"
    read -r _
  fi
}
trap 'stay_open' EXIT
# -----------------------------------------------------------------------------


echo "==> (0) Contexte dépôt"
cd "$(git rev-parse --show-toplevel)"
mkdir -p .ci-out

echo "==> (1) Scan & normalisation: constants list -> object (zz-configuration + zz-schemas)"
python - <<'PY'
from pathlib import Path
import json, sys, shutil, datetime

ROOT = Path(".").resolve()
TARGET_DIRS = [ROOT/"zz-configuration", ROOT/"zz-schemas"]

def list_to_object(lst):
    out = {}
    for item in lst:
        # {"name": "...", "value": X} ou {"key": "...", "value": X}
        if isinstance(item, dict):
            k = item.get("name", item.get("key"))
            if k is not None and "value" in item:
                out[str(k)] = item["value"]
                continue
        # ["k", v] ou ("k", v)
        if isinstance(item, (list, tuple)) and len(item) == 2:
            k, v = item
            out[str(k)] = v
            continue
        # "k=v" (optionnel)
        if isinstance(item, str) and "=" in item:
            k, v = item.split("=", 1)
            v = v.strip()
            if v.lower() in ("true","false"): vv = (v.lower()=="true")
            else:
                try: vv=int(v)
                except:
                    try: vv=float(v)
                    except: vv=v
            out[str(k).strip()] = vv
    return out if out else None

def walk(obj, changed_flag):
    if isinstance(obj, dict):
        if "constants" in obj and isinstance(obj["constants"], list):
            conv = list_to_object(obj["constants"])
            if conv is not None:
                obj["constants"] = conv
                changed_flag[0] += 1
        for v in obj.values():
            walk(v, changed_flag)
    elif isinstance(obj, list):
        for v in obj:
            walk(v, changed_flag)

changed_files = []
ts = datetime.datetime.now(datetime.timezone.utc).strftime("%Y%m%dT%H%M%SZ")

for base in TARGET_DIRS:
    if not base.exists():
        continue
    for fp in sorted(base.rglob("*.json")):
        # ignorer d'éventuelles sorties non versionnées
        if ".ci-out" in fp.parts:
            continue
        try:
            txt = fp.read_text(encoding="utf-8")
            data = json.loads(txt)
        except Exception:
            continue
        changed = [0]
        walk(data, changed)
        if changed[0]:
            # sauvegarde horodatée
            shutil.copy2(fp, fp.with_suffix(fp.suffix + f".bak.{ts}"))
            fp.write_text(json.dumps(data, indent=2, ensure_ascii=False) + "\n", encoding="utf-8")
            changed_files.append(str(fp.relative_to(ROOT)))

print(json.dumps({"normalized_files": changed_files, "count": len(changed_files)}, indent=2, ensure_ascii=False))
PY

echo "==> (2) pre-commit quick (tolérant)"
pre-commit run end-of-file-fixer -a || true
pre-commit run trailing-whitespace -a || true
pre-commit run check-yaml -a || true

echo "==> (3) Registre & schémas (registre -> .ci-out/)"
KEEP_OPEN=0 tools/ci_step9_parameters_registry_guard.sh || true
KEEP_OPEN=0 tools/ci_step6_schemas_guard.sh

echo "==> (4) Commit & push si des JSON ont changé"
if ! git diff --quiet -- zz-configuration zz-schemas; then
  git add zz-configuration zz-schemas
  git commit -m "normalize: constants list→object across zz-configuration & zz-schemas; revalidate"
  git push || true
else
  echo "Aucun changement à committer."
fi

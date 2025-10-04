#!/usr/bin/env bash
set -euo pipefail

# -------------------- GARDEFOU : NE PAS FERMER LA FENÊTRE --------------------
KEEP_OPEN="${KEEP_OPEN:-1}"
stay_open() {
  local rc=$?
  echo
  echo "[fix-consts-deep] Script terminé avec exit code: $rc"
  if [[ "${KEEP_OPEN}" == "1" && -t 1 && -z "${CI:-}" ]]; then
    echo "[fix-consts-deep] Appuie sur Entrée pour quitter…"
    # shellcheck disable=SC2034
    read -r _
  fi
}
trap 'stay_open' EXIT
# -----------------------------------------------------------------------------


echo "==> (0) Contexte dépôt"
cd "$(git rev-parse --show-toplevel)"
mkdir -p .ci-out

target="zz-schemas/results_schema_examples.json"
[[ -f "$target" ]] || { echo "Fichier introuvable: $target"; exit 1; }

echo "==> (1) Sauvegarde du fichier cible"
cp -f "$target" "${target}.bak.$(date -u +%Y%m%dT%H%M%SZ)"

echo "==> (2) Conversion profonde des 'constants' list -> object"
python - <<'PY'
from pathlib import Path
import json

fp = Path("zz-schemas/results_schema_examples.json")
data = json.loads(fp.read_text(encoding="utf-8"))

changed = 0

def list_to_object(lst):
    out = {}
    for item in lst:
        # cas {"name": "...", "value": X} ou {"key": "...", "value": X}
        if isinstance(item, dict):
            k = item.get("name", item.get("key"))
            if k is not None and "value" in item:
                out[str(k)] = item["value"]
                continue
        # cas ["k", v] / ("k", v)
        if isinstance(item, (list, tuple)) and len(item) == 2:
            k, v = item
            out[str(k)] = v
            continue
        # cas "k=v" (rare)
        if isinstance(item, str) and "=" in item:
            k, v = item.split("=", 1)
            v = v.strip()
            # tentative de typage léger
            if v.lower() in ("true","false"):
                vv = (v.lower()=="true")
            else:
                try: vv=int(v);
                except:
                    try: vv=float(v)
                    except: vv=v
            out[str(k).strip()] = vv
    return out if out else None

def walk(obj):
    global changed
    if isinstance(obj, dict):
        # si une clé 'constants' est une liste -> convertir
        if "constants" in obj and isinstance(obj["constants"], list):
            conv = list_to_object(obj["constants"])
            if conv is not None:
                obj["constants"] = conv
                changed += 1
        # recurse
        for v in obj.values():
            walk(v)
    elif isinstance(obj, list):
        for v in obj:
            walk(v)

walk(data)

if changed:
    fp.write_text(json.dumps(data, indent=2, ensure_ascii=False) + "\n", encoding="utf-8")
    print(f"[schemas] conversions appliquées: {changed}")
else:
    print("[schemas] aucun changement requis")
PY

echo "==> (3) pre-commit ciblé (tolérant)"
pre-commit run end-of-file-fixer -a || true
pre-commit run trailing-whitespace -a || true
pre-commit run check-yaml -a || true

echo "==> (4) Registre & schémas (registre -> .ci-out/)"
KEEP_OPEN=0 tools/ci_step9_parameters_registry_guard.sh || true
KEEP_OPEN=0 tools/ci_step6_schemas_guard.sh

echo "==> (5) Commit & push si diff"
if ! git diff --quiet -- "$target"; then
  git add "$target"
  git commit -m "schemas: normalize results_schema_examples constants (list→object) + revalidate"
  git push || true
else
  echo "Aucun changement à committer."
fi

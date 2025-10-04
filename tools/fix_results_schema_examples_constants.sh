#!/usr/bin/env bash
set -euo pipefail
KEEP_OPEN="${KEEP_OPEN:-1}"
stay_open(){ rc=$?; echo; echo "[fix-results-schema] Script terminé avec exit code: $rc"; if [[ "$KEEP_OPEN" == "1" && -t 1 && -z "${CI:-}" ]]; then echo "[fix-results-schema] Appuie sur Entrée pour quitter…"; read -r _; fi; }
trap 'stay_open' EXIT
cd "$(git rev-parse --show-toplevel)"

python - <<'PY'
from pathlib import Path
import json

target = Path("zz-schemas/results_schema_examples.json")
data = json.loads(target.read_text(encoding="utf-8"))
orig = json.dumps(data, ensure_ascii=False, sort_keys=True)

def list_to_object(lst):
    out = {}
    for item in lst:
        if isinstance(item, dict):
            # formats tolérés: {"name": "...", "value": X} ou {"key": "...", "value": X}
            k = item.get("name", item.get("key"))
            if k is not None and "value" in item:
                out[str(k)] = item["value"]
        elif isinstance(item, (list, tuple)) and len(item) == 2:
            k, v = item
            out[str(k)] = v
    # si on n'a rien pu convertir, on renvoie None pour ne pas casser
    return out if out else None

def walk(obj):
    if isinstance(obj, dict):
        for k, v in list(obj.items()):
            if k == "constants" and isinstance(v, list):
                maybe = list_to_object(v)
                if maybe is not None:
                    obj[k] = maybe
            else:
                walk(v)
    elif isinstance(obj, list):
        for it in obj:
            walk(it)

walk(data)
new = json.dumps(data, ensure_ascii=False, sort_keys=True)
if new != orig:
    target.write_text(json.dumps(data, ensure_ascii=False, indent=2), encoding="utf-8")
    print("[schemas] patched:", target)
else:
    print("[schemas] nothing to change")

PY

# Valide rapidement & commit/push si diff
pre-commit run --files zz-schemas/results_schema_examples.json || true
git add zz-schemas/results_schema_examples.json || true
if ! git diff --cached --quiet; then
  git commit -m "fix(schemas): make 'constants' an object in results_schema_examples"
  git push
else
  echo "Rien à committer"
fi

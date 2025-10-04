#!/usr/bin/env bash
set -euo pipefail

# -------------------- GARDEFOU : NE PAS FERMER LA FENÊTRE --------------------
KEEP_OPEN="${KEEP_OPEN:-1}"
stay_open() {
  local rc=$?
  echo
  echo "[fix-constants] Script terminé avec exit code: $rc"
  if [[ "${KEEP_OPEN}" == "1" && -t 1 && -z "${CI:-}" ]]; then
    echo "[fix-constants] Appuie sur Entrée pour quitter…"
    # shellcheck disable=SC2034
    read -r _
  fi
}
trap 'stay_open' EXIT
# -----------------------------------------------------------------------------


echo "==> (0) Contexte dépôt"
cd "$(git rev-parse --show-toplevel)"
mkdir -p .ci-out

echo "==> (1) Corrige zz-schemas/results_schema_examples.json (constants: list -> object)"
python - <<'PY'
from pathlib import Path
import json

p = Path("zz-schemas/results_schema_examples.json")
if not p.exists():
    raise SystemExit(f"[ERREUR] Introuvable: {p}")

data = json.loads(p.read_text(encoding="utf-8"))

def to_object(node):
    out = {}
    for item in node:
        if isinstance(item, dict):
            k = item.get("name", item.get("key"))
            if k is not None and "value" in item:
                out[str(k)] = item["value"]
        elif isinstance(item, (list, tuple)) and len(item) == 2:
            k, v = item
            out[str(k)] = v
    return out if out else None

def walk(obj):
    if isinstance(obj, dict):
        if "constants" in obj and isinstance(obj["constants"], list):
            conv = to_object(obj["constants"])
            if conv is not None:
                obj["constants"] = conv
        for v in obj.values():
            walk(v)
    elif isinstance(obj, list):
        for v in obj:
            walk(v)

before = json.dumps(data, sort_keys=True, ensure_ascii=False)
walk(data)
after  = json.dumps(data, sort_keys=True, ensure_ascii=False)

if after != before:
    p.write_text(json.dumps(data, indent=2, ensure_ascii=False) + "\n", encoding="utf-8")
    print("[schemas] results_schema_examples.json corrigé (constants -> object)")
else:
    print("[schemas] aucun changement requis")
PY

echo "==> (2) Registre & schémas (écriture du registre dans .ci-out/)"
KEEP_OPEN=0 tools/ci_step9_parameters_registry_guard.sh
KEEP_OPEN=0 tools/ci_step6_schemas_guard.sh

echo "==> (3) Hooks (tolérant) pour auto-fix trivials"
pre-commit run --all-files || true

echo "==> (4) Commit & push si diff sur le schéma"
if ! git diff --quiet -- zz-schemas/results_schema_examples.json; then
  git add zz-schemas/results_schema_examples.json
  git commit -m "schemas: constants -> object in results_schema_examples; registry guard clean"
  git push || true
else
  echo "Aucun changement à committer."
fi

#!/usr/bin/env bash
set -euo pipefail
KEEP_OPEN="${KEEP_OPEN:-1}"
stay_open(){ rc=$?; echo; echo "[find-constants-list] Script terminé avec exit code: $rc"; if [[ "$KEEP_OPEN" == "1" && -t 1 && -z "${CI:-}" ]]; then echo "[find-constants-list] Appuie sur Entrée pour quitter…"; read -r _; fi; }
trap 'stay_open' EXIT

cd "$(git rev-parse --show-toplevel)"

python - <<'PY'
from pathlib import Path
import json, sys

root = Path("zz-schemas")
hits = []
for fp in root.rglob("*.json"):
    try:
        data = json.loads(fp.read_text(encoding="utf-8"))
    except Exception:
        continue
    def walk(obj, path="$"):
        if isinstance(obj, dict):
            for k,v in obj.items():
                if k=="constants" and isinstance(v, list):
                    hits.append((str(fp), path+".constants"))
                walk(v, path+f".{k}")
        elif isinstance(obj, list):
            for i,v in enumerate(obj):
                walk(v, path+f"[{i}]")
    walk(data)

if hits:
    print("Trouvés (constants en LISTE):")
    for f,p in hits:
        print(f" - {f} :: {p}")
else:
    print("Aucune occurrence de 'constants' en liste.")
PY

#!/usr/bin/env bash
set -euo pipefail
KEEP_OPEN="${KEEP_OPEN:-1}"
stay_open(){ rc=$?; echo; echo "[banish-tex] Script terminé avec exit code: $rc"; if [[ "$KEEP_OPEN" == "1" && -t 1 && -z "${CI:-}" ]]; then echo "[banish-tex] Appuie sur Entrée pour quitter…"; read -r _; fi; }
trap 'stay_open' EXIT

cd "$(git rev-parse --show-toplevel)"
mkdir -p .ci-out

echo "==> (1) Déplace les .tex des chapitres 01..10 vers legacy-tex/ (idempotent)"
mapfile -t TRACKED < <(git ls-files | grep -E '^(0[1-9]|10)-.*/.*\.tex$' || true)
if (( ${#TRACKED[@]} )); then
  for p in "${TRACKED[@]}"; do
    dst="legacy-tex/$p"
    mkdir -p "$(dirname "$dst")"
    if [[ -e "$p" ]]; then
      git mv -f "$p" "$dst"
      echo "moved: $p -> $dst"
    fi
  done
else
  echo "Aucun .tex à déplacer dans 01..10"
fi

echo "==> (2) Retire *tous* les .tex du manifest_master.json"
python - <<'PY'
from pathlib import Path
import json

man = Path("zz-manifests/manifest_master.json")
data = json.loads(man.read_text(encoding="utf-8"))
entries = data.get("entries", data if isinstance(data, list) else [])
changed = 0

if isinstance(entries, list):
    before = len(entries)
    entries = [e for e in entries if not str(e.get("path","")).endswith(".tex")]
    changed = before - len(entries)
    if isinstance(data, dict) and "entries" in data and isinstance(data["entries"], list):
        data["entries"] = entries
    else:
        data = entries
elif isinstance(entries, dict):
    before = len(entries)
    for k in list(entries.keys()):
        if str(k).endswith(".tex"):
            entries.pop(k, None); changed += 1
    data["entries"] = entries

man.write_text(json.dumps(data, indent=2, ensure_ascii=False) + "\n", encoding="utf-8")
print(f"[manifest] .tex retirés: {changed}")
PY

echo "==> (3) .gitattributes : legacy-tex export-ignore (idempotent)"
grep -q -E '^[[:space:]]*legacy-tex[[:space:]]+export-ignore[[:space:]]*$' .gitattributes 2>/dev/null \
  || echo "legacy-tex export-ignore" >> .gitattributes

echo "==> (4) pre-commit (tolérant)"
pre-commit run --all-files || true

echo "==> (5) Refresh manifest (contenu + git) puis commit/push"
KEEP_OPEN=0 DROP_MISSING=0 bash tools/refresh_master_manifest_full.sh || true
git add -A
git commit -m "build: banish .tex from chapters and manifest; add legacy-tex export-ignore" || true
git push || true

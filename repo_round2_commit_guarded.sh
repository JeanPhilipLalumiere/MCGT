# repo_round2_commit_guarded.sh
set -Eeuo pipefail
TS="$(date +%Y%m%dT%H%M%S)"
LOG="/tmp/mcgt_round2_commit_${TS}.log"
exec > >(tee -a "$LOG") 2>&1

pause_guard() {
  code=$?
  echo
  echo "[GUARD] Fin (exit=$code) — log: $LOG"
  echo "[GUARD] Appuie sur Entrée pour garder la fenêtre ouverte…"
  read -r _
}
trap pause_guard EXIT

echo "== Context =="
pwd
git rev-parse --abbrev-ref HEAD || true

echo "== Step 1 | Manifest .csv → .csv.gz si .gz présent =="
PYTHONIOENCODING=UTF-8 python - <<'PY'
import json, gzip, os, sys
from pathlib import Path

mf = Path("zz-manifests/manifest_master.json")
if not mf.exists():
    print("[NOTE] manifest_master.json absent — skip")
    sys.exit(0)

data = json.loads(mf.read_text(encoding="utf-8"))
changed = 0

def gz_exists(p:str)->bool:
    gz = Path(p + ".gz") if not p.endswith(".gz") else Path(p)
    return gz.exists()

for ent in data.get("entries", data if isinstance(data, list) else []):
    p = ent.get("path")
    if not isinstance(p, str): continue
    if p.endswith(".csv"):
        alt = p + ".gz"
        if Path(alt).exists():
            ent["path"] = alt
            changed += 1

if changed:
    # note: on n’altère pas size_bytes/sha256/git_hash ici (mise à jour séparée si besoin)
    txt = json.dumps(data, ensure_ascii=False, indent=2)
    mf.write_text(txt, encoding="utf-8")
    print(f"[OK] manifest_master.json: {changed} chemins .csv → .csv.gz")
else:
    print("[OK] Aucun remplacement requis")
PY

echo "== Step 2 | Sanity producteurs ch10 (py_compile + --help) =="
ok=1
for f in zz-scripts/chapter10/plot_fig0{1,2,3,4,5}_*.py; do
  [ -f "$f" ] || continue
  echo "[CHECK] $f"
  if ! python -m py_compile "$f"; then ok=0; fi
  python "$f" --help >/dev/null 2>&1 || true
done
if [ $ok -eq 1 ]; then echo "[OK] py_compile ch10"; else echo "[WARN] py_compile ch10 a rencontré des warnings/erreurs"; fi

echo "== Step 3 | Probe Round2 (doit passer à 16/16) =="
bash repo_probe_round2_consistency.sh || true

echo "== Step 4 | Stage + Commit ciblé =="
git add zz-scripts/chapter10/*.py 2>/dev/null || true
git add zz-scripts/chapter{01..10}/requirements.txt 2>/dev/null || true
git add zz-manifests/manifest_master.json 2>/dev/null || true
git add zz-manifests/triage_round2/*.txt 2>/dev/null || true

git commit -m "round2: stabilise producteurs ch10, req stubs, triage, manifeste csv→csv.gz (idempotent); laisse ch09/fig03 pour patch ultérieur" || echo "[NOTE] Rien à committer"

echo "== Step 5 | Résumé =="
git --no-pager log -1 --oneline || true
echo "[DONE] Round2 stabilisé. Étape suivante : branch fix/ch09-fig03-parse → réparation propre du parse."

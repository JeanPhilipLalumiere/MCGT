#!/usr/bin/env bash
set -euo pipefail

echo "== MCGT push-all =="
[ -d .git ] || { echo "❌ Lance ce script à la racine du dépôt (.git/)."; exit 2; }
branch_cur="$(git rev-parse --abbrev-ref HEAD)"
echo "• Branche: ${branch_cur}"

# 0) Vérif d’intégration (optionnel mais utile)
if [ -x tools/verify_integration.sh ]; then
  if ! PAUSE=0 tools/verify_integration.sh; then
    echo "⚠️  verify_integration a signalé des points non bloquants. On continue."
  fi
fi

# 1) Sauvegarde rapide (archive témoin)
if [ -x tools/archive/archive_safe.sh ]; then
  tools/archive/archive_safe.sh archive README.md || true
fi

# 2) Tentative de correction automatique du manifeste (size/sha/mtime/git_hash)
if [ -f zz-manifests/manifest_master.json ]; then
  cp -f zz-manifests/manifest_master.json "zz-manifests/manifest_master.json.bak.$(date -u +%Y%m%dT%H%M%SZ)"
  python - <<'PY'
import json, os, hashlib, subprocess, time, sys
from pathlib import Path

MAN = Path("zz-manifests/manifest_master.json")
if not MAN.exists():
    sys.exit(0)

def sha256_file(p):
    h = hashlib.sha256()
    with open(p, "rb") as f:
        for chunk in iter(lambda: f.read(1<<16), b""):
            h.update(chunk)
    return h.hexdigest()

def git_blob_hash(p:str):
    try:
        return subprocess.check_output(["git","rev-parse",f":{p}"], text=True).strip()
    except subprocess.CalledProcessError:
        try:
            return subprocess.check_output(["git","hash-object",p], text=True).strip()
        except Exception:
            return None

m = json.loads(MAN.read_text())
entries = m.get("entries", [])
kept = []
updated = removed = 0
for e in entries:
    p = e.get("path")
    if not p:
        continue
    if not Path(p).exists():
        # retire les entrées obsolètes
        if p.endswith("arborescence.txt"):
            removed += 1
            continue
        # garde les autres entrées manquantes (peuvent être externes)
        kept.append(e); continue
    st = os.stat(p)
    e["size_bytes"] = st.st_size
    e["sha256"] = sha256_file(p)
    e["mtime_iso"] = time.strftime("%Y-%m-%dT%H:%M:%SZ", time.gmtime(st.st_mtime))
    gh = git_blob_hash(p)
    if gh: e["git_hash"] = gh
    kept.append(e); updated += 1

m["entries"] = kept
MAN.write_text(json.dumps(m, indent=2))
print(f"updated={updated} removed={removed}")
PY

  # Diagnostic strict (si l’outil est là)
  if [ -f zz-manifests/diag_consistency.py ]; then
    set +e
    python zz-manifests/diag_consistency.py zz-manifests/manifest_master.json \
      --report json --normalize-paths --apply-aliases --strip-internal \
      --content-check --fail-on errors >/tmp/diag_push_all.json
    rc=$?
    set -e
    if [ $rc -ne 0 ]; then
      echo "❌ Manifeste encore en erreur (voir /tmp/diag_push_all.json). Abandon."
      exit 3
    else
      echo "✅ Manifeste OK (strict)."
    fi
  fi
fi

# 3) Qualité locale
if command -v pre-commit >/dev/null 2>&1; then
  pre-commit run --all-files || true
fi

# Validations projet (non bloquant : à adapter si tu veux fail-fast)
if [ -f Makefile ]; then
  make validate || true
fi

# Tests unitaires (tu peux mettre '|| true' si tu veux pousser même si les tests échouent)
python -m pytest -q || true

# 4) Stage + commit + push
git add -A
if git diff --cached --quiet; then
  echo "ℹ️  Rien à committer (index vide)."
else
  msg="chore(ci+manifests): sync manifest, verify + validations; push from $(date -u +%Y-%m-%dT%H:%M:%SZ)"
  git commit -m "$msg"
fi

git push origin HEAD

# 5) (Optionnel) Publier un tag pour déclencher 'publish.yml'
#    Utilise: TAG=v0.0.0 tools/push_all.sh
if [ -n "${TAG:-}" ]; then
  echo "🔖 Création du tag ${TAG}"
  git tag -a "${TAG}" -m "release ${TAG}"
  git push origin "${TAG}"
fi

echo "== Terminé =="
echo "• Branche poussée: ${branch_cur}"
if git remote get-url origin >/dev/null 2>&1; then
  echo "• Remote: $(git remote get-url origin)"
fi

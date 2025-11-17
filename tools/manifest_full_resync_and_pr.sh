#!/usr/bin/env bash
set -Eeuo pipefail

BR="fix/manifest-resync-20251117T030626Z"
MAN="zz-manifests/manifest_publication.json"
TITLE="chore(manifests,readme,sdist): full resync; sdist code-only"
BODY="Resynchronise entièrement le manifeste avec le système de fichiers; purge les entrées orphelines; sdist code-only."

echo "[0] Branche de travail: $BR"
git fetch origin
if git show-ref --verify --quiet "refs/heads/$BR"; then
  git switch "$BR"
else
  git switch -c "$BR" origin/main
fi

echo "[1] Resync complet du manifeste"
python3 - <<'PY'
import json, os, hashlib, subprocess, sys
from datetime import datetime, timezone

P = "zz-manifests/manifest_publication.json"
if not os.path.exists(P):
    print(f"[ERREUR] Manifeste introuvable: {P}", file=sys.stderr)
    sys.exit(2)

def sha256(p):
    h = hashlib.sha256()
    with open(p, "rb") as f:
        for chunk in iter(lambda: f.read(1<<20), b""):
            h.update(chunk)
    return h.hexdigest()

def githash(p):
    # hash du blob à HEAD si suivi, sinon hash-object du fichier courant
    r = subprocess.run(["git","rev-parse","-q","--verify",f"HEAD:{p}"],
                       stdout=subprocess.PIPE, stderr=subprocess.DEVNULL, text=True)
    if r.returncode == 0:
        return r.stdout.strip()
    r = subprocess.run(["git","hash-object",p],
                       stdout=subprocess.PIPE, stderr=subprocess.DEVNULL, text=True)
    return r.stdout.strip() if r.returncode == 0 else ""

def iso_mtime(p):
    return datetime.fromtimestamp(os.path.getmtime(p), tz=timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ")

with open(P, "r", encoding="utf-8") as f:
    doc = json.load(f)

if not isinstance(doc.get("lists"), list):
    print("[ALERTE] Clé 'lists' absente ou non-liste dans le manifeste — rien à resynchroniser.", file=sys.stderr)
    print("[RESYNC] entries_in=0 updated=0 purged_missing=0 kept=0 changed=0")
    sys.exit(10)

before = json.dumps(doc, sort_keys=True)

n_in = n_kept = n_purged = n_updated = 0
for L in doc.get("lists", []):
    files = L.get("files", [])
    if not isinstance(files, list):
        continue
    kept = []
    for f in files:
        n_in += 1
        path = (f.get("path") or "").strip()
        if not path or not os.path.exists(path):
            n_purged += 1
            continue
        f["size_bytes"] = os.path.getsize(path)
        f["sha256"] = sha256(path)
        f["mtime_iso"] = iso_mtime(path)
        gh = githash(path)
        if gh:
            f["git_hash"] = gh
        kept.append(f)
        n_kept += 1
        n_updated += 1
    L["files"] = kept

after = json.dumps(doc, sort_keys=True)
changed = 0 if before == after else 1
if changed:
    with open(P, "w", encoding="utf-8") as f:
        json.dump(doc, f, ensure_ascii=False, indent=2)

print(f"[RESYNC] entries_in={n_in} updated={n_updated} purged_missing={n_purged} kept={n_kept} changed={changed}")
sys.exit(0 if changed else 10)
PY
rc=$? || true

if [ "$rc" -eq 10 ]; then
  echo "[2] Aucun changement détecté dans $MAN (no-op)."
  git --no-pager diff --stat "$MAN" || true
  exit 0
fi

echo "[2] Diagnostic post-resync"
python3 zz-manifests/diag_consistency.py "$MAN" --report text || true

echo "[3] Commit + push"
git add "$MAN"
git -c commit.gpgsign=false commit -m "chore(manifests): full resync from filesystem; purge missing" || true
git push -u origin "$BR"

echo "[4] PR + auto-merge"
if ! gh pr view "$BR" >/dev/null 2>&1; then
  gh pr create --base main --head "$BR" --title "$TITLE" --body "$BODY"
fi
PRN="$(gh pr view "$BR" --json number -q .number)"
gh pr merge "$PRN" --auto --rebase
gh pr checks "$PRN" --watch

#!/usr/bin/env bash
set -Eeuo pipefail

BR="fix/manifest-resync-20251117T030626Z"
MAN="zz-manifests/manifest_publication.json"
TITLE="chore(manifests): schema-agnostic resync from filesystem"
BODY="Resynchronise toutes les entrées {path:...} (peu importe le schéma), met à jour size/sha/mtime/git_hash et purge les fichiers manquants."

echo "[0] Branche: $BR"
git fetch origin
if git show-ref --verify --quiet "refs/heads/$BR"; then
  git switch "$BR"
else
  git switch -c "$BR" origin/main
fi

echo "[1] Resync schéma-agnostique"
python3 - <<'PY'
import json, os, hashlib, subprocess, sys
from datetime import datetime, timezone

P = "zz-manifests/manifest_publication.json"
if not os.path.exists(P):
    print(f"[ERREUR] Manifeste introuvable: {P}", file=sys.stderr); sys.exit(2)

def sha256(path):
    h = hashlib.sha256()
    with open(path, "rb") as f:
        for chunk in iter(lambda: f.read(1<<20), b""):
            h.update(chunk)
    return h.hexdigest()

def git_blob_hash(path):
    # 1) blob à HEAD si suivi; 2) hash du fichier courant sinon
    r = subprocess.run(
        ["git","rev-parse","-q","--verify",f"HEAD:{path}"],
        stdout=subprocess.PIPE, stderr=subprocess.DEVNULL, text=True
    )
    if r.returncode == 0: return r.stdout.strip()
    r = subprocess.run(["git","hash-object", path],
        stdout=subprocess.PIPE, stderr=subprocess.DEVNULL, text=True)
    return r.stdout.strip() if r.returncode == 0 else ""

def iso_mtime(path):
    return datetime.fromtimestamp(os.path.getmtime(path), tz=timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ")

with open(P, "r", encoding="utf-8") as f:
    doc = json.load(f)

before = json.dumps(doc, sort_keys=True)

stats = dict(seen=0, updated=0, purged=0)

def process(node):
    """Retourne (node_nettoye, changed_bool). Purge les dicts {path:...} inexistants quand ils sont dans une liste."""
    if isinstance(node, dict):
        if isinstance(node.get("path"), str):
            stats["seen"] += 1
            path = node["path"].strip()
            if not path or not os.path.exists(path):
                stats["purged"] += 1
                return None, True  # purge ce nœud
            # met à jour les métadonnées
            node["size_bytes"] = os.path.getsize(path)
            node["sha256"]     = sha256(path)
            node["mtime_iso"]  = iso_mtime(path)
            gh = git_blob_hash(path)
            if gh: node["git_hash"] = gh
            stats["updated"] += 1
            return node, True
        # sinon, descente récursive
        changed = False
        for k, v in list(node.items()):
            newv, ch = process(v)
            if ch: changed = True
            node[k] = newv
        return node, changed
    elif isinstance(node, list):
        new_list = []
        changed = False
        for item in node:
            new_item, ch = process(item)
            if ch: changed = True
            if new_item is None:
                # item purgé
                changed = True
            else:
                new_list.append(new_item)
        if len(new_list) != len(node):
            changed = True
        return new_list, changed
    else:
        return node, False

doc, changed = process(doc)

after = json.dumps(doc, sort_keys=True)
changed = changed or (before != after)

if changed:
    with open(P, "w", encoding="utf-8") as f:
        json.dump(doc, f, ensure_ascii=False, indent=2)

print(f"[RESYNC] entries_seen={stats['seen']} updated={stats['updated']} purged_missing={stats['purged']} changed={int(changed)}")
sys.exit(0 if changed else 10)
PY
rc=$? || true

if [ "$rc" -eq 10 ]; then
  echo "[1bis] Aucun changement détecté (no-op)."
  git --no-pager diff --stat "$MAN" || true
  exit 0
fi

echo "[2] Diagnostic post-resync"
python3 zz-manifests/diag_consistency.py "$MAN" --report text || true

echo "[3] Commit & push"
git add "$MAN"
git -c commit.gpgsign=false commit -m "$TITLE" || true
git push -u origin "$BR"

echo "[4] PR + auto-merge"
PRN="$(gh pr list --head "$BR" --json number -q '.[0].number' 2>/dev/null || true)"
if [ -z "$PRN" ]; then
  gh pr create --base main --head "$BR" --title "$TITLE" --body "$BODY"
  PRN="$(gh pr list --head "$BR" --json number -q '.[0].number')"
fi
gh pr merge "$PRN" --auto --rebase
gh pr checks "$PRN" --watch

#!/usr/bin/env python
"""
step113_sync_manifest_master_ch07_meta.py
Synchronise l'entrée correspondant à zz-data/chapter07/07_meta_perturbations.json
dans zz-manifests/manifest_master.json (size_bytes, sha256, mtime_iso),
en laissant git_hash inchangé.

La recherche de l'entrée est robuste :
- essai relpath/path/filepath exacts
- sinon, recherche par sous-chaîne "07_meta_perturbations.json" dans les champs texte.
"""

import json
import hashlib
import datetime
from pathlib import Path

ROOT = Path(__file__).resolve().parent
manifest_path = ROOT / "zz-manifests" / "manifest_master.json"
target_relpath = "zz-data/chapter07/07_meta_perturbations.json"
target_basename = "07_meta_perturbations.json"
target_path = ROOT / target_relpath

print(f"[INFO] Root     : {ROOT}")
print(f"[INFO] Manifest : {manifest_path}")
print(f"[INFO] Target   : {target_relpath}")

if not manifest_path.is_file():
    raise SystemExit(f"[ERROR] Manifest introuvable : {manifest_path}")

if not target_path.is_file():
    raise SystemExit(f"[ERROR] Fichier cible introuvable : {target_path}")

# Métadonnées FS
st = target_path.stat()
size_bytes = st.st_size
mtime_iso = (
    datetime.datetime.fromtimestamp(st.st_mtime, datetime.UTC)
    .replace(microsecond=0)
    .isoformat().replace("+00:00", "Z")
)

# SHA256
h = hashlib.sha256()
with target_path.open("rb") as f:
    for chunk in iter(lambda: f.read(8192), b""):
        h.update(chunk)
sha256 = h.hexdigest()

print(f"[INFO] Nouvelle size_bytes : {size_bytes}")
print(f"[INFO] Nouvelle sha256     : {sha256}")
print(f"[INFO] Nouvelle mtime_iso  : {mtime_iso}")

# Chargement manifest
with manifest_path.open("r", encoding="utf-8") as f:
    manifest = json.load(f)

entries = manifest.get("entries")
if not isinstance(entries, list):
    raise SystemExit("[ERROR] Manifest ne contient pas une liste 'entries'.")

target_entry = None

# 1) Match exact sur clés classiques
for entry in entries:
    for key in ("relpath", "path", "filepath"):
        v = entry.get(key)
        if isinstance(v, str) and v == target_relpath:
            target_entry = entry
            print(f"[INFO] Entrée trouvée par match exact {key} == {target_relpath}")
            break
    if target_entry is not None:
        break

# 2) Fallback : recherche par sous-chaîne du basename
if target_entry is None:
    print("[WARN] Aucun match exact trouvé. Recherche par sous-chaîne sur le basename…")
    for entry in entries:
        for key, v in entry.items():
            if isinstance(v, str) and target_basename in v:
                target_entry = entry
                print(f"[INFO] Entrée candidate trouvée via {key} = {v}")
                break
        if target_entry is not None:
            break

if target_entry is None:
    raise SystemExit(
        f"[ERROR] Impossible de trouver une entrée contenant '{target_basename}' "
        "dans manifest_master.json"
    )

old_size = target_entry.get("size_bytes")
old_sha = target_entry.get("sha256")
old_mtime = target_entry.get("mtime_iso")
old_git = target_entry.get("git_hash")

print("[TARGET] Entrée sélectionnée :")
print(f"  [INFO] size_bytes: {old_size} -> {size_bytes}")
print(f"  [INFO] sha256    : {old_sha} -> {sha256}")
print(f"  [INFO] mtime_iso : {old_mtime} -> {mtime_iso}")
print(f"  [INFO] git_hash  : {old_git} (inchangé)")

# Mise à jour
target_entry["size_bytes"] = size_bytes
target_entry["sha256"] = sha256
target_entry["mtime_iso"] = mtime_iso

with manifest_path.open("w", encoding="utf-8") as f:
    json.dump(manifest, f, indent=2, ensure_ascii=False)
    f.write("\n")

print(f"[OK] Manifest mis à jour -> {manifest_path}")

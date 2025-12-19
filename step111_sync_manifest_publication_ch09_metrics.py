from __future__ import annotations

import json
import hashlib
import subprocess
from pathlib import Path
from datetime import datetime, timezone

# Racine du dépôt = répertoire de ce script
root = Path(__file__).resolve().parent
manifest_path = root / "zz-manifests" / "manifest_publication.json"

target = "zz-data/chapter09/09_metrics_phase.json"

print(f"[INFO] Root     : {root}")
print(f"[INFO] Manifest : {manifest_path}")
print(f"[INFO] Target   : {target}")


def sha256_file(path: Path) -> str:
    h = hashlib.sha256()
    with path.open("rb") as f:
        for chunk in iter(lambda: f.read(8192), b""):
            h.update(chunk)
    return h.hexdigest()


def git_hash(path: Path) -> str:
    rel = path.as_posix()
    try:
        out = (
            subprocess.check_output(
                ["git", "log", "-n", "1", "--pretty=format:%H", "--", rel],
                cwd=root,
            )
            .decode()
            .strip()
        )
        return out
    except Exception:
        return ""


# Charge le manifest
with manifest_path.open("r", encoding="utf-8") as f:
    manifest = json.load(f)

# Détection automatique de la liste d'entrées
if isinstance(manifest, dict):
    candidate_keys = [k for k, v in manifest.items() if isinstance(v, list)]
    if not candidate_keys:
        raise SystemExit(
            "Impossible de trouver une liste d'entrées dans le manifest "
            "(aucune valeur de type list au niveau racine)."
        )
    entries_key = candidate_keys[0]
    entries = manifest[entries_key]
    print(f"[INFO] Entrées détectées sous la clé '{entries_key}' (n={len(entries)})")
elif isinstance(manifest, list):
    entries_key = None
    entries = manifest
    print(f"[INFO] Manifest est directement une liste d'entrées (n={len(entries)})")
else:
    raise SystemExit(f"Type de manifest inattendu: {type(manifest)}")


# Vérifie que la cible existe sur le FS
path = root / target
if not path.exists():
    raise SystemExit(f"[FATAL] {target} n'existe pas sur le filesystem.")

stat = path.stat()
size = stat.st_size
sha = sha256_file(path)
git = git_hash(path)
mtime_iso = datetime.fromtimestamp(stat.st_mtime, tz=timezone.utc).strftime(
    "%Y-%m-%dT%H:%M:%SZ"
)

# Patch de l'entrée correspondante
for e in entries:
    if e.get("path") == target:
        print(f"[TARGET] {target}")
        print(f"  [INFO] size_bytes: {e.get('size_bytes')} -> {size}")
        print(f"  [INFO] sha256    : {e.get('sha256')} -> {sha}")
        print(f"  [INFO] mtime_iso : {e.get('mtime_iso')} -> {mtime_iso}")
        print(f"  [INFO] git_hash  : {e.get('git_hash', '')} -> {git}")
        e["size_bytes"] = size
        e["sha256"] = sha
        e["mtime_iso"] = mtime_iso
        e["git_hash"] = git
        break
else:
    raise SystemExit(f"[FATAL] Aucune entrée avec path='{target}' dans le manifest.")


# Écrit le manifest patché
with manifest_path.open("w", encoding="utf-8") as f:
    json.dump(manifest, f, indent=2, sort_keys=True)

print(f"[OK] Manifest mis à jour -> {manifest_path}")

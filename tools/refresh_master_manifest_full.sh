#!/usr/bin/env bash
set -Eeuo pipefail

# -----------------------------------------------------------------------------
# Refresh zz-manifests/manifest_master.json (FULL)
# - Update per-file: sha256, size_bytes, mtime_iso (UTC), git_hash
# - IMPORTANT: git_hash is the Git *blob* hash of the file content (git hash-object)
# - Save a timestamped backup of the manifest before writing
# -----------------------------------------------------------------------------

die() { echo "[refresh-manifest-full][ERROR] $*" >&2; exit 1; }

repo_root="$(git rev-parse --show-toplevel 2>/dev/null)" || die "Not inside a Git repository."
cd "$repo_root"

manifest="zz-manifests/manifest_master.json"
[[ -f "$manifest" ]] || die "Missing manifest: $manifest"

echo "==> (1) Sauvegarde du manifest (timestampée)"
backup_dir="zz-manifests/_backups"
mkdir -p "$backup_dir"
ts="$(date -u +%Y%m%dT%H%M%SZ)"
cp -a "$manifest" "$backup_dir/manifest_master.json.before_refresh.${ts}"

echo "==> (2) Rafraîchit git_hash(blob) + size_bytes + sha256 + mtime_iso (UTC) depuis le repo"

python - <<'PY'
import json, hashlib, os, subprocess
from pathlib import Path
from datetime import datetime, timezone

manifest_path = Path("zz-manifests/manifest_master.json")
repo_root = Path(subprocess.check_output(["git","rev-parse","--show-toplevel"], text=True).strip())

obj = json.loads(manifest_path.read_text(encoding="utf-8"))

if "files" not in obj or not isinstance(obj["files"], list):
    raise SystemExit("[refresh-manifest-full] JSON invalid: expected top-level key 'files' as a list")

now_iso = datetime.now(timezone.utc).replace(microsecond=0).isoformat().replace("+00:00", "Z")

files = obj["files"]
new_files = []
updated = 0
dropped_missing = 0
total = len(files)

def file_sha256(p: Path) -> str:
    h = hashlib.sha256()
    with p.open("rb") as f:
        for chunk in iter(lambda: f.read(1024 * 1024), b""):
            h.update(chunk)
    return h.hexdigest()

def git_blob_hash(p: Path) -> str:
    # Matches diag_consistency behavior: git hash of working-tree content
    return subprocess.check_output(["git","hash-object", str(p)], cwd=repo_root, text=True).strip()

for entry in files:
    if not isinstance(entry, dict) or "path" not in entry:
        # Keep as-is if malformed; do not crash the refresh
        new_files.append(entry)
        continue

    rel = entry["path"]
    p = (repo_root / rel)

    if not p.exists():
        dropped_missing += 1
        continue

    st = p.stat()
    mtime_iso = datetime.fromtimestamp(st.st_mtime, timezone.utc).replace(microsecond=0).isoformat().replace("+00:00", "Z")

    sha256 = file_sha256(p)
    size_bytes = st.st_size
    gith = git_blob_hash(p)

    entry["sha256"] = sha256
    entry["size_bytes"] = size_bytes
    entry["mtime_iso"] = mtime_iso
    entry["git_hash"] = gith

    new_files.append(entry)
    updated += 1

obj["files"] = new_files
obj["generatedAt"] = now_iso
obj["files_updated"] = updated

# Preserve unknown top-level keys; keep ordering as read; pretty print.
manifest_path.write_text(json.dumps(obj, indent=2, ensure_ascii=False) + "\n", encoding="utf-8")

print(f"OK: wrapper=files updated={updated} dropped_missing={dropped_missing} total_entries={total}")
PY

code=$?
echo
echo "[refresh-manifest-full] Script terminé avec exit code: $code"

# Pause only if interactive terminal
if [[ -t 0 ]]; then
  read -rp "[refresh-manifest-full] Appuie sur Entrée pour quitter…"
fi

exit "$code"

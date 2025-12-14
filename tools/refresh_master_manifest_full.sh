#!/usr/bin/env bash
set -Eeuo pipefail

# -----------------------------------------------------------------------------
# Refresh zz-manifests/manifest_master.json (FULL)
# - Update per-file: sha256, size_bytes, mtime_iso (UTC), git_hash
# - IMPORTANT: git_hash is the Git *blob* hash of the file content (git hash-object)
# - Save a timestamped backup of the manifest before writing
#
# Env:
#   MANIFEST     : path to manifest (default: zz-manifests/manifest_master.json)
#   DROP_MISSING : 0 keep missing entries, 1 drop missing entries (default: 0)
#   KEEP_OPEN    : 1 pause at end if interactive, 0 no pause (default: 1)
# -----------------------------------------------------------------------------

die() { echo "[refresh-manifest-full][ERROR] $*" >&2; exit 1; }

repo_root="$(git rev-parse --show-toplevel 2>/dev/null)" || die "Not inside a Git repository."
cd "$repo_root"

manifest="${MANIFEST:-zz-manifests/manifest_master.json}"
drop_missing="${DROP_MISSING:-0}"
keep_open="${KEEP_OPEN:-1}"

[[ -f "$manifest" ]] || die "Missing manifest: $manifest"
[[ "$drop_missing" == "0" || "$drop_missing" == "1" ]] || die "DROP_MISSING must be 0 or 1 (got: $drop_missing)"
[[ "$keep_open" == "0" || "$keep_open" == "1" ]] || die "KEEP_OPEN must be 0 or 1 (got: $keep_open)"

echo "==> (1) Sauvegarde du manifest (timestampée)"
backup_dir="zz-manifests/_backups"
mkdir -p "$backup_dir"
ts="$(date -u +%Y%m%dT%H%M%SZ)"
cp -a "$manifest" "$backup_dir/$(basename "$manifest").before_refresh.${ts}"

echo "==> (2) Rafraîchit git_hash(blob) + size_bytes + sha256 + mtime_iso (UTC) depuis le repo"
python - "$manifest" "$drop_missing" <<'PY'
import json, hashlib, subprocess, sys
from pathlib import Path
from datetime import datetime, timezone

manifest_path = Path(sys.argv[1])
drop_missing = (sys.argv[2] == "1")

repo_root = Path(subprocess.check_output(["git","rev-parse","--show-toplevel"], text=True).strip())

obj = json.loads(manifest_path.read_text(encoding="utf-8"))
if "files" not in obj or not isinstance(obj["files"], list):
    raise SystemExit("[refresh-manifest-full] JSON invalid: expected top-level key 'files' as a list")

now_iso = datetime.now(timezone.utc).replace(microsecond=0).isoformat().replace("+00:00", "Z")

files = obj["files"]
new_files = []
updated = 0
dropped = 0
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
        new_files.append(entry)
        continue

    rel = str(entry["path"]).lstrip("./")
    p = repo_root / rel

    if (not p.exists()) or (not p.is_file()):
        if drop_missing:
            dropped += 1
            continue
        # keep as-is if we are not dropping missing paths
        new_files.append(entry)
        continue

    st = p.stat()
    entry["sha256"] = file_sha256(p)
    entry["size_bytes"] = st.st_size
    entry["mtime_iso"] = datetime.fromtimestamp(st.st_mtime, timezone.utc).replace(microsecond=0).isoformat().replace("+00:00", "Z")
    entry["git_hash"] = git_blob_hash(p)

    new_files.append(entry)
    updated += 1

obj["files"] = new_files
obj["generatedAt"] = now_iso
obj["files_updated"] = updated

manifest_path.write_text(json.dumps(obj, indent=2, ensure_ascii=False) + "\n", encoding="utf-8")
print(f"OK: wrapper=files updated={updated} dropped_missing={dropped} total_entries={len(new_files)} (was {total})")
PY

code=$?
echo
echo "[refresh-manifest-full] Script terminé avec exit code: $code"

if [[ "$keep_open" == "1" ]] && [[ -t 0 ]]; then
  read -rp "[refresh-manifest-full] Appuie sur Entrée pour quitter…" _
fi

exit "$code"

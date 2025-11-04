#!/usr/bin/env python3
import argparse
import json
import os
import re
import hashlib
import time
from datetime import datetime, timezone


def sha256sum(path, bs=1024 * 1024):
    h = hashlib.sha256()
    with open(path, "rb") as f:
        for chunk in iter(lambda: f.read(bs), b""):
            h.update(chunk)
    return h.hexdigest()


def iso_utc(ts):
    return datetime.fromtimestamp(ts, tz=timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ")


def load_json(p):
    with open(p, "r", encoding="utf-8") as f:
        return json.load(f)


def dump_json(p, obj):
    tmp = p + ".tmp"
    with open(tmp, "w", encoding="utf-8") as f:
        json.dump(obj, f, ensure_ascii=False, indent=2)
    os.replace(tmp, p)


ap = argparse.ArgumentParser()
ap.add_argument("--master", default="zz-manifests/manifest_master.json")
ap.add_argument("--publication", default="zz-manifests/manifest_publication.json")
ap.add_argument(
    "--subset",
    default=r"^(README\.md|LICENSE|CITATION\.cff|\.zenodo\.json|Makefile|tools/.*|zz-manifests/diag_consistency\.py|zz-scripts/(chapter09|chapter10)/.*|zz-data/(chapter09|chapter10)/.*|zz-figures/(chapter09|chapter10)/.*|pyproject\.toml|setup\.cfg|setup\.py)$",
)
ap.add_argument(
    "--prune-master", action="store_true", help="Retire du master les entrées absentes"
)
ap.add_argument(
    "--refresh", action="store_true", help="Recalcule size_bytes/sha256/mtime_iso"
)
args = ap.parse_args()

master = load_json(args.master)
entries = master.get("entries", [])
exists = []
missing = []
for e in entries:
    p = e.get("path")
    if not p:
        continue
    if os.path.exists(p):
        exists.append(e)
    else:
        missing.append(e)

# Prune master si demandé
if args.prune_master:
    master["entries"] = exists

# Refresh (size/SHA/mtime) pour toutes les entrées présentes
if args.refresh:
    for e in master["entries"]:
        p = e["path"]
        st = os.stat(p)
        e["size_bytes"] = st.st_size
        e["sha256"] = sha256sum(p)
        e["mtime_iso"] = iso_utc(st.st_mtime)
        # évite des WARN inutiles si présent
        e.pop("git_hash", None)

# Écrit le master mis à jour
backup = args.master + f".bak.{int(time.time())}"
try:
    os.link(args.master, backup)
except Exception:
    pass
dump_json(args.master, master)

# Construit le manifest_publication filtré par subset et "fichiers existants"
rx = re.compile(args.subset)
pub_entries = []
for e in master["entries"]:
    p = e["path"]
    if rx.match(p) and os.path.exists(p):
        pub_entries.append(e)
publication = {k: v for k, v in master.items()}
publication["entries"] = pub_entries
dump_json(args.publication, publication)

# Récapitule
print(
    f"[master] total={len(entries)}  exist={len(exists)}  missing={len(missing)}  written={args.master}"
)
print(f"[publication] kept={len(pub_entries)}  written={args.publication}")
if missing:
    print("[missing examples]")
    for e in missing[:15]:
        print(" -", e.get("path"))

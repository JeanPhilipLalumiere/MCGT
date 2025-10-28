#!/usr/bin/env python3
import json, sys, hashlib, os
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
EXCLUDE_PREFIXES = [
    "zz-figures/_legacy_conflicts/",
]
def excluded(rel: str) -> bool:
    rp = rel.replace("\\", "/")
    return any(rp.startswith(pref) for pref in EXCLUDE_PREFIXES)

mf = ROOT / "zz-manifests" / "integrity.json"
if not mf.exists():
    print("❌ Manifeste introuvable: zz-manifests/integrity.json", file=sys.stderr)
    sys.exit(2)

want = json.loads(mf.read_text(encoding="utf-8"))
want_entries = {e["path"]: e for e in want.get("entries", [])}
bad = 0

for rel, e in sorted(want_entries.items()):
    if excluded(rel):
        continue
    p = ROOT / rel
    if not p.exists():
        print(f"❌ Manquant: {rel}")
        bad = 1
        continue
    if not (os.access(p.parent, os.X_OK) and os.access(p, os.R_OK)):
        print(f"❌ Non lisible: {rel}")
        bad = 1
        continue
    h = hashlib.sha256()
    with open(p, "rb") as f:
        for chunk in iter(lambda: f.read(1<<20), b""):
            h.update(chunk)
    have_sha = h.hexdigest()
    have_bytes = p.stat().st_size
    if have_sha != e["sha256"] or have_bytes != e["bytes"]:
        print(f"❌ Divergence: {rel}\n   attendu: {e['sha256']} ({e['bytes']}o)\n   obtenu : {have_sha} ({have_bytes}o)")
        bad = 1

def collect_targets():
    paths = []
    for base in ("zz-figures", "zz-data"):
        bp = ROOT / base
        if not bp.exists(): continue
        for p in bp.rglob("*"):
            if p.is_file():
                rel = p.relative_to(ROOT).as_posix()
                if not excluded(rel):
                    paths.append(rel)
    return paths

have = set(collect_targets())
extra = sorted(have - set(want_entries.keys()))
for rel in extra:
    print(f"❌ Nouveau non listé: {rel}")
    bad = 1

if bad:
    print("\nConseil: mettez à jour le manifeste → make integrity-update", file=sys.stderr)
    sys.exit(1)
else:
    print("✅ Intégrité OK")

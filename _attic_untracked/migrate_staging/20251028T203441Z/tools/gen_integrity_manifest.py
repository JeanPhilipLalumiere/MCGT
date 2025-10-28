#!/usr/bin/env python3
import hashlib, json, os
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
EXCLUDE_PREFIXES = [
    "zz-figures/_legacy_conflicts/",
]
TARGETS = [
    ("zz-figures", {".png", ".jpg", ".jpeg", ".gif", ".svg"}),
    ("zz-data", {".csv.gz", ".npz", ".dat", ".json.gz", ".tsv.gz", ".csv"}),
]

def excluded(rel: str) -> bool:
    rp = rel.replace("\\", "/")
    return any(rp.startswith(pref) for pref in EXCLUDE_PREFIXES)

def is_accessible(p: Path) -> bool:
    # dossier "exécutable" + fichier lisible
    try:
        return os.access(p.parent, os.X_OK) and os.access(p, os.R_OK)
    except Exception:
        return False

entries = []
for base, exts in TARGETS:
    basep = ROOT / base
    if not basep.exists():
        continue
    for p in sorted(basep.rglob("*")):
        try:
            if not p.is_file():
                continue
        except PermissionError:
            # Impossible de stat() → ignorer
            continue
        rel = p.relative_to(ROOT).as_posix()
        if excluded(rel):
            continue
        if not any(rel.lower().endswith(e) for e in exts):
            continue
        if not is_accessible(p):
            # Non lisible → ignorer silencieusement
            continue
        # Hash robuste
        h = hashlib.sha256()
        try:
            with open(p, "rb") as f:
                for chunk in iter(lambda: f.read(1 << 20), b""):
                    h.update(chunk)
            entries.append({
                "path": rel,
                "sha256": h.hexdigest(),
                "bytes": p.stat().st_size,
            })
        except Exception:
            # Si lecture impossible, ignorer (ne bloque pas la CI locale)
            continue

manifest = {"version": 1, "entries": entries}
out = ROOT / "zz-manifests" / "integrity.json"
out.write_text(json.dumps(manifest, indent=2, sort_keys=True) + "\n", encoding="utf-8")
print(f"Wrote {out} with {len(entries)} entries")
